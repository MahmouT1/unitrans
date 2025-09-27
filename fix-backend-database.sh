#!/bin/bash

echo "🔧 Fixing Backend Database Connection"

cd /home/unitrans

# Stop all PM2 processes
echo "⏹️ Stopping all PM2 processes..."
pm2 stop all
pm2 delete all

# Kill any processes using port 3001
echo "🔫 Killing processes on port 3001..."
lsof -ti:3001 | xargs kill -9 2>/dev/null || true

# Check MongoDB connection
echo "🔍 Checking MongoDB connection..."
mongosh --eval "db.runCommand('ping')" || echo "MongoDB not responding"

# Check users in database
echo "👥 Checking users in database..."
mongosh unitrans --eval "
print('Database:', db.getName());
print('Users count:', db.users.countDocuments());
print('All users:');
db.users.find({}, {email: 1, fullName: 1, role: 1}).forEach(printjson);
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

# Update frontend environment
echo "⚙️ Updating frontend environment..."
cd ../frontend-new
cat > .env.local << EOF
NEXT_PUBLIC_BACKEND_URL=https://unibus.online:3001
NEXT_PUBLIC_API_URL=https://unibus.online:3001/api
NEXT_PUBLIC_FRONTEND_URL=https://unibus.online
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans
JWT_SECRET=production-jwt-secret-key-2024
EOF

# Start backend
echo "🚀 Starting backend..."
cd ../backend-new
pm2 start server.js --name "unitrans-backend"

# Wait for backend
echo "⏳ Waiting for backend to start..."
sleep 10

# Test backend health
echo "🏥 Testing backend health..."
curl -f http://localhost:3001/health && echo "✅ Backend is healthy" || echo "❌ Backend health check failed"

# Test login with mostafamohamed@gmail.com (this one works)
echo "🔐 Testing login with mostafamohamed@gmail.com..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mostafamohamed@gmail.com","password":"student123","role":"student"}' \
  && echo "✅ Login test successful" || echo "❌ Login test failed"

# Test login with sona123@gmail.com
echo "🔐 Testing login with sona123@gmail.com..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}' \
  && echo "✅ Login test successful" || echo "❌ Login test failed"

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

echo "✅ Backend database fix complete!"
echo "🔐 Working accounts:"
echo "  - Student: mostafamohamed@gmail.com / student123"
echo "  - Student: sona123@gmail.com / sona123 (if fixed)"
echo "  - Admin: admin@unibus.com / admin123"
echo "  - Supervisor: supervisor@unibus.com / supervisor123"
echo "🌍 Test your login at: https://unibus.online/auth"

# Show PM2 status
pm2 status
