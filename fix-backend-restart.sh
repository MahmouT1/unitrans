#!/bin/bash

echo "🔧 Fixing Backend Restart - Database Connection Issue"
echo "=================================================="

cd /home/unitrans

# Stop all PM2 processes
echo "⏹️ Stopping all PM2 processes..."
pm2 stop all
pm2 delete all

# Kill any processes on port 3001
echo "🔪 Killing processes on port 3001..."
lsof -ti:3001 | xargs kill -9 2>/dev/null || echo "No processes on port 3001"

# Check MongoDB status
echo "📊 Checking MongoDB status..."
systemctl status mongod --no-pager

# Test MongoDB connection
echo "🔗 Testing MongoDB connection..."
mongosh --eval "db.runCommand('ping')" unitrans

# Check backend directory
echo "📁 Checking backend directory..."
cd backend-new
ls -la

# Check package.json
echo "📄 Checking package.json..."
if [ -f "package.json" ]; then
    echo "✅ package.json exists"
    cat package.json | grep -E "(name|version|scripts)"
else
    echo "❌ package.json not found"
    exit 1
fi

# Install dependencies
echo "📦 Installing backend dependencies..."
npm install

# Check environment variables
echo "⚙️ Checking environment variables..."
if [ -f ".env" ]; then
    echo "✅ .env file exists"
    cat .env
else
    echo "❌ .env file not found"
    echo "Creating .env file..."
    cat > .env << 'EOF'
PORT=3001
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans
NODE_ENV=production
JWT_SECRET=your-secret-key-here
EOF
fi

# Start backend with PM2
echo "🚀 Starting backend with PM2..."
pm2 start "npm run start" --name "unitrans-backend"

# Wait for backend to start
echo "⏳ Waiting for backend to start..."
sleep 10

# Check PM2 status
echo "📊 Checking PM2 status..."
pm2 status

# Test backend health
echo "🏥 Testing backend health..."
for i in {1..5}; do
    echo "Attempt $i..."
    if curl -s http://localhost:3001/api/health; then
        echo "✅ Backend is healthy!"
        break
    else
        echo "❌ Backend not responding, waiting..."
        sleep 5
    fi
done

# Check backend logs
echo "📋 Checking backend logs..."
pm2 logs unitrans-backend --lines 10

# Test database connection from backend
echo "🧪 Testing database connection from backend..."
curl -s http://localhost:3001/api/health | jq . || echo "Health check failed"

# Start frontend
echo "🚀 Starting frontend..."
cd ../frontend-new
pm2 start "npm run start" --name "unitrans-frontend"

# Wait for frontend to start
echo "⏳ Waiting for frontend to start..."
sleep 15

# Test frontend
echo "🌐 Testing frontend..."
curl -s http://localhost:3000 | head -5 || echo "Frontend not responding"

# Final PM2 status
echo "📊 Final PM2 status:"
pm2 status

# Test production domain
echo "🌍 Testing production domain..."
curl -s -o /dev/null -w "%{http_code}" https://unibus.online

echo ""
echo "✅ Backend restart completed!"
echo "🌍 Test your project at: https://unibus.online"
echo "📊 Check PM2 status with: pm2 status"
echo "📋 Check logs with: pm2 logs"
