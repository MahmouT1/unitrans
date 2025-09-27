#!/bin/bash

# Quick Add Users Script
# This script quickly adds test users to the database

set -e

echo "👤 Quick Add Users to Database"

# Navigate to project directory
cd /home/unitrans

# Add users to database
echo "👥 Adding users to database..."
mongosh --eval "
use unitrans;

// Clear existing users
db.users.deleteMany({});

// Add test users
db.users.insertMany([
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
    email: 'sona123@gmail.com',
    password: 'sona123',
    fullName: 'Sona Mostafa',
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

# Test the users
echo "🔐 Testing users..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mostafamohamed@gmail.com","password":"student123","role":"student"}' \
  && echo "✅ Student login works" || echo "❌ Student login failed"

echo "✅ Users added successfully!"
echo "🔐 Test accounts:"
echo "  - Student: mostafamohamed@gmail.com / student123"
echo "  - Student: sona123@gmail.com / sona123"
echo "  - Admin: admin@unibus.com / admin123"
echo "  - Supervisor: supervisor@unibus.com / supervisor123"
echo "🌍 Test your login at: https://unibus.online/auth"
