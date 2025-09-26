#!/bin/bash

echo "🔧 Complete Services Fix"

cd /home/unitrans

# Stop all PM2 processes
echo "⏹️ Stopping all PM2 processes..."
pm2 stop all
pm2 delete all

# Kill all processes on ports 3000 and 3001
echo "🔧 Killing processes on ports 3000 and 3001..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
lsof -ti:3001 | xargs kill -9 2>/dev/null || true

# Wait a moment
sleep 5

# Check if directories exist
echo "🔍 Checking directories..."
if [ ! -d "frontend-new" ]; then
    echo "❌ Frontend directory not found"
    exit 1
fi

if [ ! -d "backend-new" ]; then
    echo "❌ Backend directory not found"
    exit 1
fi

# Fix frontend
echo "🔧 Fixing frontend..."
cd frontend-new

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "❌ package.json not found in frontend"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "🔧 Installing frontend dependencies..."
    npm install
fi

# Build frontend
echo "🔧 Building frontend..."
npm run build

# Start frontend with PM2
echo "🚀 Starting frontend..."
pm2 start "npm run start" --name "unitrans-frontend" --time

# Wait for frontend
echo "⏳ Waiting for frontend to start..."
sleep 20

# Check frontend status
echo "🔍 Checking frontend status..."
pm2 list

# Test frontend
echo "🔍 Testing frontend..."
curl -f http://localhost:3000 && echo "✅ Frontend works" || echo "❌ Frontend failed"

# Fix backend
echo "🔧 Fixing backend..."
cd ../backend-new

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "❌ package.json not found in backend"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "🔧 Installing backend dependencies..."
    npm install
fi

# Start backend with PM2
echo "🚀 Starting backend..."
pm2 start "npm start" --name "unitrans-backend" --time

# Wait for backend
echo "⏳ Waiting for backend to start..."
sleep 15

# Check backend status
echo "🔍 Checking backend status..."
pm2 list

# Test backend
echo "🔍 Testing backend..."
curl -f http://localhost:3001/api/health && echo "✅ Backend works" || echo "❌ Backend failed"

# Test through Nginx
echo "🔍 Testing through Nginx..."
curl -f https://unibus.online && echo "✅ Site works" || echo "❌ Site failed"

# Show final status
echo "🔍 Final PM2 status..."
pm2 list

echo "✅ Complete services fix done!"
echo "🌍 Test your site at: https://unibus.online"
