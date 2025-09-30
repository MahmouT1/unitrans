#!/bin/bash

echo "🔧 إضافة Redirect من /auth إلى /login في Nginx"
echo "=============================================="

# Backup nginx config
cp /etc/nginx/sites-available/unitrans /etc/nginx/sites-available/unitrans.backup

# Add redirect before location / block
sed -i '/location \/ {/i \    # Redirect /auth to /login\n    location = /auth {\n        return 301 /login;\n    }\n' /etc/nginx/sites-available/unitrans

# Test nginx config
echo "🔍 فحص Nginx config..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx config صحيح!"
    
    # Reload nginx
    echo "🔄 إعادة تحميل Nginx..."
    systemctl reload nginx
    
    echo "✅ تم إضافة Redirect من /auth إلى /login!"
else
    echo "❌ Nginx config به خطأ!"
    echo "🔄 استعادة النسخة الاحتياطية..."
    cp /etc/nginx/sites-available/unitrans.backup /etc/nginx/sites-available/unitrans
fi

echo ""
echo "🧪 اختبار Redirect:"
curl -I https://unibus.online/auth 2>&1 | grep -E "HTTP|Location"

echo ""
echo "✅ تم!"
