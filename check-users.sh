#!/bin/bash

# Check Users Script
# This script checks if users were added successfully

set -e

echo "👥 Checking Users in Database"

# Navigate to project directory
cd /home/unitrans

# Check users in database
echo "🔍 Checking users in database..."
mongosh --eval "
use unitrans;
print('Total users:', db.users.countDocuments());
print('All users:');
db.users.find().forEach(function(user) {
  print('Email:', user.email);
  print('Name:', user.fullName);
  print('Role:', user.role);
  print('Active:', user.isActive);
  print('---');
});
"

# Test login with each user
echo "🔐 Testing login with each user..."

echo "Testing student login..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mostafamohamed@gmail.com","password":"student123","role":"student"}' \
  && echo "✅ Student login works" || echo "❌ Student login failed"

echo "Testing admin login..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@unibus.com","password":"admin123","role":"admin"}' \
  && echo "✅ Admin login works" || echo "❌ Admin login failed"

echo "Testing supervisor login..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"supervisor@unibus.com","password":"supervisor123","role":"supervisor"}' \
  && echo "✅ Supervisor login works" || echo "❌ Supervisor login failed"

echo "✅ User check complete!"
echo "🌍 Test your login at: https://unibus.online/auth"
