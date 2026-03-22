const { Pool } = require('pg');
require('dotenv').config({ path: '../eventbridge/.env' });
const pool = new Pool();
pool.query('SELECT * FROM vendor_packages WHERE name = $1;', ['good'], (err, res) => {
  if (err) console.error(err);
  else console.log(res.rows);
  pool.end();
});
