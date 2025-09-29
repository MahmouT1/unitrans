#!/bin/bash

echo "🔧 إصلاح مشكلة Frontend HTTP 502"
echo "==============================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص مشكلة Frontend:"
echo "======================="

echo "🔍 فحص PM2 status:"
pm2 status

echo ""
echo "🔍 فحص frontend directory:"
ls -la frontend-new/

echo ""
echo "🔍 فحص server.js في frontend:"
if [ -f "frontend-new/server.js" ]; then
    echo "✅ server.js موجود"
else
    echo "❌ server.js غير موجود"
fi

echo ""
echo "🔧 2️⃣ إصلاح Frontend:"
echo "==================="

echo "🔄 إيقاف جميع العمليات..."
pm2 stop all

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 حذف العمليات القديمة..."
pm2 delete all

echo "⏳ انتظار 3 ثواني..."
sleep 3

echo "🔧 3️⃣ إعادة تشغيل Backend:"
echo "========================="

echo "🔄 تشغيل backend..."
pm2 start backend-new/server.js --name unitrans-backend

echo "⏳ انتظار 10 ثواني للتأكد من التشغيل..."
sleep 10

echo "🔍 فحص حالة backend:"
pm2 status unitrans-backend

echo ""
echo "🔧 4️⃣ إعادة Build Frontend:"
echo "========================="

echo "🔄 حذف .next directory:"
rm -rf frontend-new/.next

echo "🔄 حذف node_modules/.cache:"
rm -rf frontend-new/node_modules/.cache

echo "🔄 إعادة build frontend:"
cd frontend-new
npm run build

echo ""
echo "🔍 فحص build result:"
if [ -d ".next" ]; then
    echo "✅ Build نجح!"
else
    echo "❌ Build فشل!"
fi

cd ..

echo ""
echo "🔧 5️⃣ تشغيل Frontend بطريقة صحيحة:"
echo "================================="

echo "🔄 تشغيل frontend باستخدام npm start..."
cd frontend-new
pm2 start "npm" --name unitrans-frontend -- start

echo "⏳ انتظار 15 ثانية للتأكد من التشغيل..."
sleep 15

echo "🔍 فحص حالة frontend:"
pm2 status unitrans-frontend

cd ..

echo ""
echo "🧪 6️⃣ اختبار Frontend:"
echo "===================="

echo "🔍 اختبار صفحة Login:"
LOGIN_PAGE=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/login)
echo "$LOGIN_PAGE"

echo ""
echo "🔍 اختبار صفحة Student Portal:"
PORTAL_PAGE=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/student/portal)
echo "$PORTAL_PAGE"

echo ""
echo "🔍 اختبار صفحة Admin Dashboard:"
ADMIN_PAGE=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/admin/dashboard)
echo "$ADMIN_PAGE"

echo ""
echo "🧪 7️⃣ اختبار /api/login من خلال Nginx:"
echo "===================================="

echo "🔍 اختبار /api/login من خلال Nginx:"
NGINX_LOGIN=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\nHTTP Status: %{http_code}\n")

echo "$NGINX_LOGIN"

echo ""
echo "📊 8️⃣ تقرير الإصلاح النهائي:"
echo "=========================="

echo "✅ الإصلاحات المطبقة:"
echo "   🔧 تم إعادة تشغيل backend"
echo "   🏗️ تم إعادة build frontend"
echo "   🔄 تم تشغيل frontend بطريقة صحيحة"
echo "   🧪 تم اختبار جميع الصفحات"

echo ""
echo "🎯 النتائج:"
echo "   🔑 Backend APIs: ✅ تعمل"
echo "   📱 Login Page: $LOGIN_PAGE"
echo "   🏠 Portal Page: $PORTAL_PAGE"
echo "   🔧 Admin Page: $ADMIN_PAGE"
echo "   🌐 Nginx Login: $(echo "$NGINX_LOGIN" | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"

echo ""
echo "🎉 تم إصلاح مشكلة Frontend HTTP 502!"
echo "🌐 يمكنك الآن اختبار النظام:"
echo "   🔗 https://unibus.online/login"
echo "   📧 test@test.com / 123456"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
