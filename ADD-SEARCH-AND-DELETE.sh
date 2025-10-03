#!/bin/bash

echo "🔧 إضافة البحث وزر الحذف لصفحة Subscriptions"
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
echo "✅ تم إضافة الميزات بنجاح!" && \
echo "" && \
echo "📸 الميزات الجديدة:" && \
echo "  1. 🔍 شريط بحث بالاسم أو الإيميل" && \
echo "  2. 🗑️  زر حذف لكل اشتراك" && \
echo "" && \
echo "اختبر الآن في المتصفح!"
