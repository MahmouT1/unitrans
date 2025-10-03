#!/bin/bash

echo "🔧 تبديل سلس للتاب بعد QR Scan"
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
echo "✅ الإصلاح النهائي!" && \
echo "" && \
echo "📱 التحسينات:" && \
echo "  ✅ Cooldown 3 ثوان بين المسحات" && \
echo "  ✅ تبديل سلس للتاب (100ms delay)" && \
echo "  ✅ بدون fetch إضافي" && \
echo "  ✅ بدون notifications" && \
echo "  ✅ stopScanning محسّن" && \
echo "" && \
echo "📱 جرب الآن:" && \
echo "  Scan → Student Details يظهر → Back → Scan ثاني" && \
echo "  سلس 100% بدون اهتزاز!"
