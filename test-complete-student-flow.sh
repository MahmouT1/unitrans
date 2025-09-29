#!/bin/bash

echo "🧪 اختبار التدفق الكامل لتسجيل الطالب و QR Code"
echo "============================================="

cd /var/www/unitrans

echo ""
echo "📊 1️⃣ فحص حالة النظام:"
echo "==================="

echo "🔍 PM2 Status:"
pm2 status

echo ""
echo "🌐 فحص صفحة Registration:"
REG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/student/registration)
echo "Registration Page Status: $REG_STATUS"

echo ""
echo "🌐 فحص صفحة Student Portal:"
PORTAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/student/portal)
echo "Student Portal Status: $PORTAL_STATUS"

echo ""
echo "🔑 2️⃣ تسجيل دخول الطالب:"
echo "======================"

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
echo "📝 3️⃣ اختبار تسجيل بيانات الطالب:"
echo "==============================="

# بيانات الطالب للتسجيل
STUDENT_DATA='{
  "fullName": "محمود طارق - اختبار سيرفر",
  "phoneNumber": "01025713978",
  "email": "test@test.com",
  "college": "كلية الحاسوب والمعلومات",
  "grade": "third-year",
  "major": "نظم المعلومات",
  "address": "السويس، مصر - اختبار سيرفر"
}'

echo "📤 إرسال بيانات الطالب:"
echo "$STUDENT_DATA" | jq '.'

REGISTRATION_RESPONSE=$(curl -s -X PUT https://unibus.online/api/students/data \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -d "$STUDENT_DATA")

echo ""
echo "📡 استجابة تسجيل البيانات:"
echo "$REGISTRATION_RESPONSE" | jq '.' 2>/dev/null || echo "$REGISTRATION_RESPONSE"

REGISTRATION_SUCCESS=$(echo "$REGISTRATION_RESPONSE" | jq -r '.success' 2>/dev/null)

if [ "$REGISTRATION_SUCCESS" = "true" ]; then
    echo "✅ تم تسجيل بيانات الطالب بنجاح!"
else
    echo "❌ فشل في تسجيل بيانات الطالب!"
    echo "الخطأ: $(echo "$REGISTRATION_RESPONSE" | jq -r '.message' 2>/dev/null)"
    exit 1
fi

echo ""
echo "📱 4️⃣ اختبار إنشاء QR Code:"
echo "========================="

QR_RESPONSE=$(curl -s -X POST https://unibus.online/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -d '{"email":"test@test.com"}')

echo "📱 استجابة QR Code:"
echo "$QR_RESPONSE" | jq '.' 2>/dev/null || echo "$QR_RESPONSE"

QR_SUCCESS=$(echo "$QR_RESPONSE" | jq -r '.success' 2>/dev/null)

if [ "$QR_SUCCESS" = "true" ]; then
    echo "✅ تم إنشاء QR Code بنجاح!"
    echo "📝 الرسالة: $(echo "$QR_RESPONSE" | jq -r '.message' 2>/dev/null)"
    
    # فحص وجود QR Code data
    QR_DATA=$(echo "$QR_RESPONSE" | jq -r '.qrCode' 2>/dev/null)
    if [ "$QR_DATA" != "null" ] && [ -n "$QR_DATA" ]; then
        QR_SIZE=${#QR_DATA}
        echo "📊 حجم QR Code: $QR_SIZE حرف"
        echo "🔗 نوع QR Code: $(echo "$QR_DATA" | head -c 20)..."
        
        # حفظ QR Code في ملف للمراجعة
        echo "$QR_DATA" > /tmp/student_qr_code.txt
        echo "💾 تم حفظ QR Code في: /tmp/student_qr_code.txt"
    else
        echo "⚠️  QR Code مُنشأ لكن البيانات غير متاحة"
    fi
else
    echo "❌ فشل في إنشاء QR Code!"
    echo "الخطأ: $(echo "$QR_RESPONSE" | jq -r '.message' 2>/dev/null)"
fi

echo ""
echo "🔍 5️⃣ اختبار Student Search:"
echo "=========================="

echo "🔍 فحص بيانات الطالب في Student Search:"
STUDENT_SEARCH_RESPONSE=$(curl -s -X GET "https://unibus.online/api/admin/students" \
  -H "Content-Type: application/json")

echo "📊 استجابة Student Search:"
echo "$STUDENT_SEARCH_RESPONSE" | jq '.students[] | select(.email == "test@test.com")' 2>/dev/null || echo "لا توجد بيانات"

# فحص وجود الطالب في النتائج
STUDENT_FOUND=$(echo "$STUDENT_SEARCH_RESPONSE" | jq '.students[] | select(.email == "test@test.com")' 2>/dev/null)

if [ -n "$STUDENT_FOUND" ]; then
    echo "✅ الطالب موجود في Student Search!"
    echo "📋 بيانات الطالب:"
    echo "$STUDENT_FOUND" | jq '.'
else
    echo "❌ الطالب غير موجود في Student Search!"
fi

echo ""
echo "🔍 6️⃣ اختبار Student Data API:"
echo "============================"

echo "🔍 فحص بيانات الطالب من Student Data API:"
STUDENT_DATA_RESPONSE=$(curl -s -X GET "https://unibus.online/api/students/data?email=test@test.com" \
  -H "Authorization: Bearer $STUDENT_TOKEN")

echo "📊 استجابة Student Data API:"
echo "$STUDENT_DATA_RESPONSE" | jq '.' 2>/dev/null || echo "$STUDENT_DATA_RESPONSE"

STUDENT_DATA_SUCCESS=$(echo "$STUDENT_DATA_RESPONSE" | jq -r '.success' 2>/dev/null)

if [ "$STUDENT_DATA_SUCCESS" = "true" ]; then
    echo "✅ Student Data API يعمل!"
    echo "📋 بيانات الطالب:"
    echo "$STUDENT_DATA_RESPONSE" | jq '.student'
else
    echo "❌ Student Data API لا يعمل!"
    echo "الخطأ: $(echo "$STUDENT_DATA_RESPONSE" | jq -r '.message' 2>/dev/null)"
fi

echo ""
echo "🔍 7️⃣ اختبار Student Profile:"
echo "============================"

echo "🔍 فحص Student Profile:"
STUDENT_PROFILE_RESPONSE=$(curl -s -X GET "https://unibus.online/api/students/profile-simple?email=test@test.com" \
  -H "Authorization: Bearer $STUDENT_TOKEN")

echo "📊 استجابة Student Profile:"
echo "$STUDENT_PROFILE_RESPONSE" | jq '.' 2>/dev/null || echo "$STUDENT_PROFILE_RESPONSE"

echo ""
echo "📊 8️⃣ تقرير الاختبار النهائي:"
echo "=========================="

echo "✅ النتائج:"
echo "   🔑 Student Login: $([ "$STUDENT_TOKEN" != "null" ] && echo "نجح" || echo "فشل")"
echo "   📝 Registration: $([ "$REGISTRATION_SUCCESS" = "true" ] && echo "نجح" || echo "فشل")"
echo "   📱 QR Generation: $([ "$QR_SUCCESS" = "true" ] && echo "نجح" || echo "فشل")"
echo "   🔍 Student Search: $([ -n "$STUDENT_FOUND" ] && echo "نجح" || echo "فشل")"
echo "   📊 Student Data API: $([ "$STUDENT_DATA_SUCCESS" = "true" ] && echo "نجح" || echo "فشل")"

if [ "$REGISTRATION_SUCCESS" = "true" ] && [ "$QR_SUCCESS" = "true" ] && [ -n "$STUDENT_FOUND" ] && [ "$STUDENT_DATA_SUCCESS" = "true" ]; then
    echo ""
    echo "🎉 اختبار التدفق الكامل مكتمل وناجح 100%!"
    echo "✅ جميع العمليات تعمل بشكل مثالي!"
    echo "🌐 يمكنك الآن اختبار النظام في المتصفح:"
    echo ""
    echo "🎯 خطوات الاختبار في المتصفح:"
    echo "   1️⃣ سجّل دخول: https://unibus.online/login"
    echo "      📧 Email: test@test.com"
    echo "      🔐 Password: 123456"
    echo "   2️⃣ ادخل Registration: https://unibus.online/student/registration"
    echo "   3️⃣ أكمل البيانات واضغط 'Complete Registration'"
    echo "   4️⃣ اذهب لصفحة Portal: https://unibus.online/student/portal"
    echo "   5️⃣ اضغط على 'Generate QR Code'"
    echo "   6️⃣ تحقق من Student Search في Admin"
else
    echo ""
    echo "⚠️  هناك مشاكل في بعض العمليات"
    echo "🔧 يُنصح بمراجعة الأخطاء قبل اختبار المتصفح"
fi

echo ""
echo "📋 ملفات الاختبار المُنشأة:"
echo "   📱 QR Code: /tmp/student_qr_code.txt"
echo "   📊 يمكنك مراجعة هذه الملفات للتحقق"
