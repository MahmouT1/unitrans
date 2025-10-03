#!/bin/bash

echo "🔧 إصلاح تعارض QR Scan - توحيد السلوك"
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
echo "✅ تم إصلاح التعارض!" && \
echo "" && \
echo "📱 الآن سير العمل موحد:" && \
echo "  1️⃣ Scan QR → Student Details (سلس)" && \
echo "  2️⃣ شاهد البيانات" && \
echo "  3️⃣ اضغط QR Scanner → ارجع للمسح" && \
echo "  4️⃣ Scan ثاني → Student Details (سلس)" && \
echo "" && \
echo "  ✅ بدون conflict" && \
echo "  ✅ بدون اهتزاز" && \
echo "  ✅ بدون رجوع تلقائي" && \
echo "  ✅ سلاسة كاملة!"
