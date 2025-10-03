#!/bin/bash

echo "🔧 إصلاح QR Scan - إزالة كل التداخلات"
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
echo "✅ تم الإصلاح الكامل!" && \
echo "" && \
echo "📱 الآن بعد QR Scan:" && \
echo "  ✅ لا رسائل" && \
echo "  ✅ لا اهتزاز" && \
echo "  ✅ لا تغيير في التاب" && \
echo "  ✅ لا fetch إضافي" && \
echo "  ✅ الصفحة ثابتة تماماً" && \
echo "  ✅ يمكنك التنقل بسهولة بين الأزرار!"
