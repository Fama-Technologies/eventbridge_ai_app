-- =============================================================================
-- Eventbridge Core PostgreSQL Production Schema
-- Cloud SQL Optimized | PostGIS Enabled | Audit Trail Included
-- =============================================================================

-- 0. Extensions
CREATE EXTENSION IF NOT EXISTS postgis;

-- =============================================================================
-- 1. Identity & Auth
-- =============================================================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    first_name TEXT,
    last_name TEXT,
    phone TEXT,
    country VARCHAR(100),
    account_type TEXT CHECK (account_type IN ('CUSTOMER', 'VENDOR', 'ADMIN')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. Categories Taxonomy
-- =============================================================================
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    icon_name VARCHAR(50),
    category_type TEXT DEFAULT 'INDUSTRY' CHECK (category_type IN ('INDUSTRY', 'EVENT')),
    is_active BOOLEAN DEFAULT TRUE
);

-- Services Taxonomy (Individual Capabilities: what a vendor CAN DO)
CREATE TABLE services (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed Initial Services
-- Note: category_id values correspond to seeded categories (Photography=1, Catering=2, Entertainment=3)
INSERT INTO services (category_id, name, description) VALUES
(1, 'Drone Photography',   'Professional aerial event coverage'),
(1, 'Wedding Photography', 'Full day wedding photo service'),
(1, 'Portrait Photography','Studio or on-location portraits'),
(2, 'Corporate Catering',  'Buffet and platter services for business events'),
(2, 'Wedding Catering',    'Sit-down dinner and cocktail service'),
(3, 'MC Services',         'Professional event host and moderation'),
(3, 'DJ Services',         'Sound and music management');

-- =============================================================================
-- 3. Subscription Plans
-- =============================================================================
CREATE TABLE subscription_plans (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100),
    price_monthly INTEGER NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    max_new_projects_monthly INTEGER DEFAULT 0,
    max_new_packages_monthly INTEGER DEFAULT 0,
    max_new_ads_monthly INTEGER DEFAULT 0,
    has_priority_search BOOLEAN DEFAULT FALSE,
    has_recommended_badge BOOLEAN DEFAULT FALSE,
    features JSONB,
    is_active BOOLEAN DEFAULT TRUE
);

INSERT INTO subscription_plans
    (name, display_name, price_monthly, max_new_projects_monthly, max_new_packages_monthly,
     max_new_ads_monthly, has_priority_search, has_recommended_badge, features)
VALUES
('free',         'Free Starter',   0,  1, 1, 0, false, false,
 '["1 Package Listing", "1 Portfolio Project", "Basic Profile Listing"]'),
('pro',          'Basic Vendor',   15, 3, 3, 2, false, false,
 '["3 Package Listings", "3 Portfolio Projects", "Bookings Calendar", "Messaging", "2 Promotional Ads"]'),
('business_pro', 'Premium Vendor', 30, 6, 6, 4, true,  true,
 '["6 Package Listings", "6 Portfolio Projects", "Bookings Calendar", "Messaging", "Priority Search Placement", "Top Recommended Badge", "4 Promotional Ads"]');

-- =============================================================================
-- 4. System Settings
-- =============================================================================
CREATE TABLE system_settings (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO system_settings (key, value) VALUES
('ugx_to_usd_rate',                '3650'),
('subscription_grace_period_days', '3');

-- =============================================================================
-- 5. Core Profiles
-- =============================================================================
CREATE TABLE vendor_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    business_name TEXT NOT NULL,
    description TEXT,
    experience TEXT,
    country VARCHAR(100),
    location TEXT,
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    -- PostGIS spatial point (auto-populated by trigger below)
    geom GEOGRAPHY(Point, 4326),
    travel_radius INTEGER DEFAULT 20,
    avatar_url TEXT,
    base_price_amount INTEGER NOT NULL DEFAULT 0,
    base_currency VARCHAR(10) DEFAULT 'UGX',
    base_price_unit VARCHAR(50) DEFAULT 'Per Event',
    plan_id INTEGER REFERENCES subscription_plans(id) ON DELETE SET NULL,
    average_rating NUMERIC(3, 2) DEFAULT 0.00,
    review_count INTEGER DEFAULT 0,
    verification_status TEXT DEFAULT 'PENDING',
    is_verified BOOLEAN DEFAULT FALSE,
    instagram_handle TEXT,
    tiktok_handle TEXT,
    facebook_handle TEXT,
    website_url TEXT,
    last_subscription_cycle_reset TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- GIST spatial index for high-speed "nearby vendor" queries
CREATE INDEX idx_vendor_spatial ON vendor_profiles USING GIST (geom);

-- Trigger: keeps geom in sync whenever lat/long are set or updated
CREATE OR REPLACE FUNCTION update_vendor_geom()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.geom = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_vendor_geom
BEFORE INSERT OR UPDATE ON vendor_profiles
FOR EACH ROW EXECUTE FUNCTION update_vendor_geom();

CREATE TABLE vendor_profile_categories (
    id SERIAL PRIMARY KEY,
    vendor_profile_id INTEGER REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    UNIQUE(vendor_profile_id, category_id)
);

CREATE TABLE vendor_profile_views (
    id SERIAL PRIMARY KEY,
    vendor_profile_id INTEGER REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    viewer_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 6. Packages & Portfolio
-- NOTE: Defined BEFORE leads to satisfy the FK dependency (leads.package_id).
-- =============================================================================
CREATE TABLE vendor_packages (
    id SERIAL PRIMARY KEY,
    vendor_profile_id INTEGER REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    price NUMERIC(15, 2) DEFAULT 0.00,
    price_unit VARCHAR(50) DEFAULT 'event',
    features JSONB DEFAULT '[]'::jsonb,
    highlight_badge VARCHAR(20) DEFAULT 'none',
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Vendor Capabilities (which vendor offers which master service)
CREATE TABLE vendor_services (
    id SERIAL PRIMARY KEY,
    vendor_profile_id INTEGER REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    service_id INTEGER REFERENCES services(id) ON DELETE CASCADE,
    custom_description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(vendor_profile_id, service_id)
);

-- Bundling: which services are included in a package
CREATE TABLE vendor_package_services (
    package_id INTEGER REFERENCES vendor_packages(id) ON DELETE CASCADE,
    vendor_service_id INTEGER REFERENCES vendor_services(id) ON DELETE CASCADE,
    PRIMARY KEY (package_id, vendor_service_id)
);

CREATE TABLE vendor_portfolio (
    id SERIAL PRIMARY KEY,
    vendor_profile_id INTEGER REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    title TEXT,
    category TEXT,
    tags JSONB DEFAULT '[]'::jsonb,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE vendor_availability (
    id SERIAL PRIMARY KEY,
    vendor_profile_id INTEGER REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'AVAILABLE',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(vendor_profile_id, date)
);

-- =============================================================================
-- 7. Transactional (Leads & Bookings)
-- NOTE: vendor_packages is defined above so this FK resolves correctly.
-- =============================================================================
CREATE TABLE leads (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES users(id) ON DELETE RESTRICT,
    vendor_profile_id INTEGER REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    package_id INTEGER REFERENCES vendor_packages(id) ON DELETE SET NULL,
    country VARCHAR(100),
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    target_radius NUMERIC DEFAULT 50.0,
    event_date DATE,
    budget_amount INTEGER,
    budget_currency VARCHAR(10) DEFAULT 'USD',
    details JSONB,
    status VARCHAR(30) DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bookings (
    id SERIAL PRIMARY KEY,
    lead_id INTEGER REFERENCES leads(id) ON DELETE SET NULL,
    client_id INTEGER REFERENCES users(id) ON DELETE RESTRICT,
    vendor_profile_id INTEGER REFERENCES vendor_profiles(id) ON DELETE RESTRICT,
    booking_date DATE,
    total_amount INTEGER,
    total_currency VARCHAR(10) DEFAULT 'USD',
    status TEXT DEFAULT 'CONFIRMED',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 8. Messaging
-- =============================================================================
CREATE TABLE message_threads (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    vendor_profile_id INTEGER REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    last_message TEXT,
    client_unread_count INTEGER DEFAULT 0,
    vendor_unread_count INTEGER DEFAULT 0,
    status TEXT DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    thread_id INTEGER REFERENCES message_threads(id) ON DELETE CASCADE,
    sender_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS: prevent DB-level cross-user message leaks
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 9. Reviews
-- =============================================================================
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER REFERENCES bookings(id) ON DELETE SET NULL,
    client_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    vendor_profile_id INTEGER REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 10. Notifications
-- =============================================================================
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    message TEXT,
    related_entity_type VARCHAR(50),
    related_entity_id INTEGER,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 11. Promotions & Banners
-- =============================================================================
CREATE TABLE banners (
    id SERIAL PRIMARY KEY,
    vendor_profile_id INTEGER REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    media_type VARCHAR(20) DEFAULT 'IMAGE',
    tag_name VARCHAR(50),
    title TEXT,
    event_date DATE,
    place TEXT,
    is_promotional_ad BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Partial index: only index active banners (the 99% query case)
CREATE INDEX idx_active_banners ON banners(vendor_profile_id) WHERE is_active = TRUE;

-- =============================================================================
-- 12. Subscription History & Payment Sync (Audit Trail)
-- =============================================================================
CREATE TABLE vendor_subscriptions (
    id SERIAL PRIMARY KEY,
    vendor_profile_id INTEGER NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    plan_id INTEGER NOT NULL REFERENCES subscription_plans(id) ON DELETE RESTRICT,

    status VARCHAR(50) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'ACTIVE', 'EXPIRED', 'CANCELLED', 'FAILED', 'PAST_DUE')),

    -- Payment Reconciliation
    payment_provider VARCHAR(50),           -- PAYSTACK | STRIPE | MTN_MOMO | AIRTEL_MONEY
    external_reference TEXT UNIQUE,         -- Unique per provider; NULLs allowed for pre-payment rows

    amount_paid NUMERIC(15, 2),
    currency VARCHAR(10) DEFAULT 'USD',

    -- Lifecycle timestamps
    starts_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,

    -- Raw webhook payload from payment provider
    metadata JSONB DEFAULT '{}'::jsonb,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Standard performance indexes
CREATE INDEX idx_vendor_subs_profile ON vendor_subscriptions(vendor_profile_id);
CREATE INDEX idx_vendor_subs_status  ON vendor_subscriptions(status);
CREATE INDEX idx_vendor_subs_expires ON vendor_subscriptions(expires_at);

-- Partial UNIQUE index: enforces exactly ONE active subscription per vendor at the DB level
CREATE UNIQUE INDEX one_active_subscription_per_vendor
    ON vendor_subscriptions(vendor_profile_id)
    WHERE status = 'ACTIVE';

-- =============================================================================
-- 13. Views
-- =============================================================================

-- active_vendor_plans: always returns the correct effective plan for a vendor.
-- Defaults to plan ID 1 (Free) when no active, unexpired subscription exists.
-- Use this view in backend queries instead of joining vendor_profiles.plan_id directly.
CREATE OR REPLACE VIEW active_vendor_plans AS
SELECT
    vp.id    AS vendor_profile_id,
    vp.business_name,
    COALESCE(vs.plan_id, 1) AS effective_plan_id,
    vs.expires_at           AS subscription_expires_at
FROM vendor_profiles vp
LEFT JOIN vendor_subscriptions vs
    ON vp.id = vs.vendor_profile_id
    AND vs.status = 'ACTIVE'
    AND vs.expires_at > NOW();

-- =============================================================================
-- End of Schema
-- =============================================================================
