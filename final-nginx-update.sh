#!/bin/bash

echo "🔧 التحديث النهائي لـ Nginx"
echo "=========================="

echo "📄 عرض محتوى nginx config الحالي:"
cat /etc/nginx/sites-available/default

echo ""
echo "📝 إنشاء backup للـ config:"
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup.$(date +%Y%m%d_%H%M%S)

echo ""
echo "🔧 تحديث Nginx config:"
echo "======================"

# إنشاء nginx config جديد محدث
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80;
    server_name unibus.online www.unibus.online;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name unibus.online www.unibus.online;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/unibus.online/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/unibus.online/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # API Routes → Backend (Port 3001)
    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }

    # Frontend Routes → Frontend (Port 3000)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

echo "✅ تم تحديث Nginx config"

echo ""
echo "🧪 اختبار Nginx config:"
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx config صحيح"
    
    echo ""
    echo "🔄 إعادة تحميل Nginx:"
    systemctl reload nginx
    
    echo "✅ تم إعادة تحميل Nginx"
    
    echo ""
    echo "⏳ انتظار استقرار النظام..."
    sleep 5
    
    echo ""
    echo "🧪 اختبار نهائي بعد تحديث Nginx:"
    echo "================================="
    
    echo "1️⃣ اختبار صفحة /login:"
    curl -I https://unibus.online/login -w "\n📊 Status: %{http_code}\n"
    
    echo ""
    echo "2️⃣ اختبار Student login:"
    curl -X POST https://unibus.online/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"test@test.com","password":"123456"}' \
      -w "\n📊 Status: %{http_code}\n"
    
    echo ""
    echo "3️⃣ اختبار Admin login:"
    curl -X POST https://unibus.online/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"roo2admin@gmail.com","password":"admin123"}' \
      -w "\n📊 Status: %{http_code}\n"
    
    echo ""
    echo "4️⃣ اختبار Supervisor login:"
    curl -X POST https://unibus.online/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
      -w "\n📊 Status: %{http_code}\n"
    
    echo ""
    echo "5️⃣ اختبار Registration:"
    NEW_EMAIL="finaltest$(date +%s)@test.com"
    curl -X POST https://unibus.online/api/register \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"$NEW_EMAIL\",\"password\":\"123456\",\"fullName\":\"Final Test User\"}" \
      -w "\n📊 Status: %{http_code}\n"
    
else
    echo "❌ Nginx config به خطأ!"
    echo "🔍 مراجعة الأخطاء:"
    nginx -t
fi

echo ""
echo "📊 حالة الخدمات النهائية:"
pm2 status

echo ""
echo "✅ التحديث النهائي اكتمل!"
echo "🔗 جرب الآن: https://unibus.online/login"
echo ""
echo "🔐 الحسابات الجاهزة:"
echo "==================="
echo "👨‍💼 Admin:      roo2admin@gmail.com / admin123"
echo "👨‍🏫 Supervisor: ahmedazab@gmail.com / supervisor123"
echo "👨‍🎓 Student:    test@test.com / 123456"
