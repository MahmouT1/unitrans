#!/bin/bash

echo "🔧 إصلاح Admin Subscriptions API"
echo "=============================================="

cd /var/www/unitrans && \
git pull origin main && \
cd backend-new && \
pm2 restart unitrans-backend && \
sleep 2 && \
cd ../frontend-new && \
pm2 stop unitrans-frontend && \
rm -rf .next && \
npm run build && \
pm2 restart unitrans-frontend && \
pm2 save && \
echo "" && \
echo "✅ تم الإصلاح بنجاح!" && \
echo "" && \
echo "🧪 اختبار Backend API..." && \
curl -s "http://localhost:3001/api/subscriptions" | jq '.success, .subscriptions | length' && \
echo "" && \
echo "📸 اختبر الآن في المتصفح:" && \
echo "1. Admin → Subscription Management" && \
echo "2. اضغط Refresh Data 🔄" && \
echo "3. يجب أن تظهر جميع الاشتراكات!"
