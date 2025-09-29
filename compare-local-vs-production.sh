#!/bin/bash

echo "🔍 مقارنة السيرفر المحلي مع الإنتاجي"
echo "=================================="

cd /var/www/unitrans

echo ""
echo "📊 1️⃣ فحص صفحة Registration الحالية:"
echo "================================="

echo "🔍 فحص محتوى صفحة Registration:"
if [ -f "frontend-new/app/student/registration/page.js" ]; then
    echo "✅ صفحة Registration موجودة"
    echo "📋 أول 30 سطر من الصفحة:"
    head -30 frontend-new/app/student/registration/page.js
else
    echo "❌ صفحة Registration غير موجودة!"
fi

echo ""
echo "🔍 فحص API calls في الصفحة:"
if [ -f "frontend-new/app/student/registration/page.js" ]; then
    echo "📋 API calls المستخدمة:"
    grep -n "fetch\|api" frontend-new/app/student/registration/page.js | head -10
fi

echo ""
echo "🔍 2️⃣ فحص API Routes المطلوبة:"
echo "============================"

echo "🔍 فحص /api/students/data:"
DATA_TEST=$(curl -s -X GET "https://unibus.online/api/students/data?email=test@test.com" \
  -H "Content-Type: application/json")

echo "Data API Response:"
echo "$DATA_TEST" | jq '.' 2>/dev/null || echo "$DATA_TEST"

echo ""
echo "🔍 فحص /api/students/generate-qr:"
QR_TEST=$(curl -s -X POST "https://unibus.online/api/students/generate-qr" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com"}')

echo "QR API Response:"
echo "$QR_TEST" | jq '.' 2>/dev/null || echo "$QR_TEST"

echo ""
echo "🔍 3️⃣ فحص Backend Routes:"
echo "========================"

echo "🔍 فحص server.js routes:"
grep -n "students" backend-new/server.js || echo "❌ students route غير موجود"

echo ""
echo "🔍 فحص students.js:"
if [ -f "backend-new/routes/students.js" ]; then
    echo "✅ students.js موجود"
    echo "📋 routes في students.js:"
    grep -n "router\." backend-new/routes/students.js
else
    echo "❌ students.js غير موجود!"
fi

echo ""
echo "🔍 4️⃣ فحص Frontend API Service:"
echo "============================="

echo "🔍 فحص services/api.js:"
if [ -f "frontend-new/services/api.js" ]; then
    echo "✅ api.js موجود"
    echo "📋 studentAPI في api.js:"
    grep -A 20 "studentAPI" frontend-new/services/api.js
else
    echo "❌ api.js غير موجود!"
fi

echo ""
echo "🔍 5️⃣ فحص Next.js API Routes:"
echo "==========================="

echo "🔍 فحص Next.js API routes:"
if [ -d "frontend-new/app/api" ]; then
    echo "✅ app/api directory موجود"
    echo "📋 API routes المتاحة:"
    find frontend-new/app/api -name "*.js" | head -10
else
    echo "❌ app/api directory غير موجود!"
fi

echo ""
echo "🔍 6️⃣ فحص Environment Variables:"
echo "=============================="

echo "🔍 فحص .env files:"
if [ -f "frontend-new/.env.local" ]; then
    echo "✅ .env.local موجود"
    cat frontend-new/.env.local
else
    echo "❌ .env.local غير موجود"
fi

if [ -f "backend-new/.env" ]; then
    echo "✅ backend .env موجود"
    echo "📋 MONGODB_URI: $(grep MONGODB_URI backend-new/.env)"
    echo "📋 MONGODB_DB_NAME: $(grep MONGODB_DB_NAME backend-new/.env)"
else
    echo "❌ backend .env غير موجود"
fi

echo ""
echo "🔍 7️⃣ فحص Network Configuration:"
echo "=============================="

echo "🔍 فحص Nginx configuration:"
if [ -f "/etc/nginx/sites-available/default" ]; then
    echo "✅ Nginx config موجود"
    echo "📋 proxy_pass configuration:"
    grep -A 5 -B 5 "proxy_pass" /etc/nginx/sites-available/default
else
    echo "❌ Nginx config غير موجود"
fi

echo ""
echo "🔍 8️⃣ فحص PM2 Processes:"
echo "======================"

echo "🔍 PM2 status:"
pm2 status

echo ""
echo "🔍 Backend logs:"
pm2 logs unitrans-backend --lines 10

echo ""
echo "🔍 Frontend logs:"
pm2 logs unitrans-frontend --lines 10

echo ""
echo "📊 9️⃣ تحليل المشكلة:"
echo "=================="

echo "🔍 ملخص المشاكل المحتملة:"

# فحص API routes
if echo "$DATA_TEST" | grep -q "Cannot GET"; then
    echo "❌ /api/students/data - Route not found"
fi

if echo "$QR_TEST" | grep -q "Cannot POST"; then
    echo "❌ /api/students/generate-qr - Route not found"
fi

# فحص backend routes
if ! grep -q "students" backend-new/server.js; then
    echo "❌ students route not registered in server.js"
fi

# فحص students.js
if [ ! -f "backend-new/routes/students.js" ]; then
    echo "❌ students.js file missing"
fi

echo ""
echo "🎯 10️⃣ التوصيات:"
echo "=============="

echo "🔧 الحلول المقترحة:"
echo "   1️⃣ تسجيل students route في server.js"
echo "   2️⃣ إنشاء students.js إذا لم يكن موجود"
echo "   3️⃣ فحص API endpoints في frontend"
echo "   4️⃣ فحص network configuration"
echo "   5️⃣ إعادة تشغيل جميع الخدمات"

echo ""
echo "🚀 الخطوات التالية:"
echo "   ./fix-server-routes-registration.sh"
echo "   أو"
echo "   ./fix-missing-api-routes.sh"
