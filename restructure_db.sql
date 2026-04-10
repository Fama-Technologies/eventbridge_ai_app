-- Restructure leads table
DO $$
BEGIN
  -- Rename customer_id to client_id if it exists
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'leads' AND column_name = 'customer_id') THEN
    ALTER TABLE leads RENAME COLUMN customer_id TO client_id;
  END IF;

  -- Ensure client_id column exists
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'leads' AND column_name = 'client_id') THEN
    ALTER TABLE leads ADD COLUMN client_id INTEGER REFERENCES users(id) ON DELETE CASCADE;
  END IF;

  -- Handle vendor_profile_id / vendor_id
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'leads' AND column_name = 'vendor_profile_id') THEN
     IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'leads' AND column_name = 'vendor_id') THEN
       ALTER TABLE leads RENAME COLUMN vendor_profile_id TO vendor_id;
     END IF;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'leads' AND column_name = 'vendor_id') THEN
    ALTER TABLE leads ADD COLUMN vendor_id INTEGER REFERENCES users(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Restructure bookings table
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'client_phone') THEN
    ALTER TABLE bookings ADD COLUMN client_phone VARCHAR(20);
  END IF;
END $$;

-- Restructure chats table
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chats' AND column_name = 'vendor_is_typing') THEN
    ALTER TABLE chats ADD COLUMN vendor_is_typing BOOLEAN DEFAULT FALSE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chats' AND column_name = 'client_is_typing') THEN
    ALTER TABLE chats ADD COLUMN client_is_typing BOOLEAN DEFAULT FALSE;
  END IF;
END $$;
