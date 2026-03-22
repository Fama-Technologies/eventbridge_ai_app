CREATE TABLE IF NOT EXISTS leads (
  id SERIAL PRIMARY KEY,
  vendor_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  client_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  event_date DATE,
  event_time TIME,
  location VARCHAR(255),
  match_score INTEGER DEFAULT 0,
  budget DECIMAL(12, 2) DEFAULT 0,
  guests INTEGER DEFAULT 0,
  client_message TEXT,
  venue_name VARCHAR(255),
  venue_address TEXT,
  status VARCHAR(50) DEFAULT 'pending', -- pending, accepted, rejected
  is_high_value BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vendor_profiles' AND column_name = 'profile_views') THEN
    ALTER TABLE vendor_profiles ADD COLUMN profile_views INTEGER DEFAULT 0;
  END IF;
END $$;
