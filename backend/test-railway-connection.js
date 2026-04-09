import mysql from 'mysql2/promise.js';
import dotenv from 'dotenv';

dotenv.config();

const testConnection = async () => {
  try {
    console.log('🔄 Testing Railway Database Connection...');
    console.log(`Database URL: ${process.env.DATABASE_URL}`);

    const connection = await mysql.createConnection(process.env.DATABASE_URL);
    
    console.log('✅ Connected to Railway Database!');
    
    const [rows] = await connection.execute('SELECT 1 as test');
    console.log('✅ Database is responding:', rows);
    
    await connection.end();
    console.log('✅ Connection closed successfully');
    
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
    process.exit(1);
  }
};

testConnection();
