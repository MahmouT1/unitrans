#!/bin/bash

echo "🔧 إصلاح سريع لـ Supervisor"
echo "=============================="

cd /var/www/unitrans/frontend-new/app/admin/supervisor-dashboard

cp page.js page.js.bak

# إصلاح السطر 1788
sed -i "1788s/.*/            animation: 'slideInRight 0.3s ease-out',/" page.js

# تقليل notification duration
sed -i 's/duration = 5000/duration = 2000/g' page.js

echo "✅ تم التعديل"

# Build
cd /var/www/unitrans/frontend-new
rm -rf .next
npm run build

# Restart
cd /var/www/unitrans
pm2 restart unitrans-frontend
pm2 save

echo ""
echo "✅ تم!"
echo "في المتصفح:"
echo "1. Ctrl+Shift+R"
echo "2. افتح Shift أولاً!"
echo "3. ثم امسح QR"
