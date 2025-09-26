#!/bin/bash

echo "🔧 Quick 502 Fix"

cd /home/unitrans

# Stop all services
pm2 stop all
pm2 delete all

# Start backend
cd backend-new
pm2 start server.js --name "unitrans-backend"

# Wait
sleep 10

# Start frontend
cd ../frontend-new
pm2 start "npm run start" --name "unitrans-frontend"

# Wait
sleep 15

# Reload Nginx
systemctl reload nginx

echo "✅ Quick 502 fix complete!"
echo "🌍 Test at: https://unibus.online"
