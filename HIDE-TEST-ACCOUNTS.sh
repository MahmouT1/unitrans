#!/bin/bash

echo "🙈 إخفاء قائمة حسابات الاختبار من صفحة Login"
echo "================================================"

cd /var/www/unitrans && \
git pull origin main && \
cd frontend-new && \
pm2 stop unitrans-frontend && \
rm -rf .next && \
npm run build && \
pm2 restart unitrans-frontend && \
pm2 save && \
echo "" && \
echo "✅ تم إخفاء قائمة حسابات الاختبار!" && \
echo "" && \
echo "📱 افتح المتصفح:" && \
echo "  🔗 unibus.online/login" && \
echo "  ✅ قائمة حسابات الاختبار اختفت!"
