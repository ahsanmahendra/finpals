require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mysql = require('mysql2/promise');

async function run() {
  const conn = await mysql.createConnection({
    host:     process.env.DB_HOST     || 'localhost',
    port:     parseInt(process.env.DB_PORT || '3306'),
    user:     process.env.DB_USER     || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME     || 'finpals',
  });
  console.log('✅ Connected to database:', process.env.DB_NAME || 'finpals');

  try {
    // Check if user_id column already exists
    const [columns] = await conn.query('SHOW COLUMNS FROM categories LIKE "user_id"');
    if (columns.length === 0) {
      console.log('⏳ Adding user_id column to categories table...');
      await conn.query('ALTER TABLE categories ADD COLUMN user_id INT DEFAULT NULL');
      console.log('✅ Added user_id column');
    } else {
      console.log('ℹ️ user_id column already exists in categories table');
    }
  } catch (e) {
    console.error('❌ Failed to add user_id column:', e.message);
  }

  try {
    // Try to add the foreign key constraint
    console.log('⏳ Adding foreign key constraint to categories table...');
    await conn.query(`
      ALTER TABLE categories 
      ADD CONSTRAINT fk_categories_user_id 
      FOREIGN KEY (user_id) REFERENCES users(user_id) 
      ON DELETE CASCADE
    `);
    console.log('✅ Foreign key constraint added successfully');
  } catch (e) {
    if (e.code === 'ER_DUP_KEYNAME' || e.message.includes('already exists') || e.message.includes('Duplicate foreign key')) {
      console.log('ℹ️ Foreign key constraint already exists');
    } else {
      console.error('❌ Failed to add foreign key constraint:', e.message);
    }
  }

  await conn.end();
  console.log('✅ Migration complete');
}

run().catch(err => {
  console.error('❌ Migration script failed:', err);
  process.exit(1);
});
