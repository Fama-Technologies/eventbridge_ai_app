// migrate_working_hours.js
const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../eventbridge/.env') });

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function runMigration() {
  const client = await pool.connect();
  try {
    console.log('🚀 Starting migration: Adding working_hours to vendor_profiles...');
    
    await client.query(`
      ALTER TABLE vendor_profiles 
      ADD COLUMN IF NOT EXISTS working_hours JSONB DEFAULT '{}'::jsonb;
    `);

    console.log('✅ Migration successful! The column working_hours has been added.');
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();
