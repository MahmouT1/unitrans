#!/bin/bash

echo "🔧 Fixing Frontend Port Issue"

cd /home/unitrans

# Check what's running on port 3000
echo "🔍 Checking port 3000..."
netstat -tlnp | grep :3000 || echo "Port 3000 is free"

# Check PM2 status
echo "🔍 Checking PM2 status..."
pm2 list

# Stop all PM2 processes
echo "⏹️ Stopping all PM2 processes..."
pm2 stop all
pm2 delete all

# Kill any processes on port 3000
echo "🔧 Killing processes on port 3000..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

# Check if frontend directory exists
echo "🔍 Checking frontend directory..."
if [ -d "frontend-new" ]; then
    echo "✅ Frontend directory exists"
    cd frontend-new
    
    # Check if node_modules exists
    if [ -d "node_modules" ]; then
        echo "✅ node_modules exists"
    else
        echo "🔧 Installing frontend dependencies..."
        npm install
    fi
    
    # Check if .next exists
    if [ -d ".next" ]; then
        echo "✅ .next build exists"
    else
        echo "🔧 Building frontend..."
        npm run build
    fi
    
    # Start frontend with PM2
    echo "🚀 Starting frontend with PM2..."
    pm2 start "npm run start" --name "unitrans-frontend" --time
    
    # Wait for frontend to start
    echo "⏳ Waiting for frontend to start..."
    sleep 15
    
    # Test frontend
    echo "🔍 Testing frontend..."
    curl -f http://localhost:3000 && echo "✅ Frontend works" || echo "❌ Frontend failed"
    
else
    echo "❌ Frontend directory not found"
    exit 1
fi

# Start backend if not running
echo "🔍 Checking backend..."
if ! pm2 list | grep -q "unitrans-backend"; then
    echo "🚀 Starting backend..."
    cd ../backend-new
    pm2 start "npm start" --name "unitrans-backend" --time
fi

# Wait for both to start
echo "⏳ Waiting for services to start..."
sleep 10

# Test both services
echo "🔍 Testing services..."
curl -f http://localhost:3000 && echo "✅ Frontend works" || echo "❌ Frontend failed"
curl -f http://localhost:3001/api/health && echo "✅ Backend works" || echo "❌ Backend failed"

# Test through Nginx
echo "🔍 Testing through Nginx..."
curl -f https://unibus.online && echo "✅ Site works" || echo "❌ Site failed"

echo "✅ Frontend port fix complete!"
echo "🌍 Test your site at: https://unibus.online"
