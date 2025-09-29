#!/bin/bash

echo "🔧 إصلاح تسجيل API Routes في server.js"
echo "===================================="

cd /var/www/unitrans

echo ""
echo "📊 1️⃣ فحص server.js الحالي:"
echo "========================="

echo "🔍 فحص routes في server.js:"
grep -n "app.use.*students" backend-new/server.js || echo "❌ students route غير مسجل"

echo ""
echo "🔍 فحص جميع routes:"
grep -n "app.use" backend-new/server.js

echo ""
echo "🔧 2️⃣ إضافة students route إلى server.js:"
echo "======================================"

# إنشاء backup
cp backend-new/server.js backend-new/server.js.backup

echo "📝 إضافة students route..."

# البحث عن موقع إضافة الـ route
ROUTE_LINE=$(grep -n "app.use.*admin" backend-new/server.js | head -1 | cut -d: -f1)

if [ -n "$ROUTE_LINE" ]; then
    echo "📍 تم العثور على موقع إضافة الـ route في السطر $ROUTE_LINE"
    
    # إضافة students route قبل admin route
    sed -i "${ROUTE_LINE}i\\app.use('/api/students', require('./routes/students'));" backend-new/server.js
    
    echo "✅ تم إضافة students route"
else
    echo "⚠️  لم يتم العثور على admin route، إضافة في النهاية..."
    
    # إضافة في نهاية الملف قبل app.listen
    sed -i '/app.listen/i\\app.use("/api/students", require("./routes/students"));' backend-new/server.js
    
    echo "✅ تم إضافة students route في النهاية"
fi

echo ""
echo "🔍 3️⃣ التحقق من التعديل:"
echo "======================"

echo "📋 students route في server.js:"
grep -n "students" backend-new/server.js

echo ""
echo "🔧 4️⃣ إعادة تشغيل Backend:"
echo "========================"

echo "🔄 إعادة تشغيل backend..."
pm2 restart unitrans-backend

echo "⏳ انتظار 10 ثواني للتأكد من التشغيل..."
sleep 10

echo "🔍 فحص حالة backend:"
pm2 status unitrans-backend

echo ""
echo "🧪 5️⃣ اختبار API Routes بعد الإصلاح:"
echo "=================================="

echo "🔍 اختبار /api/students/profile-simple:"
PROFILE_TEST=$(curl -s -X GET "https://unibus.online/api/students/profile-simple?email=test@test.com" \
  -H "Content-Type: application/json")

echo "Profile Simple Response:"
echo "$PROFILE_TEST" | jq '.' 2>/dev/null || echo "$PROFILE_TEST"

echo ""
echo "🔍 اختبار /api/students/search:"
SEARCH_TEST=$(curl -s -X GET "https://unibus.online/api/students/search?q=test" \
  -H "Content-Type: application/json")

echo "Search Response:"
echo "$SEARCH_TEST" | jq '.' 2>/dev/null || echo "$SEARCH_TEST"

echo ""
echo "🔍 اختبار /api/students/data:"
DATA_TEST=$(curl -s -X GET "https://unibus.online/api/students/data?email=test@test.com" \
  -H "Content-Type: application/json")

echo "Data Response:"
echo "$DATA_TEST" | jq '.' 2>/dev/null || echo "$DATA_TEST"

echo ""
echo "🔍 اختبار /api/students/generate-qr:"
QR_TEST=$(curl -s -X POST "https://unibus.online/api/students/generate-qr" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com"}')

echo "QR Response:"
echo "$QR_TEST" | jq '.' 2>/dev/null || echo "$QR_TEST"

echo ""
echo "📊 6️⃣ تقرير الإصلاح النهائي:"
echo "========================="

echo "✅ الإصلاحات المطبقة:"
echo "   📝 تم إضافة students route إلى server.js"
echo "   🔄 تم إعادة تشغيل backend"
echo "   🧪 تم اختبار جميع API routes"

echo ""
echo "🎯 النتائج:"
PROFILE_SUCCESS=$(echo "$PROFILE_TEST" | jq -r '.success' 2>/dev/null)
SEARCH_SUCCESS=$(echo "$SEARCH_TEST" | jq -r '.success' 2>/dev/null)
DATA_SUCCESS=$(echo "$DATA_TEST" | jq -r '.success' 2>/dev/null)
QR_SUCCESS=$(echo "$QR_TEST" | jq -r '.success' 2>/dev/null)

echo "   📋 Profile Simple: $([ "$PROFILE_SUCCESS" = "true" ] && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   🔍 Search: $([ "$SEARCH_SUCCESS" = "true" ] && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   📊 Data: $([ "$DATA_SUCCESS" = "true" ] && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   📱 QR Generation: $([ "$QR_SUCCESS" = "true" ] && echo "✅ يعمل" || echo "❌ لا يعمل")"

if [ "$PROFILE_SUCCESS" = "true" ] && [ "$SEARCH_SUCCESS" = "true" ] && [ "$DATA_SUCCESS" = "true" ] && [ "$QR_SUCCESS" = "true" ]; then
    echo ""
    echo "🎉 تم إصلاح جميع المشاكل!"
    echo "✅ جميع API Routes تعمل بشكل كامل!"
    echo "🌐 يمكنك الآن اختبار Registration في المتصفح:"
    echo "   🔗 https://unibus.online/student/registration"
    echo "   📧 Email: test@test.com"
    echo "   🔐 Password: 123456"
else
    echo ""
    echo "⚠️  لا تزال هناك مشاكل"
    echo "🔧 يُنصح بمراجعة الأخطاء"
    
    # فحص logs للبحث عن أخطاء
    echo ""
    echo "🔍 فحص backend logs:"
    pm2 logs unitrans-backend --lines 10
fi

echo ""
echo "🔍 7️⃣ فحص إضافي - Backend Logs:"
echo "============================="

echo "📋 آخر 20 سطر من backend logs:"
pm2 logs unitrans-backend --lines 20
