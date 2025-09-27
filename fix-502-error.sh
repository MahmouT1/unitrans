#!/bin/bash

echo "🔧 Fixing 502 Bad Gateway Error"

cd /home/unitrans

# Check PM2 status
echo "📊 Checking PM2 status..."
pm2 status

# Check if services are running
echo "🔍 Checking if services are running..."
curl -f http://localhost:3000 && echo "✅ Frontend is running" || echo "❌ Frontend is not running"
curl -f http://localhost:3001/health && echo "✅ Backend is running" || echo "❌ Backend is not running"

# Restart all services
echo "🔄 Restarting all services..."
pm2 stop all
pm2 delete all

# Start backend
echo "🚀 Starting backend..."
cd backend-new
pm2 start server.js --name "unitrans-backend"

# Wait for backend
echo "⏳ Waiting for backend to start..."
sleep 10

# Test backend
echo "🔍 Testing backend..."
curl -f http://localhost:3001/health && echo "✅ Backend is healthy" || echo "❌ Backend health check failed"

# Start frontend
echo "🚀 Starting frontend..."
cd ../frontend-new
pm2 start "npm run start" --name "unitrans-frontend"

# Wait for frontend
echo "⏳ Waiting for frontend to start..."
sleep 15

# Test frontend
echo "🔍 Testing frontend..."
curl -f http://localhost:3000 && echo "✅ Frontend is accessible" || echo "❌ Frontend test failed"

# Check Nginx status
echo "🔍 Checking Nginx status..."
systemctl status nginx --no-pager -l

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
nginx -t

# Reload Nginx
echo "🔄 Reloading Nginx..."
systemctl reload nginx

# Test through Nginx
echo "🔍 Testing through Nginx..."
curl -f https://unibus.online && echo "✅ Nginx proxy works" || echo "❌ Nginx proxy failed"

# Test API through Nginx
echo "🔍 Testing API through Nginx..."
curl -X POST https://unibus.online/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}' \
  && echo "✅ API through Nginx works" || echo "❌ API through Nginx failed"

echo "✅ 502 error fix complete!"
echo "🌍 Test your site at: https://unibus.online"
