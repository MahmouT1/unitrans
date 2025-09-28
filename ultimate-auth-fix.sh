#!/bin/bash

echo "🚀 الحل النهائي لمشكلة Auth"
echo "==========================="

cd /var/www/unitrans

echo "📥 سحب آخر التحديثات..."
git pull origin main

echo ""
echo "🛑 إيقاف الخدمات..."
pm2 stop unitrans-frontend
pm2 stop unitrans-backend

echo ""
echo "🔧 إضافة proxy routes مباشرة في Backend server.js:"
echo "=================================================="

# إضافة proxy routes مباشرة في server.js
cat >> backend-new/server.js << 'EOF'

// ===== PROXY ROUTES FOR FRONTEND AUTH =====
// These routes solve the CSP issues by handling auth directly in backend

app.post('/api/login', async (req, res) => {
  try {
    console.log('🔄 Frontend Proxy Login Request:', req.body.email);
    
    // Forward to our professional auth system
    const authResponse = await fetch('http://localhost:3001/api/auth-pro/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(req.body)
    });

    const data = await authResponse.json();
    console.log('📡 Auth Response:', data.success);
    
    res.status(authResponse.status).json(data);
  } catch (error) {
    console.error('❌ Proxy login error:', error);
    res.status(500).json({ success: false, message: 'Connection error' });
  }
});

app.post('/api/register', async (req, res) => {
  try {
    console.log('🔄 Frontend Proxy Register Request:', req.body.email);
    
    // Forward to our professional auth system
    const authResponse = await fetch('http://localhost:3001/api/auth-pro/register', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(req.body)
    });

    const data = await authResponse.json();
    console.log('📡 Register Response:', data.success);
    
    res.status(authResponse.status).json(data);
  } catch (error) {
    console.error('❌ Proxy register error:', error);
    res.status(500).json({ success: false, message: 'Connection error' });
  }
});

console.log('✅ Frontend Auth Proxy Routes Added');
EOF

echo "✅ تم إضافة proxy routes في server.js"

echo ""
echo "🔧 تحديث Nginx لتوجيه /api للـ Backend:"
echo "======================================="

# إنشاء تحديث Nginx config
cat > nginx-auth-update.conf << 'EOF'
# إضافة هذا في الـ server block الخاص بـ unibus.online

# توجيه جميع /api routes للـ Backend
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

# باقي المحتوى للـ Frontend
location / {
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
}
EOF

echo "📄 تم إنشاء ملف nginx-auth-update.conf"
echo "ℹ️ يجب إضافة محتواه لـ /etc/nginx/sites-available/default"

echo ""
echo "🏗️ إعادة بناء Frontend (بدون Next.js API routes):"
echo "=============================================="

cd frontend-new

# حذف Next.js API routes (سنستخدم Backend proxy)
rm -rf app/api/login app/api/register

# حذف cache
rm -rf .next
rm -rf node_modules/.cache

# بناء جديد
npm run build

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ Frontend بُني بنجاح بدون API routes"
else
    echo "❌ فشل بناء Frontend"
    exit 1
fi

echo ""
echo "🚀 إعادة تشغيل الخدمات:"
echo "======================"

# تشغيل Backend أولاً (يحتوي على proxy routes الآن)
pm2 start unitrans-backend

# انتظار استقرار Backend
sleep 5

# تشغيل Frontend
pm2 start unitrans-frontend

# انتظار استقرار النظام
sleep 8

echo ""
echo "🧪 اختبار النظام الجديد:"
echo "======================="

echo "1️⃣ اختبار Backend proxy (port 3001):"
curl -X POST http://localhost:3001/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\n📊 Status: %{http_code}\n"

echo ""
echo "2️⃣ اختبار Frontend (port 3000):"
curl -I http://localhost:3000/login -w "\n📊 Status: %{http_code}\n"

echo ""
echo "3️⃣ اختبار HTTPS domain:"
curl -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\n📊 Status: %{http_code}\n"

echo ""
echo "4️⃣ اختبار Admin login:"
curl -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"roo2admin@gmail.com","password":"admin123"}' \
  -w "\n📊 Status: %{http_code}\n"

echo ""
echo "📊 حالة الخدمات:"
pm2 status

echo ""
echo "🎯 تعليمات النشر النهائي:"
echo "========================"
echo "1. تحديث Nginx config:"
echo "   sudo nano /etc/nginx/sites-available/default"
echo "   (أضف محتوى nginx-auth-update.conf)"
echo ""
echo "2. إعادة تشغيل Nginx:"
echo "   sudo nginx -t && sudo systemctl reload nginx"
echo ""
echo "3. اختبار النظام:"
echo "   https://unibus.online/login"

echo ""
echo "✅ الحل النهائي اكتمل!"
echo "🔗 جرب: https://unibus.online/login"
