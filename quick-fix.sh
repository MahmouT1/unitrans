#!/bin/bash

echo "🔧 Quick Fix - Adding User"

cd /home/unitrans

# Add user directly
mongosh unitrans --eval "
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
"

# Test
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mostafamohamed@gmail.com","password":"student123","role":"student"}'

echo "✅ Done! Test at: https://unibus.online/auth"
