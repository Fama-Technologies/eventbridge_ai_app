const { Pool } = require('pg');
require('dotenv').config({ path: '../eventbridge/.env' });

const pool = new Pool();

async function checkLeads() {
  try {
    const tables = await pool.query("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'");
    console.log('Tables:', tables.rows.map(r => r.table_name));

    for (const table of tables.rows) {
      if (table.table_name.includes('lead') || table.table_name.includes('request') || table.table_name.includes('inquiry')) {
        console.log(`\n--- Structure of ${table.table_name} ---`);
        const columns = await pool.query(`SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '${table.table_name}'`);
        console.log(columns.rows);
      }
    }
  } catch (err) {
    console.error(err);
  } finally {
    pool.end();
  }
}

checkLeads();
