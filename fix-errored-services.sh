#!/bin/bash

echo "🔧 إصلاح الخدمات المعطلة"
echo "========================"
echo ""

cd /var/www/unitrans

echo "📋 فحص سبب تعطل الخدمات..."
echo ""
echo "🔍 لوج Backend:"
pm2 logs unitrans-backend --lines 10

echo ""
echo "🔍 لوج Frontend:"  
pm2 logs unitrans-frontend --lines 10

echo ""
echo "🛠️  إصلاح الخدمات..."

# إصلاح Backend
echo "⚙️  إصلاح Backend..."
cd backend-new

# التحقق من وجود server.js
if [ -f "server.js" ]; then
    echo "  ✅ server.js موجود"
else
    echo "  ❌ server.js مفقود!"
    exit 1
fi

# التحقق من auth route في server.js
if grep -q "auth" server.js; then
    echo "  ⚠️  auth route موجود في server.js - يجب إزالته"
    # إزالة auth routes المعطلة من server.js
    sed -i '/auth/d' server.js
    echo "  ✅ تم إزالة auth routes المعطلة"
fi

# إعادة تشغيل Backend
pm2 delete unitrans-backend
pm2 start server.js --name unitrans-backend
echo "  ✅ تم إعادة تشغيل Backend"

# إصلاح Frontend  
echo ""
echo "🖥️  إصلاح Frontend..."
cd ../frontend-new

# التحقق من package.json
if [ -f "package.json" ]; then
    echo "  ✅ package.json موجود"
else
    echo "  ❌ package.json مفقود!"
    exit 1
fi

# حذف cache وإعادة البناء
rm -rf .next node_modules/.cache
echo "  🧹 تم حذف cache"

# إعادة البناء
npm run build
echo "  🔨 تم إعادة البناء"

# إعادة تشغيل Frontend
pm2 delete unitrans-frontend  
pm2 start npm --name unitrans-frontend -- start
echo "  ✅ تم إعادة تشغيل Frontend"

echo ""
echo "⏳ انتظار استقرار الخدمات..."
sleep 10

echo ""
echo "📊 حالة الخدمات بعد الإصلاح:"
pm2 status

echo ""
echo "🌐 اختبار الموقع:"
curl -I https://unibus.online/

echo ""
echo "✅ اكتمل إصلاح الخدمات!"
