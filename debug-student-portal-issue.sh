#!/bin/bash

echo "🔍 تشخيص مشكلة حساب الطالب"
echo "=========================="

cd /var/www/unitrans

echo "🧪 اختبار تفصيلي لحساب الطالب:"
echo "============================"

echo "1️⃣ اختبار student login:"
STUDENT_RESPONSE=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}')

echo "📡 Student login response:"
echo "$STUDENT_RESPONSE" | jq '.' 2>/dev/null || echo "$STUDENT_RESPONSE"

# استخراج البيانات
STUDENT_TOKEN=$(echo "$STUDENT_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
STUDENT_REDIRECT=$(echo "$STUDENT_RESPONSE" | grep -o '"redirectUrl":"[^"]*"' | cut -d'"' -f4)

echo ""
echo "📊 بيانات الطالب:"
echo "==============="
echo "🎫 Token: ${STUDENT_TOKEN:0:50}..."
echo "🔄 Redirect URL: $STUDENT_REDIRECT"

echo ""
echo "2️⃣ اختبار الوصول لصفحة student portal:"
curl -I https://unibus.online/student/portal -w "\n📊 Portal Status: %{http_code}\n"

echo ""
echo "3️⃣ فحص محتوى صفحة student portal:"
echo "==============================="

echo "🔍 البحث عن مراجع /auth في student portal:"
grep -n "/auth" frontend-new/app/student/portal/page.js || echo "✅ لا توجد مراجع لـ /auth"

echo ""
echo "🔍 البحث عن مراجع /login في student portal:"
grep -n "/login" frontend-new/app/student/portal/page.js || echo "❌ لا توجد مراجع لـ /login"

echo ""
echo "4️⃣ فحص آلية المصادقة في student portal:"
echo "======================================="

echo "📄 آلية التحقق من المصادقة (أول 30 سطر):"
head -30 frontend-new/app/student/portal/page.js

echo ""
echo "5️⃣ اختبار student portal API dependency:"
echo "======================================="

echo "🧪 اختبار /api/students/profile-simple:"
curl -s "https://unibus.online/api/students/profile-simple?email=test@test.com" \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -w "\n📊 Profile API Status: %{http_code}\n"

echo ""
echo "6️⃣ Frontend logs (آخر 15 سطر):"
echo "=============================="
pm2 logs unitrans-frontend --lines 15

echo ""
echo "💡 تحليل المشكلة:"
echo "================"

if echo "$STUDENT_RESPONSE" | grep -q '"success":true'; then
    echo "✅ Student login يعمل"
    if [ "$STUDENT_REDIRECT" = "/student/portal" ]; then
        echo "✅ Redirect URL صحيح"
        echo "🔍 المشكلة محتملة في:"
        echo "   - صفحة /student/portal تتحقق من المصادقة وتفشل"
        echo "   - localStorage data مفقود أو غير صحيح"
        echo "   - API dependency فاشل في /student/portal"
    else
        echo "❌ Redirect URL غير صحيح: $STUDENT_REDIRECT"
    fi
else
    echo "❌ Student login فاشل"
fi

echo ""
echo "🔧 الحل المقترح:"
echo "==============="
echo "1. تحديث student portal للتعامل مع token الجديد"
echo "2. إصلاح localStorage keys"
echo "3. تحديث API calls في student portal"

echo ""
echo "✅ تشخيص student portal اكتمل!"
