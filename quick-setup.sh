#!/bin/bash

# Quick Setup Script for Production
# Run this on your VPS server

set -e

echo "🚀 Quick Production Setup for UniBus"

# Create project directory
echo "📁 Creating project directory..."
mkdir -p /home/unitrans
cd /home/unitrans

# Clone the project
echo "📥 Cloning project from GitHub..."
git clone https://github.com/MahmouT1/unitrans.git .

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd backend-new
npm install --production

# Create backend environment
echo "⚙️ Creating backend environment..."
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

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd ../frontend-new
npm install

# Create frontend environment
echo "⚙️ Creating frontend environment..."
cat > .env.local << EOF
NEXT_PUBLIC_BACKEND_URL=https://unibus.online:3001
NEXT_PUBLIC_API_URL=https://unibus.online:3001/api
NEXT_PUBLIC_FRONTEND_URL=https://unibus.online
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans
JWT_SECRET=production-jwt-secret-key-2024
EOF

# Build frontend
echo "🔨 Building frontend..."
npm run build

# Create uploads directory
echo "📁 Creating uploads directory..."
mkdir -p /home/unitrans/backend-new/uploads/profiles

# Start backend with PM2
echo "🚀 Starting backend..."
cd /home/unitrans/backend-new
pm2 start server.js --name "unitrans-backend"

# Start frontend with PM2
echo "🚀 Starting frontend..."
cd /home/unitrans/frontend-new
pm2 start "npm run start" --name "unitrans-frontend"

# Save PM2 configuration
echo "💾 Saving PM2 configuration..."
pm2 save

# Wait for services
echo "⏳ Waiting for services to start..."
sleep 10

# Test services
echo "🏥 Testing services..."
curl -f http://localhost:3001/health && echo "✅ Backend is healthy" || echo "❌ Backend health check failed"
curl -f http://localhost:3000 && echo "✅ Frontend is accessible" || echo "❌ Frontend test failed"

echo "✅ Quick setup complete!"
echo "🌍 Your project is now running at: https://unibus.online"
echo "🔐 Login at: https://unibus.online/auth"
