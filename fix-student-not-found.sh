#!/bin/bash

echo "🔧 إصلاح مشكلة 'Student not found'"
echo "================================="

cd /var/www/unitrans

echo ""
echo "📊 1️⃣ فحص قاعدة البيانات:"
echo "=================="

# فحص الطلاب الموجودين
echo "🔍 الطلاب الموجودين في قاعدة البيانات:"
curl -s -X GET "https://unibus.online/api/admin/students" \
  -H "Content-Type: application/json" | jq '.students[] | {email: .email, fullName: .fullName}' 2>/dev/null || echo "لا توجد بيانات"

echo ""
echo "🔍 المستخدمين الموجودين:"
curl -s -X GET "https://unibus.online/api/users/list" \
  -H "Content-Type: application/json" | jq '.users[] | {email: .email, role: .role}' 2>/dev/null || echo "لا توجد بيانات"

echo ""
echo "📝 2️⃣ إنشاء طالب جديد للاختبار:"
echo "============================="

# تسجيل دخول كـ admin أولاً
echo "🔑 تسجيل دخول كـ admin..."
ADMIN_LOGIN=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@admin.com","password":"123456"}')

echo "Admin Login Response:"
echo "$ADMIN_LOGIN" | jq '.' 2>/dev/null || echo "$ADMIN_LOGIN"

ADMIN_TOKEN=$(echo "$ADMIN_LOGIN" | jq -r '.token' 2>/dev/null)

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "❌ فشل في تسجيل دخول admin!"
    echo "🔧 محاولة إنشاء admin جديد..."
    
    # إنشاء admin جديد
    ADMIN_CREATE=$(curl -s -X POST https://unibus.online/api/register \
      -H "Content-Type: application/json" \
      -d '{"email":"admin@admin.com","password":"123456","fullName":"System Admin","role":"admin"}')
    
    echo "Admin Create Response:"
    echo "$ADMIN_CREATE" | jq '.' 2>/dev/null || echo "$ADMIN_CREATE"
    
    # محاولة تسجيل دخول مرة أخرى
    ADMIN_LOGIN=$(curl -s -X POST https://unibus.online/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"admin@admin.com","password":"123456"}')
    
    ADMIN_TOKEN=$(echo "$ADMIN_LOGIN" | jq -r '.token' 2>/dev/null)
fi

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "❌ لا يمكن الحصول على admin token!"
    echo "🔧 محاولة إنشاء طالب مباشرة..."
    
    # إنشاء طالب مباشرة
    STUDENT_CREATE=$(curl -s -X POST https://unibus.online/api/register \
      -H "Content-Type: application/json" \
      -d '{"email":"test@test.com","password":"123456","fullName":"Test Student","role":"student"}')
    
    echo "Student Create Response:"
    echo "$STUDENT_CREATE" | jq '.' 2>/dev/null || echo "$STUDENT_CREATE"
    
    STUDENT_SUCCESS=$(echo "$STUDENT_CREATE" | jq -r '.success' 2>/dev/null)
    
    if [ "$STUDENT_SUCCESS" = "true" ]; then
        echo "✅ تم إنشاء الطالب بنجاح!"
    else
        echo "❌ فشل في إنشاء الطالب"
        echo "الخطأ: $(echo "$STUDENT_CREATE" | jq -r '.message' 2>/dev/null)"
    fi
else
    echo "✅ تم الحصول على admin token: ${ADMIN_TOKEN:0:20}..."
    
    echo ""
    echo "👨‍🎓 إنشاء طالب جديد عبر admin:"
    echo "============================="
    
    # إنشاء طالب جديد
    NEW_STUDENT_DATA='{
      "email": "test@test.com",
      "fullName": "Test Student - Server Test",
      "phoneNumber": "01025713978",
      "college": "كلية الحاسوب والمعلومات",
      "grade": "third-year",
      "major": "نظم المعلومات",
      "address": {
        "streetAddress": "شارع الجامعة",
        "buildingNumber": "123",
        "fullAddress": "السويس، مصر - اختبار سيرفر"
      },
      "role": "student"
    }'
    
    echo "📤 بيانات الطالب الجديد:"
    echo "$NEW_STUDENT_DATA" | jq '.'
    
    STUDENT_CREATE=$(curl -s -X POST https://unibus.online/api/admin/students \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -d "$NEW_STUDENT_DATA")
    
    echo ""
    echo "📡 استجابة إنشاء الطالب:"
    echo "$STUDENT_CREATE" | jq '.' 2>/dev/null || echo "$STUDENT_CREATE"
fi

echo ""
echo "🧪 3️⃣ اختبار Registration مرة أخرى:"
echo "=================================="

# تسجيل دخول كـ student
echo "🔑 تسجيل دخول كـ student..."
STUDENT_LOGIN=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}')

echo "Student Login Response:"
echo "$STUDENT_LOGIN" | jq '.' 2>/dev/null || echo "$STUDENT_LOGIN"

STUDENT_TOKEN=$(echo "$STUDENT_LOGIN" | jq -r '.token' 2>/dev/null)

if [ "$STUDENT_TOKEN" = "null" ] || [ -z "$STUDENT_TOKEN" ]; then
    echo "❌ فشل في تسجيل دخول الطالب!"
    exit 1
fi

echo "✅ تم الحصول على student token: ${STUDENT_TOKEN:0:20}..."

echo ""
echo "📝 اختبار تحديث بيانات الطالب:"
echo "============================="

STUDENT_UPDATE_DATA='{
  "fullName": "محمود طارق - اختبار سيرفر مُحدث",
  "phoneNumber": "01025713978",
  "email": "test@test.com",
  "college": "كلية الحاسوب والمعلومات",
  "grade": "third-year",
  "major": "نظم المعلومات",
  "address": {
    "streetAddress": "شارع الجامعة",
    "buildingNumber": "123",
    "fullAddress": "السويس، مصر - اختبار سيرفر مُحدث"
  },
  "profilePhoto": null
}'

echo "📤 إرسال بيانات الطالب المُحدثة:"
echo "$STUDENT_UPDATE_DATA" | jq '.'

UPDATE_RESPONSE=$(curl -s -X PUT https://unibus.online/api/students/data \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -d "$STUDENT_UPDATE_DATA")

echo ""
echo "📡 استجابة تحديث البيانات:"
echo "$UPDATE_RESPONSE" | jq '.' 2>/dev/null || echo "$UPDATE_RESPONSE"

UPDATE_SUCCESS=$(echo "$UPDATE_RESPONSE" | jq -r '.success' 2>/dev/null)

if [ "$UPDATE_SUCCESS" = "true" ]; then
    echo "✅ تم تحديث بيانات الطالب بنجاح!"
    
    echo ""
    echo "📱 اختبار إنشاء QR Code:"
    echo "======================="
    
    QR_RESPONSE=$(curl -s -X POST https://unibus.online/api/students/generate-qr \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $STUDENT_TOKEN" \
      -d '{"email":"test@test.com"}')
    
    echo "📱 استجابة QR Code:"
    echo "$QR_RESPONSE" | jq '.' 2>/dev/null || echo "$QR_RESPONSE"
    
    QR_SUCCESS=$(echo "$QR_RESPONSE" | jq -r '.success' 2>/dev/null)
    
    if [ "$QR_SUCCESS" = "true" ]; then
        echo "🎉 تم إنشاء QR Code بنجاح!"
        echo "✅ Registration يعمل بشكل كامل!"
    else
        echo "❌ فشل في إنشاء QR Code"
        echo "الخطأ: $(echo "$QR_RESPONSE" | jq -r '.message' 2>/dev/null)"
    fi
else
    echo "❌ فشل في تحديث بيانات الطالب!"
    echo "الخطأ: $(echo "$UPDATE_RESPONSE" | jq -r '.message' 2>/dev/null)"
fi

echo ""
echo "📊 4️⃣ تقرير الإصلاح النهائي:"
echo "========================="

if [ "$UPDATE_SUCCESS" = "true" ] && [ "$QR_SUCCESS" = "true" ]; then
    echo "🎉 تم إصلاح جميع المشاكل!"
    echo "✅ Registration يعمل بشكل كامل!"
    echo "🌐 يمكنك الآن اختبار Registration في المتصفح:"
    echo "   🔗 https://unibus.online/student/registration"
    echo "   📧 Email: test@test.com"
    echo "   🔐 Password: 123456"
else
    echo "⚠️  لا تزال هناك مشاكل"
    echo "🔧 يُنصح بمراجعة الأخطاء"
fi
