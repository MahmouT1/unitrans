#!/bin/bash

echo "🔧 Quick Auth Fix"

cd /home/unitrans

# Stop and restart backend
pm2 stop unitrans-backend
pm2 start server.js --name "unitrans-backend" --cwd backend-new

# Wait
sleep 5

# Test login
echo "🔐 Testing login..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}'

echo "✅ Quick auth fix complete!"
echo "🌍 Test at: https://unibus.online/auth"