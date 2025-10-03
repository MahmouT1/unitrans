#!/bin/bash

echo "🔧 استعادة الصفحة البسيطة لـ Subscriptions"
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
echo "✅ تم استعادة الصفحة البسيطة!" && \
echo "" && \
echo "📸 افتح المتصفح واختبر:" && \
echo "unibus.online/admin/subscriptions"
