require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const fs   = require('fs');
const path = require('path');

async function migrate() {
  const mysql = require('mysql2/promise');

  // Connect without database first to CREATE it
  const conn = await mysql.createConnection({
    host:     process.env.DB_HOST     || 'localhost',
    port:     parseInt(process.env.DB_PORT || '3306'),
    user:     process.env.DB_USER     || 'root',
    password: process.env.DB_PASSWORD || '',
    multipleStatements: true,
  });

  console.log('✅ Connected to MySQL');

  const sql = fs.readFileSync(
    path.join(__dirname, 'schema.sql'),
    'utf8'
  );

  console.log('⏳ Running migrations...');
  await conn.query(sql);
  console.log('✅ Schema applied successfully');

  await conn.end();
  console.log('🚀 Database ready! Run: npm run dev');
}

migrate().catch(err => {
  console.error('❌ Migration failed:', err.message);
  process.exit(1);
});
