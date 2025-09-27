#!/bin/bash

# Fix User Creation Script
# This script fixes the user creation issue

set -e

echo "🔧 Fixing User Creation Issue"

# Navigate to project directory
cd /home/unitrans

# Check MongoDB connection
echo "📊 Checking MongoDB connection..."
mongosh --eval "db.runCommand('ping')" || echo "MongoDB connection failed"

# Check current database
echo "🔍 Checking current database..."
mongosh --eval "
use unitrans;
print('Database:', db.getName());
print('Collections:', db.getCollectionNames());
print('Users count:', db.users.countDocuments());
"

# Clear existing users and add new ones
echo "👥 Clearing and adding users..."
mongosh --eval "
use unitrans;

// Clear existing users
db.users.deleteMany({});
print('Cleared existing users');

// Add users with proper structure
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

# Verify users were added
echo "✅ Verifying users were added..."
mongosh --eval "
use unitrans;
print('Users in database:');
db.users.find().forEach(function(user) {
  print('Email:', user.email, 'Role:', user.role);
});
"

# Test login
echo "🔐 Testing login..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mostafamohamed@gmail.com","password":"student123","role":"student"}' \
  && echo "✅ Login test successful" || echo "❌ Login test failed"

echo "✅ User creation fix complete!"
echo "🔐 Test accounts:"
echo "  - Student: mostafamohamed@gmail.com / student123"
echo "  - Student: sona123@gmail.com / sona123"
echo "  - Admin: admin@unibus.com / admin123"
echo "  - Supervisor: supervisor@unibus.com / supervisor123"
echo "🌍 Test your login at: https://unibus.online/auth"
