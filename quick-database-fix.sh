#!/bin/bash

echo "🔧 Quick Database Fix"

cd /home/unitrans

# Stop PM2
pm2 stop all

# Start MongoDB
systemctl start mongod

# Add sona123@gmail.com user
mongosh unitrans --eval "
db.users.insertOne({
  email: 'sona123@gmail.com',
  password: 'sona123',
  fullName: 'Sona Mostafa',
  role: 'student',
  isActive: true,
  createdAt: new Date(),
  updatedAt: new Date()
});
print('User added!');
"

# Start backend
cd backend-new
pm2 start server.js --name "unitrans-backend"

# Wait
sleep 10

# Test login
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}'

# Start frontend
cd ../frontend-new
pm2 start "npm run start" --name "unitrans-frontend"

echo "✅ Quick fix complete!"
echo "🔐 Test: sona123@gmail.com / sona123"
echo "🌍 Test at: https://unibus.online/auth"
