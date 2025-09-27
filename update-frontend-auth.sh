#!/bin/bash

echo "🔧 Updating Frontend Auth Routes"

cd /home/unitrans

# Pull latest changes
echo "📥 Pulling latest changes..."
git pull origin main

# Stop frontend
echo "⏹️ Stopping frontend..."
pm2 stop unitrans-frontend

# Navigate to frontend directory
cd frontend-new

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

# Test auth endpoint
echo "🔍 Testing auth endpoint..."
curl -X POST https://unibus.online/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}' \
  && echo "✅ Auth API works" || echo "❌ Auth API failed"

echo "✅ Frontend auth update complete!"
echo "🌍 Test your login at: https://unibus.online/auth"
