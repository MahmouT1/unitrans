#!/bin/bash

echo "🔍 فحص التناقض: Login يعمل لكن Student غير موجود"
echo "============================================="

cd /var/www/unitrans

echo ""
echo "🔑 1️⃣ اختبار Login:"
echo "================"

LOGIN_RESPONSE=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}')

echo "Login Response:"
echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"

LOGIN_SUCCESS=$(echo "$LOGIN_RESPONSE" | jq -r '.success' 2>/dev/null)
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token' 2>/dev/null)

if [ "$LOGIN_SUCCESS" = "true" ]; then
    echo "✅ Login نجح - المستخدم موجود في النظام"
    echo "🔑 Token: ${TOKEN:0:30}..."
else
    echo "❌ Login فشل - المستخدم غير موجود"
    exit 1
fi

echo ""
echo "👨‍🎓 2️⃣ فحص بيانات الطالب:"
echo "======================"

echo "🔍 محاولة الحصول على بيانات الطالب..."
STUDENT_DATA=$(curl -s -X GET "https://unibus.online/api/students/data?email=test@test.com" \
  -H "Authorization: Bearer $TOKEN")

echo "Student Data Response:"
echo "$STUDENT_DATA" | jq '.' 2>/dev/null || echo "$STUDENT_DATA"

STUDENT_SUCCESS=$(echo "$STUDENT_DATA" | jq -r '.success' 2>/dev/null)

if [ "$STUDENT_SUCCESS" = "true" ]; then
    echo "✅ بيانات الطالب موجودة!"
    echo "📊 البيانات:"
    echo "$STUDENT_DATA" | jq '.student' 2>/dev/null
else
    echo "❌ بيانات الطالب غير موجودة!"
    echo "الخطأ: $(echo "$STUDENT_DATA" | jq -r '.message' 2>/dev/null)"
fi

echo ""
echo "🔍 3️⃣ فحص قاعدة البيانات مباشرة:"
echo "=============================="

echo "🔍 فحص المستخدمين في users collection:"
USERS_RESPONSE=$(curl -s -X GET "https://unibus.online/api/users/list" \
  -H "Content-Type: application/json")

echo "Users Response:"
echo "$USERS_RESPONSE" | jq '.users[] | select(.email == "test@test.com")' 2>/dev/null || echo "لا توجد بيانات"

echo ""
echo "🔍 فحص الطلاب في students collection:"
STUDENTS_RESPONSE=$(curl -s -X GET "https://unibus.online/api/admin/students" \
  -H "Content-Type: application/json")

echo "Students Response:"
echo "$STUDENTS_RESPONSE" | jq '.students[] | select(.email == "test@test.com")' 2>/dev/null || echo "لا توجد بيانات"

echo ""
echo "🔍 4️⃣ فحص API endpoints المختلفة:"
echo "================================"

echo "🔍 اختبار /api/students/profile-simple:"
PROFILE_SIMPLE=$(curl -s -X GET "https://unibus.online/api/students/profile-simple?email=test@test.com" \
  -H "Authorization: Bearer $TOKEN")

echo "Profile Simple Response:"
echo "$PROFILE_SIMPLE" | jq '.' 2>/dev/null || echo "$PROFILE_SIMPLE"

echo ""
echo "🔍 اختبار /api/students/search:"
SEARCH_RESPONSE=$(curl -s -X GET "https://unibus.online/api/students/search?q=test@test.com" \
  -H "Authorization: Bearer $TOKEN")

echo "Search Response:"
echo "$SEARCH_RESPONSE" | jq '.' 2>/dev/null || echo "$SEARCH_RESPONSE"

echo ""
echo "🔍 5️⃣ فحص Backend Logs:"
echo "====================="

echo "🔍 فحص logs للـ backend:"
pm2 logs unitrans-backend --lines 20

echo ""
echo "📊 6️⃣ تحليل النتائج:"
echo "=================="

echo "🔍 ملخص النتائج:"
echo "   🔑 Login: $([ "$LOGIN_SUCCESS" = "true" ] && echo "نجح" || echo "فشل")"
echo "   👨‍🎓 Student Data: $([ "$STUDENT_SUCCESS" = "true" ] && echo "موجود" || echo "غير موجود")"

if [ "$LOGIN_SUCCESS" = "true" ] && [ "$STUDENT_SUCCESS" != "true" ]; then
    echo ""
    echo "🚨 تم اكتشاف التناقض!"
    echo "   ✅ المستخدم موجود في users collection"
    echo "   ❌ الطالب غير موجود في students collection"
    echo ""
    echo "🔧 الحلول المحتملة:"
    echo "   1️⃣ إنشاء رابط بين users و students"
    echo "   2️⃣ إنشاء student record جديد"
    echo "   3️⃣ إصلاح API endpoints"
elif [ "$LOGIN_SUCCESS" = "true" ] && [ "$STUDENT_SUCCESS" = "true" ]; then
    echo ""
    echo "✅ كل شيء يعمل بشكل صحيح!"
    echo "   🔑 Login يعمل"
    echo "   👨‍🎓 Student Data موجود"
    echo "   🎉 لا توجد مشاكل!"
else
    echo ""
    echo "❌ هناك مشاكل في النظام"
    echo "   🔧 يُنصح بمراجعة الأخطاء"
fi

echo ""
echo "🎯 7️⃣ التوصيات:"
echo "=============="

if [ "$LOGIN_SUCCESS" = "true" ] && [ "$STUDENT_SUCCESS" != "true" ]; then
    echo "🔧 يُنصح بتشغيل:"
    echo "   ./fix-student-not-found.sh"
    echo "   أو"
    echo "   إنشاء student record يدوياً"
fi
