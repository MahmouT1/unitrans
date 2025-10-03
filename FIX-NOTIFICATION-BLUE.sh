#!/bin/bash

echo "🔵 إصلاح Notification - أزرق، ثانية واحدة، بدون اهتزاز"
echo "================================================================"
echo ""

cd /var/www/unitrans

echo "1️⃣ سحب التعديلات..."
git pull origin main

echo ""
echo "2️⃣ Rebuild Frontend..."

cd frontend-new

# إيقاف مؤقت (بدون حذف!)
pm2 stop unitrans-frontend

# Clean build
rm -rf .next

# Build
npm run build

# إعادة تشغيل (نفس الـ process!)
pm2 restart unitrans-frontend
pm2 save

sleep 5

pm2 list

echo ""
echo "=============================================="
echo "✅ التعديلات:"
echo "=============================================="
echo ""
echo "  ✅ اللون: أزرق بدلاً من الأخضر"
echo "  ✅ المدة: 1 ثانية بدلاً من 5"
echo "  ✅ بدون Animation/اهتزاز"
echo "  ✅ تُغلق تلقائياً"
echo ""
echo "في المتصفح Firefox/Edge:"
echo "1. Supervisor Dashboard"
echo "2. Scan QR Code"
echo "3. ✅ رسالة زرقاء بسيطة لمدة ثانية!"
echo ""

