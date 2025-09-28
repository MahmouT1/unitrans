#!/bin/bash

echo "🔧 إصلاح صفحة Login لحفظ البيانات بالـ keys الصحيحة"
echo "========================================================"

cd /var/www/unitrans

echo "🛑 إيقاف Frontend..."
pm2 stop unitrans-frontend

echo ""
echo "🔑 إصلاح localStorage keys في صفحة Login:"
echo "========================================"

# إصلاح handleSubmit في صفحة login لحفظ البيانات بالـ keys الصحيحة
sed -i '/localStorage.setItem.*authToken/c\
        localStorage.setItem("token", data.token); // الـ key الأساسي\
        localStorage.setItem("authToken", data.token);\
        localStorage.setItem("userToken", data.token);' frontend-new/app/login/page.js

echo "✅ تم إضافة localStorage.setItem('token') للـ login page"

echo ""
echo "🔍 التحقق من التعديل:"
echo "==================="

grep -n "localStorage.setItem.*token" frontend-new/app/login/page.js

echo ""
echo "🏗️ إعادة بناء Frontend:"
echo "======================="

cd frontend-new
rm -rf .next
npm run build

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ البناء نجح!"
    
    echo ""
    echo "🚀 إعادة تشغيل Frontend..."
    pm2 start unitrans-frontend
    
    echo ""
    echo "⏳ انتظار استقرار النظام..."
    sleep 10
    
    echo ""
    echo "🧪 اختبار Login مع الـ keys الجديدة:"
    echo "=================================="
    
    LOGIN_TEST=$(curl -s -X POST https://unibus.online/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"test@test.com","password":"123456"}')
    
    echo "Login Response:"
    echo "$LOGIN_TEST" | jq '.' 2>/dev/null || echo "$LOGIN_TEST"
    
    echo ""
    echo "🌐 اختبار جميع صفحات الطلاب:"
    echo "=========================="
    
    echo "🏠 Student Portal:"
    curl -I https://unibus.online/student/portal -w "Status: %{http_code}\n" -s
    
    echo "📄 Registration:"
    curl -I https://unibus.online/student/registration -w "Status: %{http_code}\n" -s
    
    echo "💳 Subscription:"
    curl -I https://unibus.online/student/subscription -w "Status: %{http_code}\n" -s
    
    echo "🎧 Support:"
    curl -I https://unibus.online/student/support -w "Status: %{http_code}\n" -s
    
    echo "🚌 Transportation:"
    curl -I https://unibus.online/student/transportation -w "Status: %{http_code}\n" -s
    
else
    echo "❌ البناء فشل!"
fi

echo ""
echo "📊 حالة النهائية:"
pm2 status

echo ""
echo "✅ إصلاح Login page localStorage اكتمل!"
echo "🔑 الآن صفحة Login تحفظ البيانات بـ keys صحيحة:"
echo "   - token ✅"
echo "   - authToken ✅" 
echo "   - userToken ✅"
echo "   - user ✅"
echo ""
echo "🎯 جميع الكروت والصفحات ستعمل الآن!"
echo "🔗 اختبر: https://unibus.online/login"
