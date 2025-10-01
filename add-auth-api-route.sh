#!/bin/bash

echo "➕ إضافة route /auth-api للتوافق مع صفحة Login"
echo "================================================"
echo ""

cd /var/www/unitrans/backend-new

# Backup
cp server.js server.js.backup_authapi_$(date +%Y%m%d_%H%M%S)

# إضافة /auth-api route بعد /api/auth
sed -i "/app.use('\/api\/auth',/a app.use('/auth-api', require('./routes/auth-professional')); // For login page compatibility" server.js

echo "✅ تم إضافة route /auth-api"
echo ""

# التحقق
echo "التحقق:"
grep -n "auth" server.js | grep "app.use" | head -5

echo ""
echo "================================================"
echo "إعادة تشغيل Backend..."
echo "================================================"

cd /var/www/unitrans
pm2 restart unitrans-backend
pm2 save

echo ""
echo "انتظار 3 ثوان..."
sleep 3

echo ""
echo "================================================"
echo "اختبار /auth-api/login:"
echo "================================================"

curl -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com","password":"memo123"}' \
  | head -c 300

echo ""
echo ""
echo "================================================"
echo "✅ انتهى!"
echo "================================================"
echo ""
echo "الآن جرب Login في المتصفح!"
echo "  https://unibus.online/login"
echo ""

pm2 list
