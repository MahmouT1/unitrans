#!/bin/bash

echo "🔧 تشغيل Backend - الحل المباشر"
echo "================================"

cd /var/www/unitrans

# Stop backend
pm2 stop unitrans-backend 2>/dev/null
pm2 delete unitrans-backend 2>/dev/null

# Fix the corrupted students.js file
echo "🔧 إصلاح students.js..."

# Remove the corrupted file and restore from git
cd /var/www/unitrans
git checkout HEAD -- backend-new/routes/students.js

# Start backend
echo "🚀 بدء Backend..."
cd /var/www/unitrans/backend-new
pm2 start server.js --name "unitrans-backend"

# Wait and check
sleep 10

echo ""
echo "🔍 حالة Backend:"
pm2 status unitrans-backend

echo ""
echo "🔍 Backend Logs:"
pm2 logs unitrans-backend --lines 10 --nostream

echo ""
echo "✅ تم تشغيل Backend!"
