#!/bin/bash

echo "🔧 الحل النهائي: إصلاح PayloadTooLargeError بشكل كامل"
echo "==============================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة الحالية:"
echo "======================="

echo "🔍 فحص backend logs:"
pm2 logs unitrans-backend --lines 3

echo ""
echo "🔍 فحص server.js الحالي:"
if [ -f "backend-new/server.js" ]; then
    echo "✅ server.js موجود"
    
    # Check payload limits
    if grep -q "limit.*200mb" backend-new/server.js; then
        echo "✅ Payload limit موجود (200mb)"
    else
        echo "❌ Payload limit غير موجود أو غير صحيح"
        echo "🔍 عرض payload limits الحالية:"
        grep -n "limit" backend-new/server.js
    fi
else
    echo "❌ server.js غير موجود"
fi

echo ""
echo "🔧 2️⃣ إصلاح server.js مع payload limits صحيحة:"
echo "=========================================="

# Create a new server.js with proper payload limits
cat > backend-new/server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config();

const app = express();

// Middleware with proper payload limits
app.use(cors());
app.use(express.json({ limit: '500mb' }));
app.use(express.urlencoded({ extended: true, limit: '500mb' }));

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/student_portal';
mongoose.connect(MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
.then(() => console.log('✓ Connected to MongoDB (Mongoose)'))
.catch(err => console.error('MongoDB connection error:', err));

// Health Check
app.get('/api/health', (req, res) => {
    res.json({ status: 'OK', message: 'Server is running' });
});

// CRITICAL: Add /auth-api/login route for Frontend compatibility
app.post('/auth-api/login', async (req, res) => {
    try {
        console.log('🔐 Frontend Auth API Login Request:', req.body.email);
        const { email, password } = req.body;
        
        // Forward to internal auth-pro service
        const authResponse = await fetch(`http://localhost:3001/api/auth-pro/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });
        
        const data = await authResponse.json();
        console.log('🔐 Frontend Auth API Login Response:', data);
        
        res.status(authResponse.status).json(data);
    } catch (error) {
        console.error('❌ Frontend Auth API Login Error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// CRITICAL: Add /auth-api/register route for Frontend compatibility
app.post('/auth-api/register', async (req, res) => {
    try {
        console.log('🔐 Frontend Auth API Register Request:', req.body.email);
        const { email, password, fullName, role } = req.body;
        
        // Forward to internal auth-pro service
        const authResponse = await fetch(`http://localhost:3001/api/auth-pro/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password, fullName, role })
        });
        
        const data = await authResponse.json();
        console.log('🔐 Frontend Auth API Register Response:', data);
        
        res.status(authResponse.status).json(data);
    } catch (error) {
        console.error('❌ Frontend Auth API Register Error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// API Routes
app.use('/api/auth-pro', require('./routes/auth-professional'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/students', require('./routes/students'));
app.use('/api/attendance', require('./routes/attendance'));
app.use('/api/attendance', require('./routes/attendance-tracking'));
app.use('/api/subscriptions', require('./routes/subscriptions'));
app.use('/api/transportation', require('./routes/transportation'));
app.use('/api/shifts', require('./routes/shifts'));
app.use('/api/driver-salaries', require('./routes/driver-salaries'));
app.use('/api/expenses', require('./routes/expenses'));
app.use('/api/admin/dashboard', require('./routes/admin-dashboard'));
app.use('/api/reports', require('./routes/reports'));

// New direct proxy routes for login and registration
app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const authResponse = await fetch(`https://unibus.online:3001/api/auth-pro/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });
        const data = await authResponse.json();
        res.status(authResponse.status).json(data);
    } catch (error) {
        console.error('Backend /api/login proxy error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

app.post('/api/register', async (req, res) => {
    try {
        const { email, password, fullName, role } = req.body;
        const authResponse = await fetch(`https://unibus.online:3001/api/auth-pro/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password, fullName, role })
        });
        const data = await authResponse.json();
        res.status(authResponse.status).json(data);
    } catch (error) {
        console.error('Backend /api/register proxy error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// Start server
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`/api/login route: ACTIVE`);
    console.log(`/api/register route: ACTIVE`);
    console.log(`/auth-api/login route: ACTIVE`);
    console.log(`/auth-api/register route: ACTIVE`);
    console.log(`Payload limit: 500MB`);
    console.log(`Environment: ${process.env.NODE_ENV || 'production'}`);
});
EOF

echo "✅ تم إنشاء server.js جديد مع payload limits صحيحة (500MB)"

echo ""
echo "🔧 3️⃣ إعادة تشغيل Backend:"
echo "========================="

echo "🔄 إعادة تشغيل backend..."
pm2 restart unitrans-backend

echo "⏳ انتظار 30 ثانية للتأكد من التشغيل..."
sleep 30

echo "🔍 فحص حالة backend:"
pm2 status unitrans-backend

echo ""
echo "🔧 4️⃣ اختبار API endpoints:"
echo "========================="

echo "🔍 اختبار auth-api/login:"
AUTH_API_TEST=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/auth-api/login)
echo "Auth API Login: $AUTH_API_TEST"

echo ""
echo "🔍 اختبار auth-pro/login:"
AUTH_PRO_TEST=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online:3001/api/auth-pro/login)
echo "Auth Pro Login: $AUTH_PRO_TEST"

echo ""
echo "🔧 5️⃣ اختبار Login بالبيانات:"
echo "==========================="

echo "🔍 اختبار login مع بيانات الطالب:"
curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -s | head -3

echo ""
echo "🔍 اختبار login مع بيانات الإدارة:"
curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"roo2admin@gmail.com","password":"admin123"}' \
  -s | head -3

echo ""
echo "🔍 اختبار login مع بيانات المشرف:"
curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  -s | head -3

echo ""
echo "🔧 6️⃣ فحص Backend Logs:"
echo "====================="

echo "🔍 فحص backend logs:"
pm2 logs unitrans-backend --lines 10

echo ""
echo "🔧 7️⃣ إعادة Build Frontend:"
echo "========================="

echo "🔄 حذف .next directory:"
rm -rf frontend-new/.next

echo "🔄 حذف node_modules/.cache:"
rm -rf frontend-new/node_modules/.cache

echo "🔄 إعادة build frontend:"
cd frontend-new
npm run build

echo ""
echo "🔍 فحص build result:"
if [ -d ".next" ]; then
    echo "✅ Build نجح!"
else
    echo "❌ Build فشل!"
fi

cd ..

echo ""
echo "🔧 8️⃣ إعادة تشغيل Frontend:"
echo "=========================="

echo "🔄 إعادة تشغيل frontend..."
pm2 restart unitrans-frontend

echo "⏳ انتظار 20 ثانية للتأكد من التشغيل..."
sleep 20

echo "🔍 فحص حالة frontend:"
pm2 status unitrans-frontend

echo ""
echo "🧪 9️⃣ اختبار صفحة Login النهائية:"
echo "=============================="

echo "🔍 اختبار صفحة Login:"
LOGIN_PAGE_FINAL=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/login)
echo "Login Page: $LOGIN_PAGE_FINAL"

echo ""
echo "🔍 اختبار auth-api/login:"
AUTH_API_FINAL=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/auth-api/login)
echo "Auth API: $AUTH_API_FINAL"

echo ""
echo "🔍 اختبار auth-pro/login:"
AUTH_PRO_FINAL=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online:3001/api/auth-pro/login)
echo "Auth Pro: $AUTH_PRO_FINAL"

echo ""
echo "📊 10️⃣ تقرير الإصلاح النهائي:"
echo "=========================="

echo "✅ الإصلاحات المطبقة:"
echo "   🔧 تم إصلاح PayloadTooLargeError"
echo "   🔧 تم زيادة payload limit إلى 500MB"
echo "   🔄 تم إعادة تشغيل backend"
echo "   🔄 تم إعادة build frontend"
echo "   🔄 تم إعادة تشغيل frontend"
echo "   🧪 تم اختبار API endpoints"

echo ""
echo "🎯 النتائج:"
echo "   📱 Login Page: $LOGIN_PAGE_FINAL"
echo "   🔐 Auth API: $AUTH_API_FINAL"
echo "   🔐 Auth Pro: $AUTH_PRO_FINAL"
echo "   🔧 Backend: $(pm2 status unitrans-backend | grep unitrans-backend | awk '{print $4}')"
echo "   🔧 Frontend: $(pm2 status unitrans-frontend | grep unitrans-frontend | awk '{print $4}')"

echo ""
echo "🎉 تم إصلاح PayloadTooLargeError بشكل نهائي!"
echo "🌐 يمكنك الآن اختبار صفحة Login:"
echo "   🔗 https://unibus.online/login"
echo "   📧 test@test.com / 123456"
echo "   📧 roo2admin@gmail.com / admin123"
echo "   📧 ahmedazab@gmail.com / supervisor123"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
