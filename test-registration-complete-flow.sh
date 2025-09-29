#!/bin/bash

echo "🧪 اختبار Registration و QR Code كاملاً على السيرفر"
echo "=================================================="

cd /var/www/unitrans

echo ""
echo "📊 1️⃣ فحص حالة النظام:"
echo "===================="

echo "🔍 PM2 Status:"
pm2 status

echo ""
echo "🌐 فحص صفحة Registration:"
REG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/student/registration)
echo "Registration Page Status: $REG_STATUS"

if [ "$REG_STATUS" != "200" ]; then
    echo "❌ Registration page لا تعمل! Status: $REG_STATUS"
    exit 1
fi

echo "✅ Registration page تعمل بامتياز"

echo ""
echo "🔑 2️⃣ اختبار Login للحصول على Token:"
echo "====================================="

LOGIN_RESPONSE=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}')

echo "Login Response:"
echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"

# استخراج Token
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token' 2>/dev/null)

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo "❌ فشل في الحصول على Token!"
    exit 1
fi

echo "✅ تم الحصول على Token: ${TOKEN:0:20}..."

echo ""
echo "📝 3️⃣ اختبار تحديث بيانات الطالب:"
echo "==============================="

# بيانات الطالب للتحديث
STUDENT_DATA='{
  "fullName": "محمود طارق - اختبار سيرفر",
  "phoneNumber": "01025713978",
  "email": "test@test.com",
  "college": "كلية الحاسوب والمعلومات",
  "grade": "third-year", 
  "major": "نظم المعلومات",
  "address": {
    "streetAddress": "شارع الجامعة",
    "buildingNumber": "123",
    "fullAddress": "السويس، مصر - اختبار سيرفر"
  },
  "profilePhoto": null
}'

echo "📤 إرسال بيانات الطالب:"
echo "$STUDENT_DATA" | jq '.'

PROFILE_RESPONSE=$(curl -s -X PUT https://unibus.online/api/students/data \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "$STUDENT_DATA")

echo ""
echo "📡 استجابة تحديث البيانات:"
echo "$PROFILE_RESPONSE" | jq '.' 2>/dev/null || echo "$PROFILE_RESPONSE"

# فحص نجاح التحديث
PROFILE_SUCCESS=$(echo "$PROFILE_RESPONSE" | jq -r '.success' 2>/dev/null)

if [ "$PROFILE_SUCCESS" != "true" ]; then
    echo "❌ فشل في تحديث بيانات الطالب!"
    echo "الخطأ: $(echo "$PROFILE_RESPONSE" | jq -r '.message' 2>/dev/null)"
    exit 1
fi

echo "✅ تم تحديث بيانات الطالب بنجاح"

echo ""
echo "📱 4️⃣ اختبار إنشاء QR Code:"
echo "========================="

QR_REQUEST='{"email":"test@test.com"}'

echo "📤 طلب إنشاء QR Code:"
echo "$QR_REQUEST" | jq '.'

QR_RESPONSE=$(curl -s -X POST https://unibus.online/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "$QR_REQUEST")

echo ""
echo "📱 استجابة QR Code:"
QR_SUCCESS=$(echo "$QR_RESPONSE" | jq -r '.success' 2>/dev/null)
QR_MESSAGE=$(echo "$QR_RESPONSE" | jq -r '.message' 2>/dev/null)

if [ "$QR_SUCCESS" = "true" ]; then
    echo "✅ تم إنشاء QR Code بنجاح!"
    echo "📝 الرسالة: $QR_MESSAGE"
    
    # فحص وجود QR Code data
    QR_DATA=$(echo "$QR_RESPONSE" | jq -r '.qrCode' 2>/dev/null)
    if [ "$QR_DATA" != "null" ] && [ -n "$QR_DATA" ]; then
        QR_SIZE=${#QR_DATA}
        echo "📊 حجم QR Code: $QR_SIZE حرف"
        echo "🔗 نوع QR Code: $(echo "$QR_DATA" | head -c 20)..."
        
        # حفظ QR Code في ملف للمراجعة
        echo "$QR_DATA" > /tmp/test_qr_code.txt
        echo "💾 تم حفظ QR Code في: /tmp/test_qr_code.txt"
    else
        echo "⚠️  QR Code مُنشأ لكن البيانات غير متاحة"
    fi
else
    echo "❌ فشل في إنشاء QR Code!"
    echo "الخطأ: $QR_MESSAGE"
    echo "الاستجابة الكاملة:"
    echo "$QR_RESPONSE" | jq '.' 2>/dev/null || echo "$QR_RESPONSE"
fi

echo ""
echo "🔍 5️⃣ فحص قاعدة البيانات:"
echo "========================"

echo "🔍 فحص بيانات الطالب في قاعدة البيانات..."

# اختبار API للحصول على بيانات الطالب
STUDENT_GET_RESPONSE=$(curl -s -X GET "https://unibus.online/api/students/data?email=test@test.com" \
  -H "Authorization: Bearer $TOKEN")

echo "📊 بيانات الطالب من قاعدة البيانات:"
echo "$STUDENT_GET_RESPONSE" | jq '.' 2>/dev/null || echo "$STUDENT_GET_RESPONSE"

echo ""
echo "🧪 6️⃣ اختبار المسار الكامل عبر Next.js Proxy:"
echo "==========================================="

echo "🔍 اختبار /api/students/data عبر Next.js:"
NEXTJS_PROFILE_TEST=$(curl -s -X PUT https://unibus.online/api/students/data \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"fullName":"Test via NextJS Proxy","email":"test@test.com","phoneNumber":"01025713978","college":"Test College","grade":"third-year","major":"Test Major","address":{"streetAddress":"Test Street","fullAddress":"Test Address"}}')

echo "📡 نتيجة Next.js proxy test:"
echo "$NEXTJS_PROFILE_TEST" | jq '.' 2>/dev/null || echo "$NEXTJS_PROFILE_TEST"

echo ""
echo "🔍 اختبار /api/students/generate-qr عبر Next.js:"
NEXTJS_QR_TEST=$(curl -s -X POST https://unibus.online/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"email":"test@test.com"}')

echo "📱 نتيجة Next.js QR test:"
NEXTJS_QR_SUCCESS=$(echo "$NEXTJS_QR_TEST" | jq -r '.success' 2>/dev/null)
echo "QR Success: $NEXTJS_QR_SUCCESS"

echo ""
echo "📊 7️⃣ تقرير الاختبار النهائي:"
echo "=========================="

echo "✅ النتائج:"
echo "   🔑 Login: نجح"
echo "   📝 Profile Update: $([ "$PROFILE_SUCCESS" = "true" ] && echo "نجح" || echo "فشل")"
echo "   📱 QR Generation: $([ "$QR_SUCCESS" = "true" ] && echo "نجح" || echo "فشل")"
echo "   🔗 Next.js QR Proxy: $([ "$NEXTJS_QR_SUCCESS" = "true" ] && echo "نجح" || echo "فشل")"

if [ "$PROFILE_SUCCESS" = "true" ] && [ "$QR_SUCCESS" = "true" ] && [ "$NEXTJS_QR_SUCCESS" = "true" ]; then
    echo ""
    echo "🎉 اختبار Registration مكتمل وناجح 100%!"
    echo "🌐 الآن يمكنك اختبار Registration في المتصفح بثقة:"
    echo "   🔗 https://unibus.online/student/registration"
    echo "   📧 Email: test@test.com"
    echo "   🔐 Password: 123456"
    echo ""
    echo "🎯 خطوات الاختبار في المتصفح:"
    echo "   1️⃣ سجّل دخول"
    echo "   2️⃣ ادخل Registration"
    echo "   3️⃣ أكمل البيانات"
    echo "   4️⃣ احصل على QR Code!"
else
    echo ""
    echo "⚠️  هناك مشاكل في بعض الاختبارات"
    echo "🔧 يُنصح بمراجعة الأخطاء قبل اختبار المتصفح"
fi

echo ""
echo "📋 ملفات الاختبار المُنشأة:"
echo "   📱 QR Code: /tmp/test_qr_code.txt"
echo "   📊 يمكنك مراجعة هذه الملفات للتحقق"
