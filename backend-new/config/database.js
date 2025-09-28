const { MongoClient } = require('mongodb');
require('dotenv').config();

let db;
let client;

async function connectDB() {
  if (db) {
    return db;
  }

  try {
    client = new MongoClient(process.env.MONGODB_URI || 'mongodb://localhost:27017');
    await client.connect();
    db = client.db(process.env.MONGODB_DB_NAME || 'student_portal');
    console.log('✅ Connected to MongoDB:', process.env.MONGODB_DB_NAME || 'student_portal');
    return db;
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    throw error;
  }
}

module.exports = connectDB;