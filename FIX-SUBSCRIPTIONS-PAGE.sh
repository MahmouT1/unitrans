#!/bin/bash

echo "🔧 إصلاح Subscriptions Page - استخدام Frontend API"
echo "================================================================"

cd /var/www/unitrans/frontend-new/app/admin/subscriptions

# Backup
cp page.js page.js.backup_$(date +%Y%m%d_%H%M%S)

# Fix Students API call (line 226)
sed -i "s|fetch('http://localhost:3001/api/admin/students?limit=1000')|fetch('/api/students/profile-simple?admin=true')|g" page.js

# Fix Subscriptions API call (line 772)
sed -i "s|fetch('http://localhost:3001/api/admin/subscriptions')|fetch('/api/subscriptions')|g" page.js

# Remove fallback since we're using frontend API directly
sed -i '/Backend not available for subscriptions/,/fetch.*subscription.*payment/d' page.js
sed -i '/Backend not available, trying frontend API/,/fetch.*students.*profile/d' page.js

echo "✅ page.js تم تعديله"

# Rebuild Frontend
cd /var/www/unitrans/frontend-new

echo ""
echo "🔄 Rebuilding Frontend..."

pm2 stop unitrans-frontend
rm -rf .next
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Build نجح"
    cd /var/www/unitrans
    pm2 start "cd frontend-new && npm start" --name unitrans-frontend
else
    echo "⚠️ Build فشل - Dev mode"
    cd /var/www/unitrans
    pm2 start "cd frontend-new && npm run dev" --name unitrans-frontend
fi

pm2 save

sleep 10

echo ""
echo "=============================================="
echo "✅ الآن في المتصفح:"
echo "=============================================="
echo ""
echo "1. أغلق Browser تماماً"
echo "2. Ctrl+Shift+N (Incognito)"
echo "3. unibus.online/admin/subscriptions"
echo "4. Refresh Data"
echo "5. ✅ ali ramy سيظهر!"
echo ""

