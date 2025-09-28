#!/bin/bash

echo "⚡ نشر سريع لـ proxy routes"
echo "========================="

cd /var/www/unitrans

echo "📥 سحب proxy routes..."
git pull origin main

echo "🔍 التحقق من وجود proxy routes:"
if [ -f "frontend-new/app/api/login/route.js" ]; then
    echo "  ✅ login route موجود"
else
    echo "  ❌ login route مفقود!"
    exit 1
fi

if [ -f "frontend-new/app/api/register/route.js" ]; then
    echo "  ✅ register route موجود"
else
    echo "  ❌ register route مفقود!"
    exit 1
fi

echo ""
echo "🛠️  إعادة بناء Frontend مع proxy routes..."
cd frontend-new

# حذف cache كاملاً
rm -rf .next
rm -rf node_modules/.cache
rm -rf .next/cache

echo "🔨 بناء جديد..."
npm run build

echo ""
echo "🔄 إعادة تشغيل Frontend..."
pm2 restart unitrans-frontend

echo ""
echo "⏳ انتظار استقرار الخدمة..."
sleep 8

echo ""
echo "🧪 اختبار proxy routes الجديدة:"
echo "================================"

echo "1️⃣ اختبار proxy login:"
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\n📊 Status: %{http_code}\n"

echo ""
echo "2️⃣ اختبار صفحة login:"
curl -I https://unibus.online/login -w "\n📊 Status: %{http_code}\n"

echo ""
echo "📊 حالة الخدمات:"
pm2 status

echo ""
echo "✅ النشر السريع اكتمل!"
echo "🔗 جرب الآن: https://unibus.online/login"
