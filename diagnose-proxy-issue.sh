#!/bin/bash

echo "🔍 تشخيص مشكلة proxy routes"
echo "============================="

cd /var/www/unitrans

echo ""
echo "1️⃣ التحقق من Git status:"
git status

echo ""
echo "2️⃣ التحقق من وجود proxy routes في المجلد:"
echo "📁 frontend-new/app/api/ structure:"
ls -la frontend-new/app/api/

echo ""
echo "3️⃣ التحقق من محتوى login route:"
if [ -f "frontend-new/app/api/login/route.js" ]; then
    echo "✅ login route موجود:"
    head -10 frontend-new/app/api/login/route.js
else
    echo "❌ login route مفقود!"
fi

echo ""
echo "4️⃣ التحقق من محتوى register route:"
if [ -f "frontend-new/app/api/register/route.js" ]; then
    echo "✅ register route موجود:"
    head -10 frontend-new/app/api/register/route.js
else
    echo "❌ register route مفقود!"
fi

echo ""
echo "5️⃣ التحقق من .next build:"
if [ -d "frontend-new/.next/server/app/api/login" ]; then
    echo "✅ login route مبني في .next"
    ls -la frontend-new/.next/server/app/api/login/
else
    echo "❌ login route غير مبني في .next"
fi

if [ -d "frontend-new/.next/server/app/api/register" ]; then
    echo "✅ register route مبني في .next"
    ls -la frontend-new/.next/server/app/api/register/
else
    echo "❌ register route غير مبني في .next"
fi

echo ""
echo "6️⃣ اختبار مباشر للـ proxy routes:"
echo "Testing login proxy..."
RESPONSE=$(curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "STATUS_CODE:%{http_code}")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "STATUS_CODE:200"; then
    echo "✅ Proxy login يعمل بنجاح"
elif echo "$RESPONSE" | grep -q "STATUS_CODE:404"; then
    echo "❌ Proxy route غير موجود (404)"
elif echo "$RESPONSE" | grep -q "STATUS_CODE:500"; then
    echo "⚠️ خطأ في الخادم (500)"
else
    echo "❓ استجابة غير متوقعة"
fi

echo ""
echo "7️⃣ حالة PM2:"
pm2 status

echo ""
echo "8️⃣ آخر logs من Frontend:"
pm2 logs unitrans-frontend --lines 10

echo ""
echo "🔧 الحل المقترح:"
echo "=================="

if [ ! -f "frontend-new/app/api/login/route.js" ]; then
    echo "❌ proxy routes مفقودة - نحتاج إعادة إنشاء"
    echo "💡 تشغيل: ./create-missing-proxy-routes.sh"
elif [ ! -d "frontend-new/.next/server/app/api/login" ]; then
    echo "❌ proxy routes غير مبنية - نحتاج إعادة بناء"
    echo "💡 تشغيل: cd frontend-new && rm -rf .next && npm run build && pm2 restart unitrans-frontend"
else
    echo "✅ كل شيء يبدو صحيحاً - قد تكون مشكلة cache في المتصفح"
    echo "💡 جرب: Ctrl+Shift+R في المتصفح"
fi
