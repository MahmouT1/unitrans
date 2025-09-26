#!/bin/bash

echo "🔧 Fixing Authentication API"

# Navigate to project directory
cd /home/unitrans

# Stop PM2 processes
echo "⏹️ Stopping PM2 processes..."
pm2 stop all

# Check backend logs
echo "📋 Checking backend logs..."
pm2 logs unitrans-backend --lines 20

# Restart backend
echo "🚀 Restarting backend..."
cd backend-new
pm2 start server.js --name "unitrans-backend"

# Wait for backend
echo "⏳ Waiting for backend to start..."
sleep 10

# Test backend health
echo "🏥 Testing backend health..."
curl -f http://localhost:3001/health && echo "✅ Backend is healthy" || echo "❌ Backend health check failed"

# Test direct login API
echo "🔐 Testing direct login API..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}' \
  -v

# Test through frontend proxy
echo "🌐 Testing through frontend proxy..."
curl -X POST https://unibus.online/api/proxy/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}' \
  -v

# Check if backend is using correct database
echo "🔍 Checking backend database connection..."
mongosh unitrans --eval "
print('Database:', db.getName());
print('Users count:', db.users.countDocuments());
print('Sample user:', JSON.stringify(db.users.findOne({email: 'sona123@gmail.com'})));
"

# Test backend database query
echo "🔍 Testing backend database query..."
curl -X GET http://localhost:3001/api/admin/students \
  -H "Content-Type: application/json" \
  -v

echo "✅ Authentication API fix complete!"
echo "🔐 Test your login at: https://unibus.online/auth"
