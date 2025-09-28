#!/bin/bash

echo "🧪 اختبار شامل لصفحة /login الجديدة"
echo "===================================="

cd /var/www/unitrans

echo "📊 حالة النظام:"
pm2 status

echo ""
echo "🌐 اختبار تحميل صفحة /login:"
echo "============================"

# اختبار تحميل الصفحة
LOGIN_PAGE_RESPONSE=$(curl -s -I https://unibus.online/login -w "\nSTATUS_CODE:%{http_code}")
echo "Response: $LOGIN_PAGE_RESPONSE"

if echo "$LOGIN_PAGE_RESPONSE" | grep -q "STATUS_CODE:200"; then
    echo "✅ صفحة /login تُحمّل بنجاح"
else
    echo "❌ صفحة /login لا تُحمّل"
fi

echo ""
echo "🔄 اختبار redirect من /auth إلى /login:"
echo "======================================"

AUTH_REDIRECT_RESPONSE=$(curl -s -I https://unibus.online/auth -w "\nSTATUS_CODE:%{http_code}")
echo "Response: $AUTH_REDIRECT_RESPONSE"

if echo "$AUTH_REDIRECT_RESPONSE" | grep -q "STATUS_CODE:200"; then
    echo "✅ /auth redirect يعمل"
else
    echo "❌ /auth redirect لا يعمل"
fi

echo ""
echo "🔐 اختبار تسجيل الدخول لجميع الأدوار"
echo "====================================="

# 1. اختبار Admin
echo ""
echo "1️⃣ 👨‍💼 اختبار حساب الإدارة:"
echo "   📧 Email: roo2admin@gmail.com"
echo "   🔑 Password: admin123"
echo "   🎯 المتوقع: توجيه لـ /admin/dashboard"

ADMIN_RESPONSE=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"roo2admin@gmail.com","password":"admin123"}')

echo "   📡 الاستجابة:"
echo "$ADMIN_RESPONSE" | jq '.' 2>/dev/null || echo "$ADMIN_RESPONSE"

if echo "$ADMIN_RESPONSE" | grep -q '"success":true'; then
    echo "   ✅ تسجيل دخول الإدارة: نجح"
    
    # استخراج redirectUrl
    ADMIN_REDIRECT=$(echo "$ADMIN_RESPONSE" | grep -o '"redirectUrl":"[^"]*"' | cut -d'"' -f4)
    echo "   🔄 Redirect URL: $ADMIN_REDIRECT"
    
    # اختبار الصفحة المخصصة
    if [ ! -z "$ADMIN_REDIRECT" ]; then
        ADMIN_PAGE_TEST=$(curl -s -I "https://unibus.online$ADMIN_REDIRECT" -w "\nSTATUS_CODE:%{http_code}")
        ADMIN_PAGE_STATUS=$(echo "$ADMIN_PAGE_TEST" | grep "STATUS_CODE" | cut -d: -f2)
        echo "   🌐 حالة صفحة الإدارة: $ADMIN_PAGE_STATUS"
        
        if [ "$ADMIN_PAGE_STATUS" = "200" ]; then
            echo "   ✅ صفحة الإدارة تعمل"
        else
            echo "   ❌ صفحة الإدارة لا تعمل"
        fi
    fi
else
    echo "   ❌ تسجيل دخول الإدارة: فشل"
fi

# 2. اختبار Supervisor
echo ""
echo "2️⃣ 👨‍🏫 اختبار حساب المشرف:"
echo "   📧 Email: ahmedazab@gmail.com"
echo "   🔑 Password: supervisor123"
echo "   🎯 المتوقع: توجيه لـ /admin/supervisor-dashboard"

SUPERVISOR_RESPONSE=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}')

echo "   📡 الاستجابة:"
echo "$SUPERVISOR_RESPONSE" | jq '.' 2>/dev/null || echo "$SUPERVISOR_RESPONSE"

if echo "$SUPERVISOR_RESPONSE" | grep -q '"success":true'; then
    echo "   ✅ تسجيل دخول المشرف: نجح"
    
    # استخراج redirectUrl
    SUPERVISOR_REDIRECT=$(echo "$SUPERVISOR_RESPONSE" | grep -o '"redirectUrl":"[^"]*"' | cut -d'"' -f4)
    echo "   🔄 Redirect URL: $SUPERVISOR_REDIRECT"
    
    # اختبار الصفحة المخصصة
    if [ ! -z "$SUPERVISOR_REDIRECT" ]; then
        SUPERVISOR_PAGE_TEST=$(curl -s -I "https://unibus.online$SUPERVISOR_REDIRECT" -w "\nSTATUS_CODE:%{http_code}")
        SUPERVISOR_PAGE_STATUS=$(echo "$SUPERVISOR_PAGE_TEST" | grep "STATUS_CODE" | cut -d: -f2)
        echo "   🌐 حالة صفحة المشرف: $SUPERVISOR_PAGE_STATUS"
        
        if [ "$SUPERVISOR_PAGE_STATUS" = "200" ]; then
            echo "   ✅ صفحة المشرف تعمل"
        else
            echo "   ❌ صفحة المشرف لا تعمل"
        fi
    fi
else
    echo "   ❌ تسجيل دخول المشرف: فشل"
fi

# 3. اختبار Student
echo ""
echo "3️⃣ 👨‍🎓 اختبار حساب الطالب:"
echo "   📧 Email: test@test.com"
echo "   🔑 Password: 123456"
echo "   🎯 المتوقع: توجيه لـ /student/portal"

STUDENT_RESPONSE=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}')

echo "   📡 الاستجابة:"
echo "$STUDENT_RESPONSE" | jq '.' 2>/dev/null || echo "$STUDENT_RESPONSE"

if echo "$STUDENT_RESPONSE" | grep -q '"success":true'; then
    echo "   ✅ تسجيل دخول الطالب: نجح"
    
    # استخراج redirectUrl
    STUDENT_REDIRECT=$(echo "$STUDENT_RESPONSE" | grep -o '"redirectUrl":"[^"]*"' | cut -d'"' -f4)
    echo "   🔄 Redirect URL: $STUDENT_REDIRECT"
    
    # اختبار الصفحة المخصصة
    if [ ! -z "$STUDENT_REDIRECT" ]; then
        STUDENT_PAGE_TEST=$(curl -s -I "https://unibus.online$STUDENT_REDIRECT" -w "\nSTATUS_CODE:%{http_code}")
        STUDENT_PAGE_STATUS=$(echo "$STUDENT_PAGE_TEST" | grep "STATUS_CODE" | cut -d: -f2)
        echo "   🌐 حالة صفحة الطالب: $STUDENT_PAGE_STATUS"
        
        if [ "$STUDENT_PAGE_STATUS" = "200" ]; then
            echo "   ✅ صفحة الطالب تعمل"
        else
            echo "   ❌ صفحة الطالب لا تعمل"
        fi
    fi
else
    echo "   ❌ تسجيل دخول الطالب: فشل"
fi

# 4. اختبار Registration
echo ""
echo "4️⃣ 📝 اختبار التسجيل الجديد:"
NEW_EMAIL="testuser$(date +%s)@test.com"
echo "   📧 Email: $NEW_EMAIL"
echo "   🔑 Password: 123456"
echo "   👤 Name: Test User New"

REGISTER_RESPONSE=$(curl -s -X POST https://unibus.online/api/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$NEW_EMAIL\",\"password\":\"123456\",\"fullName\":\"Test User New\"}")

echo "   📡 الاستجابة:"
echo "$REGISTER_RESPONSE" | jq '.' 2>/dev/null || echo "$REGISTER_RESPONSE"

if echo "$REGISTER_RESPONSE" | grep -q '"success":true'; then
    echo "   ✅ التسجيل الجديد: نجح"
else
    echo "   ❌ التسجيل الجديد: فشل"
fi

# 5. اختبار حساب خاطئ
echo ""
echo "5️⃣ ❌ اختبار حساب خاطئ:"
echo "   📧 Email: wrong@test.com"
echo "   🔑 Password: wrongpass"
echo "   🎯 المتوقع: رسالة خطأ"

WRONG_RESPONSE=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"wrong@test.com","password":"wrongpass"}')

echo "   📡 الاستجابة:"
echo "$WRONG_RESPONSE" | jq '.' 2>/dev/null || echo "$WRONG_RESPONSE"

if echo "$WRONG_RESPONSE" | grep -q '"success":false'; then
    echo "   ✅ التعامل مع الخطأ: صحيح"
else
    echo "   ❌ التعامل مع الخطأ: غير صحيح"
fi

echo ""
echo "📋 ملخص اختبار صفحة /login:"
echo "==========================="

# تلخيص النتائج
LOGIN_PAGE_OK=$(echo "$LOGIN_PAGE_RESPONSE" | grep -q "STATUS_CODE:200" && echo "✅ تعمل" || echo "❌ لا تعمل")
AUTH_REDIRECT_OK=$(echo "$AUTH_REDIRECT_RESPONSE" | grep -q "STATUS_CODE:200" && echo "✅ يعمل" || echo "❌ لا يعمل")
ADMIN_LOGIN_OK=$(echo "$ADMIN_RESPONSE" | grep -q '"success":true' && echo "✅ نجح" || echo "❌ فشل")
SUPERVISOR_LOGIN_OK=$(echo "$SUPERVISOR_RESPONSE" | grep -q '"success":true' && echo "✅ نجح" || echo "❌ فشل")
STUDENT_LOGIN_OK=$(echo "$STUDENT_RESPONSE" | grep -q '"success":true' && echo "✅ نجح" || echo "❌ فشل")
REGISTER_OK=$(echo "$REGISTER_RESPONSE" | grep -q '"success":true' && echo "✅ نجح" || echo "❌ فشل")
ERROR_HANDLING_OK=$(echo "$WRONG_RESPONSE" | grep -q '"success":false' && echo "✅ صحيح" || echo "❌ غير صحيح")

echo "🌐 تحميل صفحة /login:     $LOGIN_PAGE_OK"
echo "🔄 redirect من /auth:     $AUTH_REDIRECT_OK"
echo "👨‍💼 Admin Login:           $ADMIN_LOGIN_OK"
echo "👨‍🏫 Supervisor Login:     $SUPERVISOR_LOGIN_OK"
echo "👨‍🎓 Student Login:         $STUDENT_LOGIN_OK"
echo "📝 New Registration:      $REGISTER_OK"
echo "❌ Error Handling:        $ERROR_HANDLING_OK"

echo ""
echo "🎯 URLs للاختبار في المتصفح:"
echo "=========================="
echo "🔗 الصفحة الجديدة:  https://unibus.online/login"
echo "🔗 Redirect test:   https://unibus.online/auth (يجب أن يوجه لـ /login)"

echo ""
echo "🔐 الحسابات الجاهزة:"
echo "=================="
echo "👨‍💼 Admin:      roo2admin@gmail.com / admin123"
echo "👨‍🏫 Supervisor: ahmedazab@gmail.com / supervisor123"
echo "👨‍🎓 Student:    test@test.com / 123456"

echo ""
echo "✅ اختبار صفحة /login اكتمل!"
echo "🚀 جرب الآن في المتصفح!"
