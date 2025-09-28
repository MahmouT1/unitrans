#!/bin/bash

echo "🧪 اختبار شامل لجميع الحسابات والأدوار"
echo "======================================="

cd /var/www/unitrans

echo "📊 حالة النظام:"
pm2 status

echo ""
echo "🔐 اختبار تسجيل الدخول لجميع الأدوار"
echo "====================================="

# 1. اختبار Admin
echo ""
echo "1️⃣ اختبار حساب الإدارة (Admin):"
echo "   📧 Email: roo2admin@gmail.com"
echo "   🔑 Password: admin123"
echo "   🎯 المتوقع: admin dashboard"

ADMIN_RESPONSE=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"roo2admin@gmail.com","password":"admin123"}' \
  -w "\nSTATUS_CODE:%{http_code}")

echo "   📡 الاستجابة: $ADMIN_RESPONSE"

if echo "$ADMIN_RESPONSE" | grep -q '"success":true'; then
    echo "   ✅ تسجيل الدخول: نجح"
    
    # استخراج token للاختبار
    ADMIN_TOKEN=$(echo "$ADMIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "   🎫 Token: ${ADMIN_TOKEN:0:30}..."
    
    # استخراج redirectUrl
    ADMIN_REDIRECT=$(echo "$ADMIN_RESPONSE" | grep -o '"redirectUrl":"[^"]*"' | cut -d'"' -f4)
    echo "   🔄 Redirect URL: $ADMIN_REDIRECT"
    
    # اختبار الوصول للصفحة المطلوبة
    echo "   🌐 اختبار الوصول للصفحة المخصصة..."
    ADMIN_PAGE_TEST=$(curl -s -I "https://unibus.online$ADMIN_REDIRECT" -w "\nSTATUS_CODE:%{http_code}")
    echo "   📊 حالة الصفحة: $(echo "$ADMIN_PAGE_TEST" | grep "STATUS_CODE" | cut -d: -f2)"
    
else
    echo "   ❌ تسجيل الدخول: فشل"
fi

# 2. اختبار Supervisor
echo ""
echo "2️⃣ اختبار حساب المشرف (Supervisor):"
echo "   📧 Email: ahmedazab@gmail.com" 
echo "   🔑 Password: supervisor123"
echo "   🎯 المتوقع: supervisor dashboard"

SUPERVISOR_RESPONSE=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  -w "\nSTATUS_CODE:%{http_code}")

echo "   📡 الاستجابة: $SUPERVISOR_RESPONSE"

if echo "$SUPERVISOR_RESPONSE" | grep -q '"success":true'; then
    echo "   ✅ تسجيل الدخول: نجح"
    
    # استخراج redirectUrl
    SUPERVISOR_REDIRECT=$(echo "$SUPERVISOR_RESPONSE" | grep -o '"redirectUrl":"[^"]*"' | cut -d'"' -f4)
    echo "   🔄 Redirect URL: $SUPERVISOR_REDIRECT"
    
    # اختبار الوصول للصفحة المطلوبة
    echo "   🌐 اختبار الوصول للصفحة المخصصة..."
    SUPERVISOR_PAGE_TEST=$(curl -s -I "https://unibus.online$SUPERVISOR_REDIRECT" -w "\nSTATUS_CODE:%{http_code}")
    echo "   📊 حالة الصفحة: $(echo "$SUPERVISOR_PAGE_TEST" | grep "STATUS_CODE" | cut -d: -f2)"
    
else
    echo "   ❌ تسجيل الدخول: فشل"
fi

# 3. اختبار Student
echo ""
echo "3️⃣ اختبار حساب الطالب (Student):"
echo "   📧 Email: test@test.com"
echo "   🔑 Password: 123456"
echo "   🎯 المتوقع: student portal"

STUDENT_RESPONSE=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\nSTATUS_CODE:%{http_code}")

echo "   📡 الاستجابة: $STUDENT_RESPONSE"

if echo "$STUDENT_RESPONSE" | grep -q '"success":true'; then
    echo "   ✅ تسجيل الدخول: نجح"
    
    # استخراج redirectUrl
    STUDENT_REDIRECT=$(echo "$STUDENT_RESPONSE" | grep -o '"redirectUrl":"[^"]*"' | cut -d'"' -f4)
    echo "   🔄 Redirect URL: $STUDENT_REDIRECT"
    
    # اختبار الوصول للصفحة المطلوبة
    echo "   🌐 اختبار الوصول للصفحة المخصصة..."
    STUDENT_PAGE_TEST=$(curl -s -I "https://unibus.online$STUDENT_REDIRECT" -w "\nSTATUS_CODE:%{http_code}")
    echo "   📊 حالة الصفحة: $(echo "$STUDENT_PAGE_TEST" | grep "STATUS_CODE" | cut -d: -f2)"
    
else
    echo "   ❌ تسجيل الدخول: فشل"
fi

# 4. اختبار حساب غير موجود
echo ""
echo "4️⃣ اختبار حساب غير موجود:"
echo "   📧 Email: nonexistent@test.com"
echo "   🔑 Password: wrongpass"
echo "   🎯 المتوقع: خطأ"

WRONG_RESPONSE=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"nonexistent@test.com","password":"wrongpass"}' \
  -w "\nSTATUS_CODE:%{http_code}")

echo "   📡 الاستجابة: $WRONG_RESPONSE"

if echo "$WRONG_RESPONSE" | grep -q '"success":false'; then
    echo "   ✅ التعامل مع الخطأ: صحيح"
else
    echo "   ❌ التعامل مع الخطأ: غير صحيح"
fi

# 5. اختبار التسجيل الجديد
echo ""
echo "5️⃣ اختبار التسجيل الجديد:"
echo "   📧 Email: newuser$(date +%s)@test.com"
echo "   🔑 Password: 123456"
echo "   👤 Name: New Test User"

NEW_EMAIL="newuser$(date +%s)@test.com"
REGISTER_RESPONSE=$(curl -s -X POST https://unibus.online/api/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$NEW_EMAIL\",\"password\":\"123456\",\"fullName\":\"New Test User\"}" \
  -w "\nSTATUS_CODE:%{http_code}")

echo "   📡 الاستجابة: $REGISTER_RESPONSE"

if echo "$REGISTER_RESPONSE" | grep -q '"success":true'; then
    echo "   ✅ التسجيل الجديد: نجح"
else
    echo "   ❌ التسجيل الجديد: فشل"
fi

echo ""
echo "📋 ملخص النتائج:"
echo "================"

# تلخيص النتائج
ADMIN_SUCCESS=$(echo "$ADMIN_RESPONSE" | grep -q '"success":true' && echo "✅ نجح" || echo "❌ فشل")
SUPERVISOR_SUCCESS=$(echo "$SUPERVISOR_RESPONSE" | grep -q '"success":true' && echo "✅ نجح" || echo "❌ فشل")
STUDENT_SUCCESS=$(echo "$STUDENT_RESPONSE" | grep -q '"success":true' && echo "✅ نجح" || echo "❌ فشل")
WRONG_SUCCESS=$(echo "$WRONG_RESPONSE" | grep -q '"success":false' && echo "✅ صحيح" || echo "❌ غير صحيح")
REGISTER_SUCCESS=$(echo "$REGISTER_RESPONSE" | grep -q '"success":true' && echo "✅ نجح" || echo "❌ فشل")

echo "🔹 Admin Login:       $ADMIN_SUCCESS"
echo "🔹 Supervisor Login:  $SUPERVISOR_SUCCESS"  
echo "🔹 Student Login:     $STUDENT_SUCCESS"
echo "🔹 Wrong Credentials: $WRONG_SUCCESS"
echo "🔹 New Registration:  $REGISTER_SUCCESS"

echo ""
echo "🎯 الصفحات المخصصة لكل دور:"
echo "=========================="
echo "👨‍💼 Admin →       /admin/dashboard"
echo "👨‍🏫 Supervisor →  /admin/supervisor-dashboard" 
echo "👨‍🎓 Student →     /student/portal"

echo ""
echo "🔗 جرب الآن في المتصفح:"
echo "======================="
echo "https://unibus.online/login"

echo ""
echo "✅ اختبار السيرفر اكتمل!"
