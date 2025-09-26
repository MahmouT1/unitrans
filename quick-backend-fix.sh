#!/bin/bash

# Quick Backend Fix for Production
# This script quickly fixes backend connection issues

set -e

echo "🔧 Quick Backend Fix for Production"

# Navigate to project directory
cd /home/unitrans

# Stop PM2 processes
echo "⏹️ Stopping PM2 processes..."
pm2 stop all

# Start MongoDB
echo "📊 Starting MongoDB..."
systemctl start mongod
systemctl enable mongod

# Check MongoDB
echo "🔍 Checking MongoDB..."
mongosh --eval "db.runCommand('ping')" || echo "MongoDB not responding"

# Check users collection
echo "👥 Checking users collection..."
mongosh --eval "
use unitrans;
print('Users count:', db.users.countDocuments());
db.users.find().limit(3).forEach(printjson);
"

# Update backend environment
echo "⚙️ Updating backend environment..."
cd backend-new
cat > .env << EOF
NODE_ENV=production
PORT=3001
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans
FRONTEND_URL=https://unibus.online
JWT_SECRET=production-jwt-secret-key-2024
API_VERSION=v1
API_PREFIX=/api
LOG_LEVEL=info
EOF

# Start backend
echo "🚀 Starting backend..."
pm2 start server.js --name "unitrans-backend"

# Wait for backend
echo "⏳ Waiting for backend to start..."
sleep 10

# Test backend
echo "🏥 Testing backend..."
curl -f http://localhost:3001/health && echo "✅ Backend is healthy" || echo "❌ Backend health check failed"

# Test auth endpoint
echo "🔐 Testing auth endpoint..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test","role":"student"}' \
  && echo "✅ Auth endpoint working" || echo "❌ Auth endpoint failed"

# Start frontend
echo "🚀 Starting frontend..."
cd ../frontend-new
pm2 start "npm run start" --name "unitrans-frontend"

# Wait for frontend
echo "⏳ Waiting for frontend to start..."
sleep 10

# Test frontend
echo "🌐 Testing frontend..."
curl -f http://localhost:3000 && echo "✅ Frontend is accessible" || echo "❌ Frontend test failed"

echo "✅ Quick backend fix complete!"
echo "🌍 Test your login at: https://unibus.online/auth"
echo "🔐 Backend API: https://unibus.online/api/"
echo "🏥 Health check: https://unibus.online/health"

# Show PM2 status
pm2 status
