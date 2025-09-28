#!/bin/bash

echo "🔍 فحص حذف صفحات Auth من السيرفر"
echo "===================================="
echo ""

# التأكد من المسار الصحيح
cd /var/www/unitrans

echo "📂 فحص وجود صفحات Auth..."
echo ""

# فحص frontend Auth pages
echo "🖥️  فحص Frontend Auth pages:"
if [ -d "frontend-new/app/auth" ]; then
    echo "  ❌ FOUND: frontend-new/app/auth (يجب حذفها)"
    ls -la frontend-new/app/auth/
else
    echo "  ✅ DELETED: frontend-new/app/auth (محذوفة بنجاح)"
fi

if [ -d "frontend-new/app/auth-working" ]; then
    echo "  ❌ FOUND: frontend-new/app/auth-working (يجب حذفها)"
    ls -la frontend-new/app/auth-working/
else
    echo "  ✅ DELETED: frontend-new/app/auth-working (محذوفة بنجاح)"
fi

# فحص proxy routes
echo ""
echo "🔄 فحص Proxy Routes:"
if [ -d "frontend-new/app/api/proxy/auth" ]; then
    echo "  ❌ FOUND: frontend-new/app/api/proxy/auth (يجب حذفها)"
    ls -la frontend-new/app/api/proxy/auth/
else
    echo "  ✅ DELETED: frontend-new/app/api/proxy/auth (محذوفة بنجاح)"
fi

# فحص backend Auth routes
echo ""
echo "⚙️  فحص Backend Auth Routes:"
if [ -f "backend-new/routes/auth.js" ]; then
    echo "  ❌ FOUND: backend-new/routes/auth.js (يجب حذفه)"
    echo "    حجم الملف: $(wc -l < backend-new/routes/auth.js) سطر"
else
    echo "  ✅ DELETED: backend-new/routes/auth.js (محذوف بنجاح)"
fi

if [ -f "backend-new/routes/auth-simple.js" ]; then
    echo "  ❌ FOUND: backend-new/routes/auth-simple.js (يجب حذفه)"
    echo "    حجم الملف: $(wc -l < backend-new/routes/auth-simple.js) سطر"
else
    echo "  ✅ DELETED: backend-new/routes/auth-simple.js (محذوف بنجاح)"
fi

# فحص cache
echo ""
echo "🧹 فحص Cache:"
if [ -d "frontend-new/.next" ]; then
    echo "  ❌ FOUND: frontend-new/.next (يجب حذفه)"
else
    echo "  ✅ DELETED: frontend-new/.next (محذوف بنجاح)"
fi

# فحص النسخ الاحتياطية
echo ""
echo "💾 فحص النسخ الاحتياطية:"
if [ -d "/var/www/unitrans-backup" ]; then
    echo "  ✅ النسخ الاحتياطية موجودة في:"
    ls -la /var/www/unitrans-backup/
else
    echo "  ⚠️  لا توجد نسخ احتياطية"
fi

# فحص حالة الخدمات
echo ""
echo "📊 حالة الخدمات الحالية:"
pm2 status

echo ""
echo "🔍 ملخص الفحص:"
echo "================"

# تحديد حالة الحذف
AUTH_PAGES_EXIST=false

if [ -d "frontend-new/app/auth" ] || [ -d "frontend-new/app/auth-working" ] || [ -d "frontend-new/app/api/proxy/auth" ] || [ -f "backend-new/routes/auth.js" ] || [ -f "backend-new/routes/auth-simple.js" ]; then
    AUTH_PAGES_EXIST=true
fi

if [ "$AUTH_PAGES_EXIST" = true ]; then
    echo "❌ صفحات Auth ما زالت موجودة - يجب حذفها"
    echo "🔧 قم بتشغيل: ./safe-remove-auth-pages.sh"
else
    echo "✅ جميع صفحات Auth محذوفة بنجاح!"
    echo "🎯 السيرفر جاهز لحل Auth جديد"
fi

echo ""
echo "📂 الملفات المتبقية في المشروع:"
echo "Frontend pages:"
ls -la frontend-new/app/ | grep -v auth
echo ""
echo "Backend routes:"
ls -la backend-new/routes/ | grep -v auth

echo ""
echo "✅ انتهى فحص حذف صفحات Auth"
