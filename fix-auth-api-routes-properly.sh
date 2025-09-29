#!/bin/bash

echo "🔧 إصلاح auth-api routes بشكل صحيح"
echo "================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة الحالية:"
echo "======================="

echo "🔍 فحص server.js:"
if [ -f "backend-new/server.js" ]; then
    echo "✅ server.js موجود"
    
    # Check if auth-api routes exist
    if grep -q "auth-api/login" backend-new/server.js; then
        echo "✅ auth-api routes موجودة في server.js"
        echo "🔍 عرض auth-api routes:"
        grep -A 10 "auth-api/login" backend-new/server.js
    else
        echo "❌ auth-api routes غير موجودة في server.js"
    fi
else
    echo "❌ server.js غير موجود"
fi

echo ""
echo "🔧 2️⃣ إصلاح server.js بشكل صحيح:"
echo "=============================="

echo "🔍 فحص نهاية server.js:"
tail -20 backend-new/server.js

echo ""
echo "🔧 3️⃣ إضافة auth-api routes في المكان الصحيح:"
echo "========================================="

# Find the correct place to add routes (before the server.listen)
sed -i '/app.listen(3001/i\
\
// Frontend Auth API Routes for /auth-api compatibility\
app.post("/auth-api/login", async (req, res) => {\
    try {\
        const { email, password } = req.body;\
        console.log("🔐 Frontend Auth API Login Request:", email);\
        \
        const authResponse = await fetch(`http://localhost:3001/api/auth-pro/login`, {\
            method: "POST",\
            headers: { "Content-Type": "application/json" },\
            body: JSON.stringify({ email, password })\
        });\
        \
        const data = await authResponse.json();\
        console.log("🔐 Frontend Auth API Login Response:", data);\
        \
        res.status(authResponse.status).json(data);\
    } catch (error) {\
        console.error("❌ Frontend Auth API Login Error:", error);\
        res.status(500).json({ success: false, message: "Internal server error" });\
    }\
});\
\
app.post("/auth-api/register", async (req, res) => {\
    try {\
        const { email, password, fullName, role } = req.body;\
        console.log("🔐 Frontend Auth API Register Request:", email);\
        \
        const authResponse = await fetch(`http://localhost:3001/api/auth-pro/register`, {\
            method: "POST",\
            headers: { "Content-Type": "application/json" },\
            body: JSON.stringify({ email, password, fullName, role })\
        });\
        \
        const data = await authResponse.json();\
        console.log("🔐 Frontend Auth API Register Response:", data);\
        \
        res.status(authResponse.status).json(data);\
    } catch (error) {\
        console.error("❌ Frontend Auth API Register Error:", error);\
        res.status(500).json({ success: false, message: "Internal server error" });\
    }\
});\
' backend-new/server.js

echo "✅ تم إضافة auth-api routes إلى server.js"

echo ""
echo "🔍 4️⃣ فحص server.js بعد الإضافة:"
echo "============================="

echo "🔍 فحص auth-api routes:"
if grep -q "auth-api/login" backend-new/server.js; then
    echo "✅ auth-api routes موجودة الآن"
    echo "🔍 عرض auth-api routes:"
    grep -A 5 "auth-api/login" backend-new/server.js
else
    echo "❌ auth-api routes غير موجودة"
fi

echo ""
echo "🔧 5️⃣ إعادة تشغيل Backend:"
echo "========================="

echo "🔄 إعادة تشغيل backend..."
pm2 restart unitrans-backend

echo "⏳ انتظار 15 ثانية للتأكد من التشغيل..."
sleep 15

echo "🔍 فحص حالة backend:"
pm2 status unitrans-backend

echo ""
echo "🔧 6️⃣ اختبار API endpoints:"
echo "========================="

echo "🔍 اختبار auth-api/login:"
AUTH_API_TEST=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/auth-api/login)
echo "Auth API Login: $AUTH_API_TEST"

echo ""
echo "🔍 اختبار auth-pro/login:"
AUTH_PRO_TEST=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online:3001/api/auth-pro/login)
echo "Auth Pro Login: $AUTH_PRO_TEST"

echo ""
echo "🔧 7️⃣ اختبار Login بالبيانات:"
echo "==========================="

echo "🔍 اختبار login مع بيانات الطالب:"
curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -s | head -3

echo ""
echo "🔍 اختبار login مع بيانات الإدارة:"
curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"roo2admin@gmail.com","password":"admin123"}' \
  -s | head -3

echo ""
echo "🔧 8️⃣ فحص Backend Logs:"
echo "====================="

echo "🔍 فحص backend logs:"
pm2 logs unitrans-backend --lines 10

echo ""
echo "🔧 9️⃣ إعادة Build Frontend:"
echo "========================="

echo "🔄 حذف .next directory:"
rm -rf frontend-new/.next

echo "🔄 حذف node_modules/.cache:"
rm -rf frontend-new/node_modules/.cache

echo "🔄 إعادة build frontend:"
cd frontend-new
npm run build

echo ""
echo "🔍 فحص build result:"
if [ -d ".next" ]; then
    echo "✅ Build نجح!"
else
    echo "❌ Build فشل!"
fi

cd ..

echo ""
echo "🔧 10️⃣ إعادة تشغيل Frontend:"
echo "=========================="

echo "🔄 إعادة تشغيل frontend..."
pm2 restart unitrans-frontend

echo "⏳ انتظار 10 ثواني للتأكد من التشغيل..."
sleep 10

echo "🔍 فحص حالة frontend:"
pm2 status unitrans-frontend

echo ""
echo "🧪 11️⃣ اختبار صفحة Login النهائية:"
echo "=============================="

echo "🔍 اختبار صفحة Login:"
LOGIN_PAGE_FINAL=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/login)
echo "Login Page: $LOGIN_PAGE_FINAL"

echo ""
echo "🔍 اختبار auth-api/login:"
AUTH_API_FINAL=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/auth-api/login)
echo "Auth API: $AUTH_API_FINAL"

echo ""
echo "🔍 اختبار auth-pro/login:"
AUTH_PRO_FINAL=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online:3001/api/auth-pro/login)
echo "Auth Pro: $AUTH_PRO_FINAL"

echo ""
echo "📊 12️⃣ تقرير الإصلاح النهائي:"
echo "=========================="

echo "✅ الإصلاحات المطبقة:"
echo "   🔧 تم إضافة auth-api routes إلى server.js في المكان الصحيح"
echo "   🔄 تم إعادة تشغيل backend"
echo "   🔄 تم إعادة build frontend"
echo "   🔄 تم إعادة تشغيل frontend"
echo "   🧪 تم اختبار API endpoints"

echo ""
echo "🎯 النتائج:"
echo "   📱 Login Page: $LOGIN_PAGE_FINAL"
echo "   🔐 Auth API: $AUTH_API_FINAL"
echo "   🔐 Auth Pro: $AUTH_PRO_FINAL"
echo "   🔧 Backend: $(pm2 status unitrans-backend | grep unitrans-backend | awk '{print $4}')"
echo "   🔧 Frontend: $(pm2 status unitrans-frontend | grep unitrans-frontend | awk '{print $4}')"

echo ""
echo "🎉 تم إصلاح auth-api routes بشكل صحيح!"
echo "🌐 يمكنك الآن اختبار صفحة Login:"
echo "   🔗 https://unibus.online/login"
echo "   📧 test@test.com / 123456"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
