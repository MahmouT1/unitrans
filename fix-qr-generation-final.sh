#!/bin/bash

echo "🔧 إصلاح QR Generation - الحل النهائي"
echo "====================================="

cd /var/www/unitrans

echo ""
echo "🔧 1️⃣ إيقاف Backend:"
pm2 stop unitrans-backend
pm2 delete unitrans-backend

echo ""
echo "🔧 2️⃣ حذف students.js القديم واستعادة النسخة الجديدة:"
cd /var/www/unitrans

# Force pull latest changes
git fetch origin
git checkout origin/main -- backend-new/routes/students.js

echo ""
echo "🔍 3️⃣ فحص الكود الجديد:"
grep -A 15 "router.post('/generate-qr'" backend-new/routes/students.js | head -20

echo ""
echo "🔧 4️⃣ إعادة تثبيت Dependencies:"
cd backend-new
npm install

echo ""
echo "🔧 5️⃣ بدء Backend:"
pm2 start server.js --name "unitrans-backend"

echo ""
echo "⏳ انتظار 10 ثواني..."
sleep 10

echo ""
echo "🔍 6️⃣ فحص Backend:"
pm2 status unitrans-backend
pm2 logs unitrans-backend --lines 10 --nostream

echo ""
echo "🧪 7️⃣ اختبار QR Generation:"
echo "=========================="

echo "🧪 اختبار 1: مع email:"
curl -X POST http://localhost:3001/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com"}' \
  -s | jq '.success, .message' | head -2

echo ""
echo "🧪 اختبار 2: مع studentData:"
curl -X POST http://localhost:3001/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentData":{"email":"mahmoudtarekmonaim@gmail.com"}}' \
  -s | jq '.success, .message' | head -2

echo ""
echo "✅ تم!"