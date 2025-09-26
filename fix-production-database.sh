#!/bin/bash

# Fix Production Database Connection
# This script fixes the database connection on production server

set -e

echo "🔧 Fixing Production Database Connection"

# Navigate to project directory
cd /home/unitrans

# Stop PM2 processes
echo "⏹️ Stopping PM2 processes..."
pm2 stop all

# Check MongoDB status
echo "📊 Checking MongoDB status..."
systemctl status mongod --no-pager -l
systemctl start mongod
systemctl enable mongod

# Check if MongoDB is running
echo "🔍 Checking MongoDB connection..."
mongosh --eval "db.runCommand('ping')" || echo "MongoDB not responding"

# Check current database
echo "🔍 Checking current database..."
mongosh --eval "
use unitrans;
print('Database:', db.getName());
print('Collections:', db.getCollectionNames());
print('Users count:', db.users.countDocuments());
"

# Add users from local database
echo "👥 Adding users from local database..."
mongosh --eval "
use unitrans;

// Clear existing users
db.users.deleteMany({});

// Add users that work locally
db.users.insertMany([
  {
    email: 'sona123@gmail.com',
    password: 'sona123',
    fullName: 'Sona Mostafa',
    role: 'student',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    email: 'mostafamohamed@gmail.com',
    password: 'student123',
    fullName: 'Mostafa Mohamed',
    role: 'student',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    email: 'admin@unibus.com',
    password: 'admin123',
    fullName: 'System Administrator',
    role: 'admin',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    email: 'supervisor@unibus.com',
    password: 'supervisor123',
    fullName: 'Transportation Supervisor',
    role: 'supervisor',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);

print('Users added successfully!');
print('Total users:', db.users.countDocuments());
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

# Test backend
echo "🏥 Testing backend..."
curl -f http://localhost:3001/health && echo "✅ Backend is healthy" || echo "❌ Backend health check failed"

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

# Test through HTTPS
echo "🌐 Testing through HTTPS..."
curl -X POST https://unibus.online/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}' \
  && echo "✅ HTTPS login test successful" || echo "❌ HTTPS login test failed"

echo "✅ Production database fix complete!"
echo "🔐 Test accounts:"
echo "  - Student: sona123@gmail.com / sona123"
echo "  - Student: mostafamohamed@gmail.com / student123"
echo "  - Admin: admin@unibus.com / admin123"
echo "  - Supervisor: supervisor@unibus.com / supervisor123"
echo "🌍 Test your login at: https://unibus.online/auth"

# Show PM2 status
pm2 status
