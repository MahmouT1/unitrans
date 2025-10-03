#!/bin/bash

echo "🔧 إصلاح زر OK على الموبايل"
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
echo "📱 الآن زر OK سيعمل على الموبايل!"
