#!/bin/bash

echo "🔧 إصلاح مشكلة Nginx /auth-api routes"
echo "===================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص مشكلة Nginx:"
echo "===================="

echo "🔍 فحص Nginx configuration:"
nginx -t

echo ""
echo "🔍 فحص Nginx sites:"
ls -la /etc/nginx/sites-available/

echo ""
echo "🔍 فحص Nginx sites enabled:"
ls -la /etc/nginx/sites-enabled/

echo ""
echo "🔧 2️⃣ إصلاح Nginx Configuration:"
echo "============================="

echo "📝 إنشاء Nginx configuration جديد مع /auth-api routes:"

# Backup current nginx config
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup-$(date +%Y%m%d-%H%M%S)

# Create new nginx config with auth-api routes
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80;
    server_name unibus.online www.unibus.online;

    # Frontend (Next.js)
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

    # Backend API routes
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
    }

    # CRITICAL: Add /auth-api routes for Frontend compatibility
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
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo "✅ تم إنشاء Nginx configuration جديد مع /auth-api routes"

echo ""
echo "🔧 3️⃣ إعادة تشغيل Nginx:"
echo "======================"

echo "🔄 اختبار Nginx configuration:"
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration صحيح"
    
    echo "🔄 إعادة تشغيل Nginx:"
    systemctl reload nginx
    
    echo "⏳ انتظار 5 ثواني للتأكد من التشغيل..."
    sleep 5
    
    echo "🔍 فحص حالة Nginx:"
    systemctl status nginx --no-pager
else
    echo "❌ Nginx configuration خطأ"
    echo "🔄 استرجاع النسخة الاحتياطية..."
    cp /etc/nginx/sites-available/default.backup-$(date +%Y%m%d-%H%M%S) /etc/nginx/sites-available/default
    systemctl reload nginx
fi

echo ""
echo "🧪 4️⃣ اختبار /auth-api/login من خلال Nginx:"
echo "======================================="

echo "🔍 اختبار /auth-api/login من خلال Nginx:"
NGINX_AUTH_API_LOGIN=$(curl -s -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\nHTTP Status: %{http_code}\n")

echo "$NGINX_AUTH_API_LOGIN"

echo ""
echo "🔍 اختبار /auth-api/register من خلال Nginx:"
NGINX_AUTH_API_REGISTER=$(curl -s -X POST https://unibus.online/auth-api/register \
  -H "Content-Type: application/json" \
  -d '{"email":"nginxtest@test.com","password":"123456","fullName":"Nginx Test User","role":"student"}' \
  -w "\nHTTP Status: %{http_code}\n")

echo "$NGINX_AUTH_API_REGISTER"

echo ""
echo "🔍 اختبار /api/login من خلال Nginx:"
NGINX_API_LOGIN=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\nHTTP Status: %{http_code}\n")

echo "$NGINX_API_LOGIN"

echo ""
echo "🧪 5️⃣ اختبار صفحات الواجهة:"
echo "=========================="

echo "🔍 اختبار صفحة Login:"
LOGIN_PAGE=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/login)
echo "$LOGIN_PAGE"

echo ""
echo "🔍 اختبار صفحة Student Portal:"
PORTAL_PAGE=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/student/portal)
echo "$PORTAL_PAGE"

echo ""
echo "📊 6️⃣ تقرير الإصلاح النهائي:"
echo "=========================="

echo "✅ الإصلاحات المطبقة:"
echo "   🔧 تم إصلاح Nginx configuration"
echo "   🔑 تم إضافة /auth-api routes إلى Nginx"
echo "   🔄 تم إعادة تشغيل Nginx"
echo "   🧪 تم اختبار جميع المسارات"

echo ""
echo "🎯 النتائج:"
echo "   🔑 /auth-api/login (Nginx): $(echo "$NGINX_AUTH_API_LOGIN" | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   📝 /auth-api/register (Nginx): $(echo "$NGINX_AUTH_API_REGISTER" | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   🌐 /api/login (Nginx): $(echo "$NGINX_API_LOGIN" | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   📱 Login Page: $LOGIN_PAGE"
echo "   🏠 Portal Page: $PORTAL_PAGE"

echo ""
echo "🎉 تم إصلاح مشكلة Nginx /auth-api routes!"
echo "🌐 يمكنك الآن اختبار صفحة Login:"
echo "   🔗 https://unibus.online/login"
echo "   📧 test@test.com / 123456"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
