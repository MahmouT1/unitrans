#!/bin/bash

echo "🔄 إعادة تشغيل Backend واختباره"
echo "===================================="

cd /var/www/unitrans

# 1. إعادة تشغيل Backend
echo "1. إعادة تشغيل Backend..."
cd backend-new

pm2 delete backend-new 2>/dev/null || true
pm2 start server.js --name backend-new

pm2 save

cd ..

echo "✅ تم تشغيل Backend"
echo ""

# 2. انتظار
echo "2. انتظار 5 ثوان..."
sleep 5

# 3. اختبار Backend
echo "3. اختبار Backend API..."
echo ""

curl -s http://localhost:3001/api/students/all?page=1&limit=3 | head -30

echo ""
echo ""
echo "===================================="
echo "✅ تم! جرب الصفحة الآن"
echo "===================================="
