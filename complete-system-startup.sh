#!/bin/bash

echo "🚀 Complete System Startup - Backend & Frontend"
echo "=============================================="

cd /home/unitrans

# Check current status
echo "📊 Current PM2 status:"
pm2 status

# Check if backend is running
echo "🔍 Checking backend status..."
if pm2 status | grep -q "unitrans-backend.*online"; then
    echo "✅ Backend is running"
else
    echo "❌ Backend is not running"
    exit 1
fi

# Test backend health
echo "🏥 Testing backend health..."
curl -s http://localhost:3001/api/health || echo "Backend health check failed"

# Start frontend
echo "🚀 Starting frontend..."
cd frontend-new

# Check if frontend directory exists
if [ ! -d "." ]; then
    echo "❌ Frontend directory not found"
    exit 1
fi

# Check package.json
if [ ! -f "package.json" ]; then
    echo "❌ Frontend package.json not found"
    exit 1
fi

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
npm install

# Check environment variables
echo "⚙️ Checking frontend environment variables..."
if [ -f ".env.local" ]; then
    echo "✅ .env.local file exists"
    cat .env.local
else
    echo "❌ .env.local file not found"
    echo "Creating .env.local file..."
    cat > .env.local << 'EOF'
NEXT_PUBLIC_BACKEND_URL=http://localhost:3001
NEXT_PUBLIC_API_URL=http://localhost:3001/api
NEXT_PUBLIC_FRONTEND_URL=https://unibus.online
NODE_ENV=production
EOF
fi

# Start frontend with PM2
echo "🚀 Starting frontend with PM2..."
pm2 start "npm run start" --name "unitrans-frontend"

# Wait for frontend to start
echo "⏳ Waiting for frontend to start..."
sleep 20

# Check PM2 status
echo "📊 Checking PM2 status after frontend start:"
pm2 status

# Test frontend
echo "🌐 Testing frontend..."
for i in {1..5}; do
    echo "Attempt $i..."
    if curl -s http://localhost:3000 | head -5; then
        echo "✅ Frontend is responding!"
        break
    else
        echo "❌ Frontend not responding, waiting..."
        sleep 10
    fi
done

# Check frontend logs
echo "📋 Checking frontend logs..."
pm2 logs unitrans-frontend --lines 10

# Test production domain
echo "🌍 Testing production domain..."
curl -s -o /dev/null -w "%{http_code}" https://unibus.online

# Test API endpoints
echo "🧪 Testing API endpoints..."
echo "Testing /api/health:"
curl -s http://localhost:3001/api/health || echo "Health endpoint failed"

echo "Testing /api/auth/login:"
curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test"}' || echo "Login endpoint failed"

# Final status
echo ""
echo "📊 Final System Status:"
echo "======================"
pm2 status

echo ""
echo "🌍 Test your application:"
echo "Frontend: https://unibus.online"
echo "Backend API: http://localhost:3001/api"
echo "Health Check: http://localhost:3001/api/health"

echo ""
echo "✅ System startup completed!"
echo "📋 Check logs with: pm2 logs"
echo "🔄 Restart services with: pm2 restart all"
