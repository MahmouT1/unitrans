#!/bin/bash

echo "🔧 إصلاح صفحات Transportation"
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
echo "📸 الآن في المتصفح:" && \
echo "  ✅ Admin → Transportation → إضافة جدول يعمل" && \
echo "  ✅ Student Portal → Dates & Locations → المواعيد تظهر"
