#!/bin/bash

echo "👥 Adding Users to Production Database"

# Navigate to project directory
cd /home/unitrans

# Add users directly to MongoDB
echo "🔍 Adding users to database..."
mongosh unitrans --eval "
// Clear existing users first
db.users.deleteMany({});

// Add users
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

print('✅ Users added successfully!');
print('📊 Total users:', db.users.countDocuments());
print('👥 User list:');
db.users.find({}, {email: 1, fullName: 1, role: 1}).forEach(printjson);
"

# Test login
echo "🔐 Testing login..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}' \
  && echo "✅ Login test successful" || echo "❌ Login test failed"

echo "✅ Users added to production database!"
echo "🔐 Test accounts:"
echo "  - Student: sona123@gmail.com / sona123"
echo "  - Student: mostafamohamed@gmail.com / student123"
echo "  - Admin: admin@unibus.com / admin123"
echo "  - Supervisor: supervisor@unibus.com / supervisor123"
echo "🌍 Test your login at: https://unibus.online/auth"
