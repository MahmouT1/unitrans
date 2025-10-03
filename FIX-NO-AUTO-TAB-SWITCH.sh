#!/bin/bash

echo "🔧 إزالة التبديل التلقائي للتاب بعد QR Scan"
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
echo "📱 الآن على الموبايل:" && \
echo "  ✅ بعد QR Scan - الصفحة لن تتحرك" && \
echo "  ✅ يمكنك التنقل بين الأزرار بسهولة" && \
echo "  ✅ لا اهتزاز - لا حركة تلقائية"
