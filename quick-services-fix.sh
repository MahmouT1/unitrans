#!/bin/bash

echo "🔧 Quick Services Fix"

cd /home/unitrans

# Stop all PM2 processes
pm2 stop all
pm2 delete all

# Kill processes on ports
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
lsof -ti:3001 | xargs kill -9 2>/dev/null || true

# Wait
sleep 5

# Start backend first
cd backend-new
pm2 start "npm start" --name "unitrans-backend"

# Wait for backend
sleep 10

# Start frontend
cd ../frontend-new
pm2 start "npm run start" --name "unitrans-frontend"

# Wait for frontend
sleep 15

# Test
curl -f http://localhost:3001/api/health && echo "✅ Backend works" || echo "❌ Backend failed"
curl -f http://localhost:3000 && echo "✅ Frontend works" || echo "❌ Frontend failed"
curl -f https://unibus.online && echo "✅ Site works" || echo "❌ Site failed"

echo "✅ Quick services fix complete!"
