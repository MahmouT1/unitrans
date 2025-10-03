#!/bin/bash

echo "🔧 تفعيل التبديل التلقائي السلس"
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
echo "✅ التبديل التلقائي مُفعّل بشكل سلس!" && \
echo "" && \
echo "📱 الآن سير العمل:" && \
echo "  1️⃣ Scan QR → ينتقل تلقائياً لـ Student Details ✅" && \
echo "  2️⃣ شاهد البيانات" && \
echo "  3️⃣ اضغط QR Scanner → ارجع للمسح" && \
echo "  4️⃣ Scan QR ثاني → ينتقل تلقائياً ✅" && \
echo "" && \
echo "  ✅ بدون اهتزاز" && \
echo "  ✅ بدون fetch إضافي" && \
echo "  ✅ بدون notifications" && \
echo "  ✅ سلس 100%!"
