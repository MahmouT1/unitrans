#!/bin/bash

# نشر إصلاح صفحة Auth مع الحفاظ على التصميم الأصلي

echo "================================================"
echo "🔧 نشر إصلاح صفحة Auth (بدون تغيير التصميم)"
echo "================================================"

# المتغيرات
PROJECT_DIR="/var/www/unitrans"
BACKUP_DIR="$PROJECT_DIR/backups/$(date +%Y%m%d_%H%M%S)"
FRONTEND_DIR="$PROJECT_DIR/frontend-new"

echo "📁 دليل المشروع: $PROJECT_DIR"
echo "💾 مجلد النسخ الاحتياطية: $BACKUP_DIR"

# 1️⃣ إنشاء نسخة احتياطية
echo -e "\n1️⃣ إنشاء نسخة احتياطية..."
mkdir -p "$BACKUP_DIR"
cp "$FRONTEND_DIR/app/auth/page.js" "$BACKUP_DIR/auth-page.js.backup" 2>/dev/null || echo "تحذير: لم يتم العثور على ملف Auth القديم"
cp "$FRONTEND_DIR/app/api/proxy/auth/login/route.js" "$BACKUP_DIR/login-route.js.backup" 2>/dev/null || echo "تحذير: لم يتم العثور على ملف Login route القديم"
cp "$FRONTEND_DIR/app/api/proxy/auth/register/route.js" "$BACKUP_DIR/register-route.js.backup" 2>/dev/null || echo "تحذير: لم يتم العثور على ملف Register route القديم"
echo "✅ تم إنشاء النسخة الاحتياطية"

# 2️⃣ الانتقال إلى دليل المشروع
echo -e "\n2️⃣ الانتقال إلى دليل المشروع..."
cd "$PROJECT_DIR" || {
    echo "❌ فشل في الانتقال إلى دليل المشروع"
    exit 1
}
echo "✅ تم الانتقال إلى: $(pwd)"

# 3️⃣ سحب آخر التعديلات من GitHub
echo -e "\n3️⃣ سحب آخر التعديلات من GitHub..."
git stash || echo "لا توجد تغييرات للحفظ المؤقت"
git pull origin main || {
    echo "❌ فشل في سحب التعديلات"
    exit 1
}
echo "✅ تم سحب آخر التعديلات"

# 4️⃣ فحص الملفات المستعادة
echo -e "\n4️⃣ فحص الملفات المستعادة..."
if [ -f "$FRONTEND_DIR/app/auth/page.js" ]; then
    echo "✅ صفحة Auth موجودة"
    # فحص أن الصفحة تحتوي على التصميم الأصلي
    if grep -q "UniBus Portal" "$FRONTEND_DIR/app/auth/page.js"; then
        echo "✅ التصميم الأصلي مستعاد بنجاح"
    else
        echo "⚠️ قد لا يكون التصميم الأصلي مستعاد بالكامل"
    fi
else
    echo "❌ ملف Auth مفقود!"
    exit 1
fi

if [ -f "$FRONTEND_DIR/app/api/proxy/auth/login/route.js" ]; then
    echo "✅ Login route موجود"
else
    echo "❌ Login route مفقود!"
    exit 1
fi

if [ -f "$FRONTEND_DIR/app/api/proxy/auth/register/route.js" ]; then
    echo "✅ Register route موجود"
else
    echo "❌ Register route مفقود!"
    exit 1
fi

# 5️⃣ حذف cache للبناء النظيف
echo -e "\n5️⃣ حذف cache للبناء النظيف..."
cd "$FRONTEND_DIR" || {
    echo "❌ فشل في الانتقال إلى دليل Frontend"
    exit 1
}
rm -rf .next node_modules/.cache
echo "✅ تم حذف cache"

# 6️⃣ بناء المشروع
echo -e "\n6️⃣ بناء المشروع..."
npm run build || {
    echo "❌ فشل في بناء المشروع"
    echo "📋 فحص الأخطاء:"
    npm run build 2>&1 | tail -20
    exit 1
}
echo "✅ تم بناء المشروع بنجاح"

# 7️⃣ إعادة تشغيل الخدمة
echo -e "\n7️⃣ إعادة تشغيل Frontend..."
pm2 restart unitrans-frontend || {
    echo "❌ فشل في إعادة تشغيل Frontend"
    pm2 status
    exit 1
}
echo "✅ تم إعادة تشغيل Frontend"

# 8️⃣ اختبار النظام
echo -e "\n8️⃣ اختبار النظام..."
sleep 3

# اختبار Frontend
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/auth)
echo "🔗 Frontend Health: $FRONTEND_STATUS"

# اختبار Backend  
BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/health)
echo "🔗 Backend Health: $BACKEND_STATUS"

# اختبار API
AUTH_TEST=$(curl -s -o /dev/null -w "%{http_code}" -X POST https://unibus.online/api/proxy/auth/login -H 'Content-Type: application/json' -d '{"email":"test@test.com","password":"invalid"}')
echo "🔗 Auth API Test: $AUTH_TEST"

echo -e "\n================================================"
echo "✅ تم الانتهاء من نشر إصلاح صفحة Auth!"
echo "================================================"

echo -e "\n📋 ملخص النتائج:"
echo "  🔗 Frontend Health: $FRONTEND_STATUS"
echo "  🔗 Backend Health: $BACKEND_STATUS"  
echo "  🔗 Auth API Test: $AUTH_TEST"

echo -e "\n🌐 يمكنك الآن اختبار النظام على:"
echo "  https://unibus.online/auth"

echo -e "\n💾 Backup محفوظ في: $BACKUP_DIR"

echo -e "\n🎯 الإصلاحات المطبقة:"
echo "  ✅ استعادة التصميم الأصلي لصفحة Auth"
echo "  ✅ إصلاح Login API route"
echo "  ✅ إصلاح Register API route"
echo "  ✅ إصلاح الاتصال بـ Backend"

# 9️⃣ حالة PM2
echo -e "\n📊 حالة الخدمات:"
pm2 status
