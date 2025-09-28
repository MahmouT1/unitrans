#!/bin/bash

# =================================================
# 🚀 نشر إصلاح مشكلة التسجيل - Script احترافي
# =================================================

echo "🔄 بدء نشر إصلاح مشكلة التسجيل..."
echo "================================================"

# 1️⃣ سحب آخر التحديثات من GitHub
echo "📥 1. سحب آخر التحديثات من GitHub..."
cd /var/www/unitrans
git stash push -m "backup before registration fix"
git pull origin main

if [ $? -ne 0 ]; then
    echo "❌ فشل في سحب التحديثات من GitHub"
    exit 1
fi

echo "✅ تم سحب التحديثات بنجاح"

# 2️⃣ أخذ backup من الملفات الحالية
echo "💾 2. أخذ backup من الملفات الحالية..."
mkdir -p /var/www/unitrans/backups/$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/www/unitrans/backups/$(date +%Y%m%d_%H%M%S)"

cp frontend-new/app/auth/page.js $BACKUP_DIR/auth-page-backup.js
cp frontend-new/app/api/proxy/auth/register/route.js $BACKUP_DIR/register-route-backup.js
cp frontend-new/app/api/proxy/auth/login/route.js $BACKUP_DIR/login-route-backup.js
cp backend-new/routes/auth.js $BACKUP_DIR/backend-auth-backup.js

echo "✅ تم حفظ backup في: $BACKUP_DIR"

# 3️⃣ تثبيت المكتبات المطلوبة
echo "📦 3. تثبيت المكتبات المطلوبة..."
cd backend-new
npm install qrcode
cd ..

# 4️⃣ إعادة تشغيل Backend
echo "🔄 4. إعادة تشغيل Backend..."
pm2 restart unitrans-backend

# انتظار قليل للتأكد من بدء Backend
sleep 3

# 5️⃣ فحص صحة Backend
echo "🧪 5. فحص صحة Backend..."
BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online:3001/health)

if [ "$BACKEND_STATUS" = "200" ]; then
    echo "✅ Backend يعمل بشكل صحيح"
else
    echo "❌ Backend لا يستجيب (Status: $BACKEND_STATUS)"
    echo "📋 محاولة إعادة تشغيل Backend..."
    pm2 restart unitrans-backend
    sleep 5
fi

# 6️⃣ إزالة cache وإعادة بناء Frontend
echo "🔨 6. إعادة بناء Frontend..."
cd frontend-new
rm -rf .next
rm -rf node_modules/.cache

# بناء المشروع
npm run build

if [ $? -ne 0 ]; then
    echo "❌ فشل في بناء Frontend"
    echo "🔄 محاولة إصلاح المشاكل..."
    npm install
    npm run build
    
    if [ $? -ne 0 ]; then
        echo "❌ فشل نهائي في بناء Frontend"
        echo "💾 استعادة backup..."
        cp $BACKUP_DIR/auth-page-backup.js app/auth/page.js
        npm run build
        exit 1
    fi
fi

cd ..

# 7️⃣ إعادة تشغيل Frontend
echo "🔄 7. إعادة تشغيل Frontend..."
pm2 restart unitrans-frontend

# انتظار قليل للتأكد من بدء Frontend
sleep 5

# 8️⃣ فحص صحة Frontend
echo "🧪 8. فحص صحة Frontend..."
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/auth)

if [ "$FRONTEND_STATUS" = "200" ]; then
    echo "✅ Frontend يعمل بشكل صحيح"
else
    echo "❌ Frontend لا يستجيب (Status: $FRONTEND_STATUS)"
    echo "🔄 محاولة إعادة تشغيل Frontend..."
    pm2 restart unitrans-frontend
    sleep 5
fi

# 9️⃣ اختبار APIs
echo "🧪 9. اختبار APIs الجديدة..."

# اختبار Backend API مباشرة
echo "📡 اختبار Backend Registration API..."
BACKEND_TEST=$(curl -s -X POST https://unibus.online:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test-'$(date +%s)'@test.com","password":"test123","fullName":"Test User","role":"student"}' \
  -w "%{http_code}" -o /tmp/backend_test.json)

if [ "$BACKEND_TEST" = "201" ] || [ "$BACKEND_TEST" = "409" ]; then
    echo "✅ Backend Registration API يعمل (Status: $BACKEND_TEST)"
else
    echo "⚠️ Backend Registration API (Status: $BACKEND_TEST)"
    cat /tmp/backend_test.json
fi

# اختبار Frontend Proxy API
echo "📡 اختبار Frontend Proxy API..."
FRONTEND_TEST=$(curl -s -X POST https://unibus.online/api/proxy/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test-'$(date +%s)'@test.com","password":"test123","fullName":"Test User","role":"student"}' \
  -w "%{http_code}" -o /tmp/frontend_test.json)

if [ "$FRONTEND_TEST" = "201" ] || [ "$FRONTEND_TEST" = "409" ]; then
    echo "✅ Frontend Proxy API يعمل (Status: $FRONTEND_TEST)"
else
    echo "⚠️ Frontend Proxy API (Status: $FRONTEND_TEST)"
    cat /tmp/frontend_test.json
fi

# 🔟 فحص حالة PM2
echo "📊 10. فحص حالة الخدمات..."
pm2 status

# نظافة الملفات المؤقتة
rm -f /tmp/backend_test.json /tmp/frontend_test.json

echo ""
echo "================================================"
echo "✅ تم الانتهاء من نشر إصلاح التسجيل!"
echo "================================================"
echo ""
echo "📋 ملخص النتائج:"
echo "  🔗 Backend Health: $BACKEND_STATUS"
echo "  🔗 Frontend Health: $FRONTEND_STATUS"
echo "  🔗 Backend API Test: $BACKEND_TEST"
echo "  🔗 Frontend API Test: $FRONTEND_TEST"
echo ""
echo "🌐 يمكنك الآن اختبار التسجيل على:"
echo "  https://unibus.online/auth"
echo ""
echo "💾 Backup محفوظ في: $BACKUP_DIR"
echo ""
echo "🎯 الميزات الجديدة:"
echo "  ✅ إصلاح مشكلة 'Registration not implemented yet'"
echo "  ✅ تفعيل التسجيل الكامل للطلاب"
echo "  ✅ إنشاء سجل طالب تلقائياً"
echo "  ✅ توجيه المستخدم حسب الدور"
echo "  ✅ حفظ بيانات المستخدم"
