#!/bin/bash

# Quick Authentication Fix for Production
# This script quickly fixes authentication issues on production

set -e

echo "🚀 Quick Authentication Fix for Production"

# Navigate to project directory
cd /home/unitrans

# Stop PM2 processes
echo "⏹️ Stopping PM2 processes..."
pm2 stop all

# Pull latest changes
echo "📥 Pulling latest changes..."
git pull origin main

# Update frontend environment for production
echo "⚙️ Updating frontend environment..."
cd frontend-new
cat > .env.local << EOF
NEXT_PUBLIC_BACKEND_URL=https://unibus.online:3001
NEXT_PUBLIC_API_URL=https://unibus.online:3001/api
NEXT_PUBLIC_FRONTEND_URL=https://unibus.online
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans
JWT_SECRET=production-jwt-secret-key-2024
EOF

# Install dependencies and build
echo "📦 Installing dependencies..."
npm install

echo "🔨 Building frontend..."
npm run build

# Update backend environment
echo "⚙️ Updating backend environment..."
cd ../backend-new
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

# Install backend dependencies
echo "📦 Installing backend dependencies..."
npm install --production

# Restart PM2 processes
echo "🔄 Restarting PM2 processes..."
cd /home/unitrans
pm2 restart all

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# Test services
echo "🏥 Testing services..."
curl -f http://localhost:3001/health && echo "✅ Backend is healthy" || echo "❌ Backend health check failed"
curl -f http://localhost:3000 && echo "✅ Frontend is accessible" || echo "❌ Frontend test failed"

echo "✅ Quick authentication fix complete!"
echo "🌍 Test your login at: https://unibus.online/auth"
