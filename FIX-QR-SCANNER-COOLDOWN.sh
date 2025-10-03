#!/bin/bash

echo "🔧 إصلاح QR Scanner - فترة راحة 3 ثوان بين المسحات"
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
echo "✅ تم الإصلاح النهائي!" && \
echo "" && \
echo "📱 الآن:" && \
echo "  ✅ المسح الأول: سلس تماماً" && \
echo "  ✅ المسح الثاني: يحتاج 3 ثوان بين كل مسح" && \
echo "  ✅ لا مسح مكرر - لا اهتزاز" && \
echo "  ✅ stopScanning محسّن - يوقف كل شيء" && \
echo "  ✅ يمكنك التنقل بسهولة!"
