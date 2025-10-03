#!/bin/bash

echo "🔧 إزالة اهتزاز الإشعار على الموبايل"
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
echo "✅ تم الإصلاح!" && \
echo "" && \
echo "📱 على الموبايل:" && \
echo "1. افتح Supervisor Dashboard" && \
echo "2. امسح QR Code" && \
echo "3. ✅ الإشعار سيظهر بدون اهتزاز!"
