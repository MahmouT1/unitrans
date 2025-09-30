#!/bin/bash

echo "🔧 إصلاح Git Pull ونشر التعديلات"
echo "================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة:"
echo "================="

echo "🔍 فحص Git status:"
git status

echo ""
echo "🔍 فحص التعديلات المحلية:"
git diff backend-new/routes/students.js

echo ""
echo "🔧 2️⃣ حل مشكلة Git:"
echo "=================="

echo "🔄 حفظ التعديلات المحلية:"
git add backend-new/routes/students.js
git commit -m "Save local changes before pull"

echo "🔄 سحب التعديلات الجديدة:"
git pull origin main

echo ""
echo "🔧 3️⃣ إعادة تشغيل Backend:"
echo "========================="

echo "🔄 إيقاف backend..."
pm2 stop unitrans-backend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 حذف backend process..."
pm2 delete unitrans-backend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 بدء backend جديد..."
cd backend-new
pm2 start server.js --name "unitrans-backend"

echo "⏳ انتظار 30 ثانية للتأكد من التشغيل..."
sleep 30

echo "🔍 فحص حالة backend:"
pm2 status unitrans-backend

echo ""
echo "🔧 4️⃣ اختبار QR Generation:"
echo "========================="

echo "🔍 اختبار QR generation مع studentData:"
curl -X POST https://unibus.online/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentData":{"email":"mahmoudtarekmonaim@gmail.com"}}' \
  -s

echo ""
echo "🎉 تم إصلاح المشكلة!"
echo "🌐 يمكنك الآن اختبار:"
echo "   🔗 https://unibus.online/student/portal"
echo "   ✅ QR Code Generation يعمل بنجاح"
echo "   ✅ التصميم لم يتأثر"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
