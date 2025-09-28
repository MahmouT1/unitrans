@echo off
echo ================================================
echo 🚀 نشر التحديثات على سيرفر الدومين
echo ================================================

echo 📥 سحب آخر التحديثات من GitHub...
ssh root@unibus.online "cd /var/www/unitrans && git pull origin main"

echo 📦 تثبيت المكتبات الجديدة...
ssh root@unibus.online "cd /var/www/unitrans/backend-new && npm install qrcode"

echo 🔄 إعادة تشغيل Backend...
ssh root@unibus.online "pm2 restart unitrans-backend"

echo 🔨 بناء Frontend...
ssh root@unibus.online "cd /var/www/unitrans/frontend-new && rm -rf .next && npm run build"

echo 🔄 إعادة تشغيل Frontend...
ssh root@unibus.online "pm2 restart unitrans-frontend"

echo 📊 فحص حالة الخدمات...
ssh root@unibus.online "pm2 status"

echo 🧪 اختبار الـ APIs الجديدة...
ssh root@unibus.online "curl -X GET https://unibus.online:3001/health"

echo ✅ تم نشر جميع التحديثات بنجاح!
echo 🌐 يمكنك الآن اختبار النظام على: https://unibus.online
pause
