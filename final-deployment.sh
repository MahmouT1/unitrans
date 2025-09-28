#!/bin/bash

# نشر النظام المُعاد بناؤه بالكامل - يجب أن يعمل 100%

echo "================================================"
echo "🔧 نشر النظام المُعاد بناؤه بالكامل"
echo "================================================"

PROJECT_DIR="/var/www/unitrans"
BACKUP_DIR="$PROJECT_DIR/backups/final_$(date +%Y%m%d_%H%M%S)"

echo "📁 إنشاء نسخة احتياطية في: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -r "$PROJECT_DIR/backend-new" "$BACKUP_DIR/" 2>/dev/null || echo "تحذير: مشكلة في النسخ الاحتياطي"
cp -r "$PROJECT_DIR/frontend-new" "$BACKUP_DIR/" 2>/dev/null || echo "تحذير: مشكلة في النسخ الاحتياطي"

echo -e "\n1️⃣ سحب آخر التعديلات من GitHub..."
cd "$PROJECT_DIR" || exit 1
git stash
git pull origin main
echo "✅ تم سحب التعديلات"

echo -e "\n2️⃣ تثبيت dependencies للـ Backend..."
cd "$PROJECT_DIR/backend-new"
npm install dotenv mongodb express cors
echo "✅ تم تثبيت Backend dependencies"

echo -e "\n3️⃣ إعادة تشغيل Backend..."
pm2 stop unitrans-backend 2>/dev/null || true
pm2 delete unitrans-backend 2>/dev/null || true
NODE_ENV=production PORT=3001 pm2 start server.js --name "unitrans-backend"
sleep 3
echo "✅ تم إعادة تشغيل Backend"

echo -e "\n4️⃣ بناء Frontend..."
cd "$PROJECT_DIR/frontend-new"
rm -rf .next node_modules/.cache
npm run build
echo "✅ تم بناء Frontend"

echo -e "\n5️⃣ إعادة تشغيل Frontend..."
pm2 restart unitrans-frontend
sleep 3
echo "✅ تم إعادة تشغيل Frontend"

echo -e "\n6️⃣ فحص حالة النظام..."
pm2 status

echo -e "\n7️⃣ اختبار النظام..."

# اختبار Backend
BACKEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/health || echo "000")
echo "🔗 Backend Health: $BACKEND_HEALTH"

# اختبار Frontend
FRONTEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/auth || echo "000")
echo "🔗 Frontend Health: $FRONTEND_HEALTH"

# اختبار Login API
LOGIN_TEST=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3001/api/auth/login -H 'Content-Type: application/json' -d '{"email":"test@test.com","password":"invalid"}' || echo "000")
echo "🔗 Login API Test: $LOGIN_TEST"

# اختبار Auth Proxy
PROXY_TEST=$(curl -s -o /dev/null -w "%{http_code}" -X POST https://unibus.online/api/proxy/auth/login -H 'Content-Type: application/json' -d '{"email":"test@test.com","password":"invalid"}' || echo "000")
echo "🔗 Auth Proxy Test: $PROXY_TEST"

echo -e "\n================================================"
echo "✅ تم الانتهاء من النشر النهائي!"
echo "================================================"

echo -e "\n📋 ملخص النتائج:"
echo "  🔗 Backend Health: $BACKEND_HEALTH"
echo "  🔗 Frontend Health: $FRONTEND_HEALTH"
echo "  🔗 Login API Test: $LOGIN_TEST"
echo "  🔗 Auth Proxy Test: $PROXY_TEST"

echo -e "\n🌐 اختبر النظام الآن على:"
echo "  https://unibus.online/auth"

echo -e "\n🎯 ما تم إصلاحه:"
echo "  ✅ Backend: database.js + auth.js جديد ومبسط"
echo "  ✅ Frontend: صفحة Auth الأصلية مع apiCall"
echo "  ✅ Proxy Routes: login + register routes"
echo "  ✅ Dependencies: تثبيت جميع المكتبات المطلوبة"

if [[ "$BACKEND_HEALTH" == "200" && "$FRONTEND_HEALTH" == "200" ]]; then
    echo -e "\n🎉 النظام يعمل بنجاح! يمكنك تسجيل الدخول الآن!"
else
    echo -e "\n⚠️ هناك مشكلة. تحقق من logs:"
    echo "  pm2 logs unitrans-backend --lines 10"
    echo "  pm2 logs unitrans-frontend --lines 10"
fi

echo -e "\n💾 Backup محفوظ في: $BACKUP_DIR"
