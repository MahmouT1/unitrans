#!/bin/bash

echo "🔧 إصلاح QR Generation - حل بسيط"
echo "====================================="
echo ""

cd /var/www/unitrans

# نسخ الملف الجديد
cp new-qr-route.js frontend-new/app/api/students/generate-qr/route.js

echo "✅ تم استبدال route.js"
echo ""

# إعادة بناء
cd frontend-new
rm -rf .next
npm run build

# إعادة تشغيل
cd /var/www/unitrans
pm2 restart unitrans-frontend
pm2 save

echo ""
echo "انتظار 5 ثوان..."
sleep 5

# اختبار
echo ""
curl -X POST http://localhost:3000/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com"}' \
  | head -c 300

echo ""
echo ""
echo "✅ جرب في المتصفح الآن!"
