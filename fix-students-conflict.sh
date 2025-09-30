#!/bin/bash

echo "🔧 إصلاح Git Conflict في students.js"
echo "====================================="

cd /var/www/unitrans

# إيقاف Backend
pm2 stop unitrans-backend
pm2 delete unitrans-backend

# حذف الملف التالف واستعادة النسخة الصحيحة
echo "🔧 استعادة students.js من Git..."
git checkout HEAD -- backend-new/routes/students.js

# التأكد من عدم وجود conflict markers
echo "🔍 فحص Conflict markers..."
if grep -q "<<<<<<< HEAD" backend-new/routes/students.js; then
    echo "❌ Conflict markers لا تزال موجودة! سأحذفها..."
    sed -i '/<<<<<<< HEAD/d' backend-new/routes/students.js
    sed -i '/=======/d' backend-new/routes/students.js
    sed -i '/>>>>>>>/d' backend-new/routes/students.js
else
    echo "✅ لا توجد conflict markers"
fi

# التحقق من Syntax
echo "🔍 فحص Syntax..."
cd backend-new
node -c routes/students.js && echo "✅ Syntax صحيح!" || echo "❌ Syntax به أخطاء!"

# بدء Backend
echo "🚀 بدء Backend..."
pm2 start server.js --name "unitrans-backend"

sleep 10

# فحص الحالة
pm2 status unitrans-backend

# اختبار تسجيل الدخول
echo ""
echo "🧪 اختبار تسجيل الدخول:"
curl -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com","password":"memo123"}' \
  -s | jq

echo ""
echo "✅ تم إصلاح المشكلة!"
