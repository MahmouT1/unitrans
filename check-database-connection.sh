#!/bin/bash

echo "🔍 Checking Database Connection for Production Domain"
echo "=================================================="

cd /home/unitrans

# Check if MongoDB is running
echo "📊 Checking MongoDB status..."
systemctl status mongod --no-pager

# Check MongoDB connection
echo "🔗 Testing MongoDB connection..."
mongosh --eval "db.runCommand('ping')" unitrans

# Check if MongoDB is accessible on localhost:27017
echo "🌐 Testing localhost:27017 connection..."
netstat -tlnp | grep :27017 || echo "❌ Port 27017 not listening"

# Check backend environment variables
echo "⚙️ Checking backend environment variables..."
if [ -f "backend-new/.env" ]; then
    echo "📄 Backend .env file exists:"
    cat backend-new/.env | grep -E "(MONGODB|DB_|MONGO)"
else
    echo "❌ Backend .env file not found"
fi

# Check if backend is running
echo "🚀 Checking backend status..."
pm2 status | grep unitrans-backend

# Test backend database connection
echo "🧪 Testing backend database connection..."
curl -s http://localhost:3001/api/health | jq . || echo "❌ Backend health check failed"

# Check backend logs for database connection
echo "📋 Checking backend logs for database connection..."
pm2 logs unitrans-backend --lines 20 | grep -i -E "(mongo|database|connection|error)" || echo "No database-related logs found"

# Test database operations
echo "💾 Testing database operations..."
echo "Creating test collection..."
mongosh unitrans --eval "
try {
    db.testConnection.insertOne({test: 'connection', timestamp: new Date()});
    print('✅ Database write successful');
    db.testConnection.deleteOne({test: 'connection'});
    print('✅ Database delete successful');
} catch (error) {
    print('❌ Database operation failed: ' + error.message);
}
"

# Check if the project is using the correct database
echo "🎯 Checking if project uses localhost:27017..."
if grep -r "localhost:27017" backend-new/ 2>/dev/null; then
    echo "✅ Found localhost:27017 references in backend"
else
    echo "❌ No localhost:27017 references found in backend"
fi

# Check MongoDB connection string in backend
echo "🔍 Checking MongoDB connection string..."
if [ -f "backend-new/server.js" ]; then
    echo "📄 Backend server.js MongoDB connection:"
    grep -A 5 -B 5 "mongodb://" backend-new/server.js || echo "No MongoDB connection string found"
fi

# Test actual database connectivity from backend
echo "🔧 Testing backend database connectivity..."
cd backend-new
node -e "
const { MongoClient } = require('mongodb');
const client = new MongoClient('mongodb://localhost:27017/unitrans');

async function testConnection() {
    try {
        await client.connect();
        console.log('✅ Backend can connect to MongoDB');
        const db = client.db('unitrans');
        const collections = await db.listCollections().toArray();
        console.log('📊 Available collections:', collections.map(c => c.name));
        await client.close();
    } catch (error) {
        console.log('❌ Backend database connection failed:', error.message);
    }
}
testConnection();
" 2>/dev/null || echo "❌ Backend database test failed"

cd ..

# Check if frontend can reach backend
echo "🌐 Testing frontend to backend connection..."
curl -s http://localhost:3000 | head -5 || echo "❌ Frontend not accessible"

# Check production domain database connection
echo "🌍 Testing production domain database connection..."
curl -s https://unibus.online/api/health | jq . || echo "❌ Production domain health check failed"

# Summary
echo ""
echo "📋 SUMMARY:"
echo "==========="
echo "MongoDB Status: $(systemctl is-active mongod)"
echo "MongoDB Port: $(netstat -tlnp | grep :27017 | wc -l) listening"
echo "Backend Status: $(pm2 status | grep unitrans-backend | awk '{print $4}')"
echo "Frontend Status: $(pm2 status | grep unitrans-frontend | awk '{print $4}')"
echo "Production Domain: $(curl -s -o /dev/null -w "%{http_code}" https://unibus.online)"

echo ""
echo "✅ Database connection check completed!"
echo "🌍 Test your project at: https://unibus.online"
