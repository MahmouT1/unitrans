#!/bin/bash

echo "🔧 Rebuilding Frontend with Proxy Routes"

cd /home/unitrans

# Stop frontend
echo "⏹️ Stopping frontend..."
pm2 stop unitrans-frontend

# Navigate to frontend directory
cd frontend-new

# Clear Next.js cache
echo "🧹 Clearing Next.js cache..."
rm -rf .next
rm -rf node_modules/.cache

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Build frontend
echo "🏗️ Building frontend..."
npm run build

# Start frontend
echo "🚀 Starting frontend..."
pm2 start "npm run start" --name "unitrans-frontend"

# Wait for frontend to start
echo "⏳ Waiting for frontend to start..."
sleep 15

# Test proxy endpoint
echo "🔍 Testing proxy endpoint..."
curl -X POST https://unibus.online/api/proxy/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}' \
  && echo "✅ Proxy API works" || echo "❌ Proxy API failed"

echo "✅ Frontend rebuild complete!"
echo "🌍 Test your login at: https://unibus.online/auth"
