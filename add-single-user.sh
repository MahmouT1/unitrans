#!/bin/bash

echo "👤 Adding Single User to Database"

cd /home/unitrans

# Add single user
mongosh --eval "
use unitrans;
db.users.insertOne({
  email: 'mostafamohamed@gmail.com',
  password: 'student123',
  fullName: 'Mostafa Mohamed',
  role: 'student',
  isActive: true,
  createdAt: new Date(),
  updatedAt: new Date()
});
print('User added successfully!');
print('Total users:', db.users.countDocuments());
"

# Test login
echo "🔐 Testing login..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mostafamohamed@gmail.com","password":"student123","role":"student"}' \
  && echo "✅ Login test successful" || echo "❌ Login test failed"

echo "✅ Single user added!"
echo "🔐 Test: mostafamohamed@gmail.com / student123"
echo "🌍 Test at: https://unibus.online/auth"
