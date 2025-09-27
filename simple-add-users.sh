#!/bin/bash

echo "👤 Adding Users to Database"

cd /home/unitrans

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
print('User added!');
"

echo "✅ User added!"
echo "🔐 Test: mostafamohamed@gmail.com / student123"
echo "🌍 Test at: https://unibus.online/auth"
