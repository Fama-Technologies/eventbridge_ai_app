-- Create chats table
CREATE TABLE IF NOT EXISTS chats (
  id SERIAL PRIMARY KEY,
  vendor_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  client_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  last_message TEXT,
  last_message_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  unread_count_vendor INTEGER DEFAULT 0,
  unread_count_client INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(vendor_id, client_id)
);

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  chat_id INTEGER REFERENCES chats(id) ON DELETE CASCADE,
  sender_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster message fetching
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_chats_vendor_id ON chats(vendor_id);
CREATE INDEX IF NOT EXISTS idx_chats_client_id ON chats(client_id);
