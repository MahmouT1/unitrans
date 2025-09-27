#!/bin/bash

echo "🔧 Quick Frontend Fix"

cd /home/unitrans

# Stop all PM2 processes
pm2 stop all
pm2 delete all

# Kill processes on port 3000
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

# Start frontend
cd frontend-new
pm2 start "npm run start" --name "unitrans-frontend"

# Start backend
cd ../backend-new
pm2 start "npm start" --name "unitrans-backend"

# Wait and test
sleep 15
curl -f http://localhost:3000 && echo "✅ Frontend works" || echo "❌ Frontend failed"
curl -f https://unibus.online && echo "✅ Site works" || echo "❌ Site failed"

echo "✅ Quick frontend fix complete!"
