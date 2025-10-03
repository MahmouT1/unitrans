#!/bin/bash

echo "🔧 إصلاح Student Subscription Page API Call"
echo "=============================================="

cd /var/www/unitrans && \
git pull origin main && \
cd frontend-new && \
pm2 stop unitrans-frontend && \
rm -rf .next && \
npm run build && \
pm2 restart unitrans-frontend && \
pm2 save && \
echo "" && \
echo "✅ تم الإصلاح بنجاح!" && \
echo "" && \
echo "📸 اختبر الآن في المتصفح (Firefox/Edge):" && \
echo "1. Student Portal → Subscription Tab" && \
echo "2. اضغط Refresh Data 🔄" && \
echo "3. يجب أن يظهر الاشتراك!"

