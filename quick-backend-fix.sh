#!/bin/bash

echo "🔧 Quick Backend Fix"

cd /home/unitrans

# Stop all processes
pm2 stop all
pm2 delete all

# Kill port 3001
lsof -ti:3001 | xargs kill -9 2>/dev/null || true

# Start backend
cd backend-new
pm2 start server.js --name "unitrans-backend"

# Wait
sleep 10

# Test login
echo "🔐 Testing login..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mostafamohamed@gmail.com","password":"student123","role":"student"}'

# Start frontend
cd ../frontend-new
pm2 start "npm run start" --name "unitrans-frontend"

echo "✅ Quick backend fix complete!"
echo "🔐 Test with: mostafamohamed@gmail.com / student123"
echo "🌍 Test at: https://unibus.online/auth"