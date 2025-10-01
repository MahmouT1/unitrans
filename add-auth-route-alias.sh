#!/bin/bash

echo "➕ إضافة route /api/auth كـ alias لـ /api/auth-pro"
echo "=================================================="
echo ""

cd /var/www/unitrans/backend-new

# Backup
cp server.js server.js.backup_auth_$(date +%Y%m%d_%H%M%S)

echo "✅ تم حفظ نسخة احتياطية"
echo ""

# إضافة السطر بعد auth-pro
# نبحث عن السطر الذي فيه auth-pro ونضيف بعده
sed -i "/app.use('\/api\/auth-pro'/a app.use('/api/auth', require('./routes/auth-professional')); // Alias for compatibility" server.js

echo "✅ تم إضافة route /api/auth"
echo ""

# التحقق
echo "التحقق:"
grep -n "app.use.*auth" server.js | head -5

echo ""
echo "=================================================="
echo "إعادة تشغيل Backend..."
echo "=================================================="

cd /var/www/unitrans
pm2 restart unitrans-backend
pm2 save

echo ""
echo "انتظار 3 ثوان..."
sleep 3

echo ""
echo "=================================================="
echo "اختبار /api/auth/login:"
echo "=================================================="

curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com","password":"memo123"}' \
  | head -c 200

echo ""
echo ""
echo "=================================================="
echo "✅ انتهى!"
echo "=================================================="
echo ""
echo "الآن جرب Login في المتصفح!"
echo ""

pm2 list
