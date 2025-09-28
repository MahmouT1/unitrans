#!/bin/bash

echo "🔒 حذف آمن لصفحات Auth فقط"
echo "================================="
echo "⚠️  هذا السكريپت يحذف صفحات Auth فقط ولا يمس باقي المشروع"
echo ""

# التأكد من المسار الصحيح
cd /var/www/unitrans

echo "📂 إنشاء نسخة احتياطية من صفحات Auth..."
mkdir -p /var/www/unitrans-backup/auth-pages-$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/www/unitrans-backup/auth-pages-$(date +%Y%m%d_%H%M%S)"

# نسخ احتياطي لصفحات Auth
echo "💾 نسخ احتياطي للصفحات..."
if [ -d "frontend-new/app/auth" ]; then
    cp -r frontend-new/app/auth "$BACKUP_DIR/app-auth"
    echo "  ✅ نسخ احتياطي: frontend-new/app/auth"
fi

if [ -d "frontend-new/app/auth-working" ]; then
    cp -r frontend-new/app/auth-working "$BACKUP_DIR/app-auth-working"
    echo "  ✅ نسخ احتياطي: frontend-new/app/auth-working"
fi

if [ -d "frontend-new/app/api/proxy/auth" ]; then
    cp -r frontend-new/app/api/proxy/auth "$BACKUP_DIR/api-proxy-auth"
    echo "  ✅ نسخ احتياطي: frontend-new/app/api/proxy/auth"
fi

if [ -f "backend-new/routes/auth.js" ]; then
    cp backend-new/routes/auth.js "$BACKUP_DIR/auth.js"
    echo "  ✅ نسخ احتياطي: backend-new/routes/auth.js"
fi

if [ -f "backend-new/routes/auth-simple.js" ]; then
    cp backend-new/routes/auth-simple.js "$BACKUP_DIR/auth-simple.js"
    echo "  ✅ نسخ احتياطي: backend-new/routes/auth-simple.js"
fi

echo ""
echo "📍 النسخة الاحتياطية محفوظة في: $BACKUP_DIR"
echo ""

# إيقاف الخدمات مؤقتاً
echo "⏸️  إيقاف مؤقت للخدمات..."
pm2 stop unitrans-frontend
pm2 stop unitrans-backend

# حذف صفحات Auth فقط
echo "🗑️  حذف صفحات Auth..."

if [ -d "frontend-new/app/auth" ]; then
    rm -rf frontend-new/app/auth
    echo "  ❌ تم حذف: frontend-new/app/auth"
fi

if [ -d "frontend-new/app/auth-working" ]; then
    rm -rf frontend-new/app/auth-working
    echo "  ❌ تم حذف: frontend-new/app/auth-working"
fi

if [ -d "frontend-new/app/api/proxy/auth" ]; then
    rm -rf frontend-new/app/api/proxy/auth
    echo "  ❌ تم حذف: frontend-new/app/api/proxy/auth"
fi

if [ -f "backend-new/routes/auth.js" ]; then
    rm backend-new/routes/auth.js
    echo "  ❌ تم حذف: backend-new/routes/auth.js"
fi

if [ -f "backend-new/routes/auth-simple.js" ]; then
    rm backend-new/routes/auth-simple.js
    echo "  ❌ تم حذف: backend-new/routes/auth-simple.js"
fi

# حذف cache
echo "🧹 حذف cache..."
if [ -d "frontend-new/.next" ]; then
    rm -rf frontend-new/.next
    echo "  ❌ تم حذف: frontend-new/.next"
fi

if [ -d "frontend-new/node_modules/.cache" ]; then
    rm -rf frontend-new/node_modules/.cache
    echo "  ❌ تم حذف: frontend-new/node_modules/.cache"
fi

echo ""
echo "✅ تم حذف صفحات Auth بنجاح!"
echo ""
echo "📋 ملخص ما تم حذفه:"
echo "  ❌ frontend-new/app/auth (الصفحة الأصلية)"
echo "  ❌ frontend-new/app/auth-working (الصفحة الجديدة)"
echo "  ❌ frontend-new/app/api/proxy/auth (proxy routes)"
echo "  ❌ backend-new/routes/auth.js (backend routes الأصلي)"
echo "  ❌ backend-new/routes/auth-simple.js (backend routes البسيط)"
echo "  ❌ frontend-new/.next (cache)"
echo ""
echo "💾 النسخة الاحتياطية: $BACKUP_DIR"
echo ""
echo "🔄 إعادة تشغيل الخدمات..."
pm2 start unitrans-frontend
pm2 start unitrans-backend

echo ""
echo "📊 حالة الخدمات:"
pm2 status

echo ""
echo "✅ اكتمل الحذف الآمن لصفحات Auth!"
echo "🎯 المشروع الآن بدون صفحات Auth - جاهز للحل الجديد"
