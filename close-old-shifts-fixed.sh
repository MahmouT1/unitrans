#!/bin/bash

echo "🔧 إغلاق الـ Shifts القديمة"
echo "==========================="

cd /var/www/unitrans/backend-new

# Create temporary Node.js script
cat > /tmp/close_shifts.js << 'EOF'
const { MongoClient } = require('mongodb');
require('dotenv').config();

const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const dbName = process.env.MONGODB_DB_NAME || 'student_portal';

async function closeOldShifts() {
  const client = new MongoClient(mongoUri);
  
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB');
    
    const db = client.db(dbName);
    
    // Find old open shifts
    const oldShifts = await db.collection('shifts').find({
      status: 'open',
      shiftEnd: null
    }).toArray();
    
    console.log('🔍 Found', oldShifts.length, 'old open shifts');
    
    // Close them
    const result = await db.collection('shifts').updateMany(
      { 
        status: 'open',
        shiftEnd: null
      },
      { 
        $set: { 
          status: 'closed',
          shiftEnd: new Date(),
          isActive: false
        } 
      }
    );
    
    console.log('✅ Closed', result.modifiedCount, 'old shifts');
    
    // Check remaining open shifts
    const remaining = await db.collection('shifts').countDocuments({
      status: 'open',
      shiftEnd: null
    });
    
    console.log('🔍 Remaining open shifts:', remaining);
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
  }
}

closeOldShifts();
EOF

# Run the script
node /tmp/close_shifts.js

echo ""
echo "🧪 اختبار API:"
curl http://localhost:3001/api/shifts?status=open -s | jq '.shifts | length'

echo ""
echo "✅ تم!"
