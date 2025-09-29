#!/bin/bash

echo "🔍 فحص مكونات صفحة Registration على السيرفر"
echo "========================================="

cd /var/www/unitrans

echo ""
echo "📊 1️⃣ فحص حالة Build:"
echo "==================="

echo "🔍 فحص .next directory:"
if [ -d "frontend-new/.next" ]; then
    echo "✅ .next directory موجود"
    echo "📋 محتوى .next:"
    ls -la frontend-new/.next/ | head -10
else
    echo "❌ .next directory غير موجود - لم يتم build!"
fi

echo ""
echo "🔍 فحص build status:"
if [ -f "frontend-new/.next/BUILD_ID" ]; then
    echo "✅ BUILD_ID موجود"
    echo "📋 Build ID: $(cat frontend-new/.next/BUILD_ID)"
else
    echo "❌ BUILD_ID غير موجود - لم يتم build!"
fi

echo ""
echo "🔍 2️⃣ فحص صفحة Registration:"
echo "========================="

echo "🔍 فحص ملف الصفحة:"
if [ -f "frontend-new/app/student/registration/page.js" ]; then
    echo "✅ صفحة Registration موجودة"
    echo "📋 حجم الملف: $(wc -c < frontend-new/app/student/registration/page.js) bytes"
    echo "📋 عدد الأسطر: $(wc -l < frontend-new/app/student/registration/page.js)"
    
    echo ""
    echo "📋 أول 30 سطر من الصفحة:"
    head -30 frontend-new/app/student/registration/page.js
    
    echo ""
    echo "📋 آخر 30 سطر من الصفحة:"
    tail -30 frontend-new/app/student/registration/page.js
else
    echo "❌ صفحة Registration غير موجودة!"
fi

echo ""
echo "🔍 3️⃣ فحص Frontend Build:"
echo "========================"

echo "🔍 فحص package.json:"
if [ -f "frontend-new/package.json" ]; then
    echo "✅ package.json موجود"
    echo "📋 build script:"
    grep -A 2 -B 2 "build" frontend-new/package.json
else
    echo "❌ package.json غير موجود!"
fi

echo ""
echo "🔍 فحص node_modules:"
if [ -d "frontend-new/node_modules" ]; then
    echo "✅ node_modules موجود"
    echo "📋 حجم node_modules: $(du -sh frontend-new/node_modules)"
else
    echo "❌ node_modules غير موجود!"
fi

echo ""
echo "🔧 4️⃣ إعادة Build Frontend:"
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
    echo "📋 محتوى .next:"
    ls -la .next/ | head -10
else
    echo "❌ Build فشل!"
fi

cd ..

echo ""
echo "🔧 5️⃣ إعادة تشغيل Frontend:"
echo "========================="

echo "🔄 إعادة تشغيل frontend..."
pm2 restart unitrans-frontend

echo "⏳ انتظار 20 ثواني للتأكد من التشغيل..."
sleep 20

echo "🔍 فحص حالة frontend:"
pm2 status unitrans-frontend

echo ""
echo "🧪 6️⃣ اختبار صفحة Registration:"
echo "============================="

echo "🔍 فحص صفحة Registration:"
REG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/student/registration)
echo "Registration Page Status: $REG_STATUS"

if [ "$REG_STATUS" = "200" ]; then
    echo "✅ صفحة Registration تعمل!"
    echo "🌐 يمكنك الآن اختبار الصفحة في المتصفح:"
    echo "   🔗 https://unibus.online/student/registration"
else
    echo "❌ صفحة Registration لا تعمل! Status: $REG_STATUS"
fi

echo ""
echo "🔍 7️⃣ فحص Frontend Logs:"
echo "======================"

echo "📋 آخر 30 سطر من frontend logs:"
pm2 logs unitrans-frontend --lines 30

echo ""
echo "🔍 8️⃣ فحص Build Logs:"
echo "==================="

echo "📋 فحص build logs:"
if [ -f "frontend-new/.next/build.log" ]; then
    echo "📋 Build logs:"
    cat frontend-new/.next/build.log
else
    echo "❌ Build logs غير موجودة"
fi

echo ""
echo "📊 9️⃣ تقرير الفحص النهائي:"
echo "======================="

echo "✅ الفحوصات المطبقة:"
echo "   📋 فحص .next directory"
echo "   📋 فحص صفحة Registration"
echo "   📋 فحص package.json و node_modules"
echo "   🔄 إعادة build frontend"
echo "   🔄 إعادة تشغيل frontend"
echo "   🧪 اختبار الصفحة"

echo ""
echo "🎯 النتائج:"
echo "   📋 Build Status: $([ -d "frontend-new/.next" ] && echo "✅ نجح" || echo "❌ فشل")"
echo "   📋 Registration Page: $([ "$REG_STATUS" = "200" ] && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   📋 Frontend Status: $(pm2 status unitrans-frontend | grep unitrans-frontend | awk '{print $10}')"

echo ""
echo "🎉 تم فحص جميع مكونات الصفحة!"
echo "✅ يمكنك الآن اختبار الصفحة في المتصفح"
echo ""
echo "🎯 ما يجب أن تراه:"
echo "   📋 صفحة Registration مع حقول واضحة"
echo "   🎨 تصميم بسيط ونظيف"
echo "   ✅ أزرار تعمل بشكل صحيح"
