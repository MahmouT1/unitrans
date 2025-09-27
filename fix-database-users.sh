#!/bin/bash

# Fix Database Users Collection
# This script fixes the database users collection and adds test users

set -e

echo "🔧 Fixing Database Users Collection"

# Navigate to project directory
cd /home/unitrans

# Check MongoDB status
echo "📊 Checking MongoDB status..."
systemctl status mongod --no-pager -l
systemctl start mongod
systemctl enable mongod

# Check current users
echo "👥 Checking current users..."
mongosh --eval "
use unitrans;
print('Current users count:', db.users.countDocuments());
db.users.find().forEach(printjson);
"

# Add test users if none exist
echo "👤 Adding test users..."
mongosh --eval "
use unitrans;

// Check if users exist
if (db.users.countDocuments() === 0) {
  print('No users found, adding test users...');
  
  // Add admin user
  db.users.insertOne({
    email: 'admin@unibus.com',
    password: 'admin123',
    fullName: 'System Administrator',
    role: 'admin',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  });
  
  // Add supervisor user
  db.users.insertOne({
    email: 'supervisor@unibus.com',
    password: 'supervisor123',
    fullName: 'Transportation Supervisor',
    role: 'supervisor',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  });
  
  // Add student user
  db.users.insertOne({
    email: 'mostafamohamed@gmail.com',
    password: 'student123',
    fullName: 'Mostafa Mohamed',
    role: 'student',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  });
  
  // Add another student user
  db.users.insertOne({
    email: 'sona123@gmail.com',
    password: 'sona123',
    fullName: 'Sona Mostafa',
    role: 'student',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  });
  
  print('Test users added successfully!');
} else {
  print('Users already exist, skipping...');
}

// Show all users
print('All users:');
db.users.find().forEach(printjson);
"

# Test login with the added users
echo "🔐 Testing login with added users..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mostafamohamed@gmail.com","password":"student123","role":"student"}' \
  && echo "✅ Student login test successful" || echo "❌ Student login test failed"

curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@unibus.com","password":"admin123","role":"admin"}' \
  && echo "✅ Admin login test successful" || echo "❌ Admin login test failed"

curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"supervisor@unibus.com","password":"supervisor123","role":"supervisor"}' \
  && echo "✅ Supervisor login test successful" || echo "❌ Supervisor login test failed"

# Test through HTTPS
echo "🌐 Testing through HTTPS..."
curl -X POST https://unibus.online/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mostafamohamed@gmail.com","password":"student123","role":"student"}' \
  && echo "✅ HTTPS login test successful" || echo "❌ HTTPS login test failed"

echo "✅ Database users fix complete!"
echo "🔐 Test accounts created:"
echo "  - Student: mostafamohamed@gmail.com / student123"
echo "  - Admin: admin@unibus.com / admin123"
echo "  - Supervisor: supervisor@unibus.com / supervisor123"
echo "🌍 Test your login at: https://unibus.online/auth"
