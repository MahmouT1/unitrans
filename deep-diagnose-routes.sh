#!/bin/bash

echo "🔍 تشخيص عميق لمشكلة proxy routes"
echo "===================================="

cd /var/www/unitrans

echo "1️⃣ حالة PM2:"
pm2 status

echo ""
echo "2️⃣ التحقق من Git والملفات:"
echo "هل نحن على آخر commit؟"
git log -1 --oneline

echo ""
echo "هل الملفات موجودة؟"
echo "📁 login route:"
if [ -f "frontend-new/app/api/login/route.js" ]; then
    echo "✅ موجود"
    echo "   📄 الحجم: $(wc -c < frontend-new/app/api/login/route.js) bytes"
    echo "   📝 أول 3 أسطر:"
    head -3 frontend-new/app/api/login/route.js
else
    echo "❌ مفقود!"
fi

echo ""
echo "📁 register route:"
if [ -f "frontend-new/app/api/register/route.js" ]; then
    echo "✅ موجود"
    echo "   📄 الحجم: $(wc -c < frontend-new/app/api/register/route.js) bytes"
    echo "   📝 أول 3 أسطر:"
    head -3 frontend-new/app/api/register/route.js
else
    echo "❌ مفقود!"
fi

echo ""
echo "3️⃣ التحقق من البناء (.next):"
cd frontend-new

echo "📂 .next structure:"
if [ -d ".next" ]; then
    echo "✅ .next موجود"
    echo "   📁 app structure:"
    ls -la .next/server/app/api/ 2>/dev/null || echo "   ❌ لا يوجد api في البناء!"
    
    echo ""
    echo "   🔍 البحث عن login في البناء:"
    find .next -name "*login*" -type f 2>/dev/null || echo "   ❌ لا يوجد login routes في البناء!"
    
    echo ""
    echo "   🔍 البحث عن register في البناء:"
    find .next -name "*register*" -type f 2>/dev/null || echo "   ❌ لا يوجد register routes في البناء!"
    
else
    echo "❌ .next غير موجود!"
fi

echo ""
echo "4️⃣ اختبار Frontend على port 3000 (مباشر):"
echo "============================================"

# اختبار مباشر على port 3000
echo "🧪 login test على port 3000:"
PORT3000_LOGIN=$(curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\nSTATUS_CODE:%{http_code}")

echo "Response: $PORT3000_LOGIN"

if echo "$PORT3000_LOGIN" | grep -q "STATUS_CODE:200"; then
    echo "✅ port 3000 يعمل بنجاح"
elif echo "$PORT3000_LOGIN" | grep -q "STATUS_CODE:404"; then
    echo "❌ port 3000 - route غير موجود"
else
    echo "⚠️ port 3000 - خطأ آخر"
fi

echo ""
echo "5️⃣ اختبار Nginx proxy (HTTPS):"
echo "=============================="

# اختبار عبر nginx
echo "🧪 login test عبر HTTPS:"
HTTPS_LOGIN=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\nSTATUS_CODE:%{http_code}")

echo "Response: $HTTPS_LOGIN"

if echo "$HTTPS_LOGIN" | grep -q "STATUS_CODE:200"; then
    echo "✅ HTTPS proxy يعمل بنجاح"
elif echo "$HTTPS_LOGIN" | grep -q "STATUS_CODE:404"; then
    echo "❌ HTTPS proxy - route غير موجود"
elif echo "$HTTPS_LOGIN" | grep -q "STATUS_CODE:502"; then
    echo "❌ HTTPS proxy - خطأ في الاتصال بـ Frontend"
else
    echo "⚠️ HTTPS proxy - خطأ آخر"
fi

echo ""
echo "6️⃣ التحقق من Nginx config:"
echo "=========================="
echo "🔍 Nginx configuration for API routes:"
nginx -t
echo ""
echo "📄 محتوى الـ Nginx config المتعلق بـ /api:"
grep -A 5 -B 5 "/api" /etc/nginx/sites-available/default 2>/dev/null || echo "لا يوجد config خاص بـ /api"

echo ""
echo "7️⃣ Frontend logs (آخر 20 سطر):"
echo "=============================="
pm2 logs unitrans-frontend --lines 20

echo ""
echo "8️⃣ خلاصة التشخيص:"
echo "=================="

if [ ! -f "app/api/login/route.js" ]; then
    echo "🔴 المشكلة: proxy routes مفقودة من المجلد"
    echo "💡 الحل: إعادة إنشاؤها"
elif [ ! -d ".next/server/app/api/login" ]; then
    echo "🔴 المشكلة: proxy routes غير مبنية في .next"
    echo "💡 الحل: إعادة بناء Frontend"
elif echo "$PORT3000_LOGIN" | grep -q "STATUS_CODE:404"; then
    echo "🔴 المشكلة: Frontend لا يجد routes رغم وجودها"
    echo "💡 الحل: مشكلة في Next.js routing"
elif echo "$HTTPS_LOGIN" | grep -q "STATUS_CODE:502"; then
    echo "🔴 المشكلة: Nginx لا يستطيع الوصول لـ Frontend"
    echo "💡 الحل: إعادة تشغيل Nginx"
else
    echo "🔴 المشكلة: غير محددة - نحتاج تحليل أعمق"
fi

echo ""
echo "🔗 الخطوة التالية: تنفيذ الحل المقترح أعلاه"
