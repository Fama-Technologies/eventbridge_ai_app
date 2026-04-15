# Final Production Database ERD (Enriched Lean Version)

This Entity-Relationship Diagram represents the complete, verified production schema. We have specifically ensured that **Vendor Profile Views** are integrated into the core tracking system.

```mermaid
erDiagram
    %% Identity & Auth
    users {
        int id PK
        text email UK 
        text account_type 
        boolean is_active
        timestamp created_at
    }

    %% Core Profiles & Tracking
    vendor_profiles {
        int id PK
        int user_id FK
        text business_name
        text location
        numeric average_rating
        int review_count
        boolean is_verified
        timestamp created_at
    }

    vendor_profile_views {
        int id PK
        int vendor_profile_id FK
        int viewer_user_id FK "Optional"
        timestamp viewed_at
    }

    %% Service Offerings
    vendor_packages {
        int id PK
        int vendor_profile_id FK
        text title
        numeric price
        varchar highlight_badge
        boolean is_active
    }

    %% Transactional Flow
    leads {
        int id PK
        int client_id FK
        int vendor_profile_id FK
        int package_id FK "Optional"
        date event_date
        int budget_amount
        varchar(30) status
        timestamp created_at
    }

    bookings {
        int id PK
        int lead_id FK
        int client_id FK
        int vendor_profile_id FK
        date booking_date
        int total_amount
        text status
    }

    %% Portfolio & Messaging
    vendor_portfolio {
        int id PK
        int vendor_profile_id FK
        text image_url
        timestamp created_at
    }

    message_threads {
        int id PK
        int client_id FK
        int vendor_profile_id FK
        text last_message
        timestamp updated_at
    }

    messages {
        int id PK
        int thread_id FK
        int sender_user_id FK
        text content
        timestamp created_at
    }

    %% Relationships
    users ||--o| vendor_profiles : "manages"
    vendor_profiles ||--o{ vendor_profile_views : "tracked by"
    users ||--o{ vendor_profile_views : "performs view"
    
    users ||--o{ leads : "requests"
    vendor_profiles ||--o{ leads : "receives"
    leads ||--o| bookings : "converts to"
    
    vendor_profiles ||--o{ vendor_packages : "offers"
    vendor_profiles ||--o{ vendor_portfolio : "displays"
    users ||--o{ message_threads : "chats (customer)"
    vendor_profiles ||--o{ message_threads : "chats (vendor)"
    message_threads ||--o{ messages : "contains"
```
