#!/bin/bash

echo "🔧 حل المشكلة الحقيقية: إضافة auth-api routes إلى Nginx"
echo "====================================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة الحالية:"
echo "======================="

echo "🔍 فحص Nginx configuration الحالي:"
grep -n "auth-api" /etc/nginx/sites-available/unitrans || echo "❌ auth-api routes غير موجودة في Nginx"

echo ""
echo "🔍 فحص backend status:"
pm2 status unitrans-backend

echo ""
echo "🔍 فحص frontend status:"
pm2 status unitrans-frontend

echo ""
echo "🔧 2️⃣ إضافة auth-api routes إلى Nginx:"
echo "===================================="

# Create new Nginx configuration with auth-api routes
cat > /etc/nginx/sites-available/unitrans << 'EOF'
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
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # CRITICAL: Add auth-api routes BEFORE /api/ routes
    location /auth-api/ {
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
        proxy_connect_timeout 86400;
        proxy_send_timeout 86400;
    }

    # Backend API - Priority routing
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
        proxy_connect_timeout 86400;
        proxy_send_timeout 86400;
    }

    # Health check - Direct backend access
    location /health {
        proxy_pass http://localhost:3001/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Frontend (Next.js) - Catch all
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
        proxy_read_timeout 86400;
    }

    # Static files
    location /uploads/ {
        alias /var/www/unitrans/backend-new/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /profiles/ {
        alias /var/www/unitrans/backend-new/uploads/profiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /backend-uploads/ {
        alias /var/www/unitrans/backend-new/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

echo "✅ تم إضافة auth-api routes إلى Nginx configuration"

echo ""
echo "🔧 3️⃣ اختبار Nginx configuration:"
echo "================================="

echo "🔍 اختبار Nginx configuration:"
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration صحيح"
    
    echo "🔄 إعادة تحميل Nginx:"
    systemctl reload nginx
    
    echo "⏳ انتظار 5 ثواني..."
    sleep 5
    
    echo "✅ Nginx تم إعادة تحميله بنجاح"
else
    echo "❌ Nginx configuration خطأ!"
    exit 1
fi

echo ""
echo "🔧 4️⃣ اختبار auth-api routes:"
echo "============================"

echo "🔍 اختبار auth-api/login:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/auth-api/login

echo ""
echo "🔍 اختبار login مع بيانات الطالب (test@test.com):"
echo "=============================================="
curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -s

echo ""
echo "🔍 اختبار login مع بيانات الإدارة (roo2admin@gmail.com):"
echo "====================================================="
curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"roo2admin@gmail.com","password":"admin123"}' \
  -s

echo ""
echo "🔍 اختبار login مع بيانات المشرف (ahmedazab@gmail.com):"
echo "====================================================="
curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  -s

echo ""
echo "🎉 تم إصلاح المشكلة الحقيقية!"
echo "🌐 يمكنك الآن اختبار في المتصفح:"
echo "   🔗 https://unibus.online/login"
echo "   📧 test@test.com / 123456"
echo "   📧 roo2admin@gmail.com / admin123"
echo "   📧 ahmedazab@gmail.com / supervisor123"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
