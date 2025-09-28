#!/bin/bash

echo "🔧 إصلاح مصادقة صفحات الطلاب"
echo "============================="

cd /var/www/unitrans

echo "🛑 إيقاف Frontend..."
pm2 stop unitrans-frontend

echo ""
echo "🔧 إصلاح توجيه Auth في جميع صفحات الطلاب:"
echo "==========================================="

# إصلاح student/portal/page.js
echo "1️⃣ إصلاح student/portal/page.js..."
sed -i "s|router.push('/auth');|router.push('/login');|g" frontend-new/app/student/portal/page.js

# إصلاح student/subscription/page.js
echo "2️⃣ إصلاح student/subscription/page.js..."
sed -i "s|router.push('/auth');|router.push('/login');|g" frontend-new/app/student/subscription/page.js

# إصلاح student/support/page.js
echo "3️⃣ إصلاح student/support/page.js..."
sed -i "s|router.push('/auth');|router.push('/login');|g" frontend-new/app/student/support/page.js

# إصلاح student/transportation/page.js
echo "4️⃣ إصلاح student/transportation/page.js..."
sed -i "s|router.push('/auth');|router.push('/login');|g" frontend-new/app/student/transportation/page.js

# إصلاح student/registration/page.js
echo "5️⃣ إصلاح student/registration/page.js..."
sed -i "s|router.push('/auth');|router.push('/login');|g" frontend-new/app/student/registration/page.js

echo ""
echo "🔍 التحقق من الإصلاحات:"
echo "===================="

echo "✅ البحث عن /auth في صفحات الطلاب:"
grep -r "router.push('/auth')" frontend-new/app/student/ || echo "✅ لا توجد مراجع لـ /auth"

echo ""
echo "✅ البحث عن /login في صفحات الطلاب:"
grep -r "router.push('/login')" frontend-new/app/student/ || echo "❌ لا توجد مراجع لـ /login"

echo ""
echo "🔧 إصلاح إضافي - البحث عن جميع مراجع /auth:"
echo "============================================="

# البحث في جميع الملفات عن مراجع /auth وإصلاحها
find frontend-new -name "*.js" -type f -exec grep -l "'/auth'" {} \; | while read file; do
    echo "🔧 إصلاح $file..."
    sed -i "s|'/auth'|'/login'|g" "$file"
done

echo ""
echo "🔧 إصلاح خاص للصفحات التي تستخدم window.location.href:"
echo "=================================================="

# إصلاح any مراجع أخرى
find frontend-new -name "*.js" -type f -exec grep -l "window.location.href.*auth" {} \; | while read file; do
    echo "🔧 إصلاح window.location في $file..."
    sed -i "s|window.location.href = '/auth'|window.location.href = '/login'|g" "$file"
done

echo ""
echo "🏗️ إعادة بناء Frontend مع الإصلاحات:"
echo "==================================="

cd frontend-new

# حذف cache
rm -rf .next
rm -rf node_modules/.cache

# بناء جديد
npm run build

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ البناء نجح!"
    
    echo ""
    echo "🚀 إعادة تشغيل Frontend..."
    pm2 start unitrans-frontend
    
    echo ""
    echo "⏳ انتظار استقرار النظام..."
    sleep 8
    
    echo ""
    echo "🧪 اختبار student login كامل:"
    echo "=============================="
    
    echo "1️⃣ اختبار تسجيل دخول الطالب:"
    STUDENT_LOGIN=$(curl -s -X POST https://unibus.online/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"test@test.com","password":"123456"}')
    
    echo "Response: $STUDENT_LOGIN"
    
    if echo "$STUDENT_LOGIN" | grep -q '"success":true'; then
        echo "✅ تسجيل دخول الطالب: نجح"
        
        # اختبار الوصول لصفحة student portal
        echo ""
        echo "2️⃣ اختبار صفحة student portal:"
        curl -I https://unibus.online/student/portal -w "\n📊 Status: %{http_code}\n"
        
    else
        echo "❌ تسجيل دخول الطالب: فشل"
    fi
    
else
    echo "❌ البناء فشل!"
fi

echo ""
echo "📊 حالة النهائية:"
pm2 status

echo ""
echo "✅ إصلاح صفحات الطلاب اكتمل!"
echo "🔗 جرب الآن: https://unibus.online/login"
echo "   📧 test@test.com / 123456"
echo "   🎯 يجب أن يدخل لـ /student/portal بدون مشاكل"
