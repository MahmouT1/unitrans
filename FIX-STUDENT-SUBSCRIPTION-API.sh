#!/bin/bash

echo "🔧 إصلاح Student Subscription Page API Call"
echo "=============================================="

cd /var/www/unitrans/frontend-new

echo ""
echo "1️⃣ Stop Frontend..."
pm2 stop unitrans-frontend

echo ""
echo "2️⃣ Clean Build..."
rm -rf .next

echo ""
echo "3️⃣ Building..."
npm run build

echo ""
echo "4️⃣ Restart Frontend..."
pm2 restart unitrans-frontend
pm2 save

echo ""
echo "✅ تم الإصلاح!"
echo ""
echo "📸 اختبر الآن في المتصفح (Firefox/Edge):"
echo "1. Student Portal → Subscription Tab"
echo "2. اضغط Refresh Data 🔄"
echo "3. يجب أن يظهر الاشتراك!"

