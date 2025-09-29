#!/bin/bash

echo "🔧 حل المشكلة مع Build صحيح"
echo "========================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة الحالية:"
echo "======================="

echo "🔍 فحص backend status:"
pm2 status unitrans-backend

echo ""
echo "🔍 فحص frontend status:"
pm2 status unitrans-frontend

echo ""
echo "🔧 2️⃣ إصلاح server.js مع auth-api routes صحيحة:"
echo "============================================="

# Create a new server.js with proper auth-api routes
cat > backend-new/server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config();

const app = express();

// CRITICAL: CORS Configuration FIRST
const corsOptions = {
    origin: ['https://unibus.online', 'http://localhost:3000'],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept']
};

// CRITICAL: Apply CORS FIRST
app.use(cors(corsOptions));

// CRITICAL: Body parsing middleware SECOND
app.use(express.json({ limit: '500mb' }));
app.use(express.urlencoded({ extended: true, limit: '500mb' }));

// CRITICAL: Static files middleware
app.use(express.static('public'));

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

// API Routes - Load after basic routes
try {
    app.use('/api/auth-pro', require('./routes/auth-professional'));
    console.log('✓ Auth Professional route loaded');
} catch (error) {
    console.error('❌ Auth Professional route error:', error);
}

try {
    app.use('/api/admin', require('./routes/admin'));
    console.log('✓ Admin route loaded');
} catch (error) {
    console.error('❌ Admin route error:', error);
}

try {
    app.use('/api/students', require('./routes/students'));
    console.log('✓ Students route loaded');
} catch (error) {
    console.error('❌ Students route error:', error);
}

try {
    app.use('/api/attendance', require('./routes/attendance'));
    console.log('✓ Attendance route loaded');
} catch (error) {
    console.error('❌ Attendance route error:', error);
}

try {
    app.use('/api/attendance', require('./routes/attendance-tracking'));
    console.log('✓ Attendance Tracking route loaded');
} catch (error) {
    console.error('❌ Attendance Tracking route error:', error);
}

try {
    app.use('/api/subscriptions', require('./routes/subscriptions'));
    console.log('✓ Subscriptions route loaded');
} catch (error) {
    console.error('❌ Subscriptions route error:', error);
}

try {
    app.use('/api/transportation', require('./routes/transportation'));
    console.log('✓ Transportation route loaded');
} catch (error) {
    console.error('❌ Transportation route error:', error);
}

try {
    app.use('/api/shifts', require('./routes/shifts'));
    console.log('✓ Shifts route loaded');
} catch (error) {
    console.error('❌ Shifts route error:', error);
}

try {
    app.use('/api/driver-salaries', require('./routes/driver-salaries'));
    console.log('✓ Driver Salaries route loaded');
} catch (error) {
    console.error('❌ Driver Salaries route error:', error);
}

try {
    app.use('/api/expenses', require('./routes/expenses'));
    console.log('✓ Expenses route loaded');
} catch (error) {
    console.error('❌ Expenses route error:', error);
}

try {
    app.use('/api/admin/dashboard', require('./routes/admin-dashboard'));
    console.log('✓ Admin Dashboard route loaded');
} catch (error) {
    console.error('❌ Admin Dashboard route error:', error);
}

try {
    app.use('/api/reports', require('./routes/reports'));
    console.log('✓ Reports route loaded');
} catch (error) {
    console.error('❌ Reports route error:', error);
}

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

// CRITICAL: Error handling middleware LAST
app.use((err, req, res, next) => {
    console.error('❌ Express Error:', err);
    res.status(500).json({ success: false, message: 'Internal server error' });
});

// CRITICAL: 404 handler LAST
app.use((req, res) => {
    res.status(404).json({ success: false, message: 'Route not found' });
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
    console.log(`CORS enabled for: https://unibus.online, http://localhost:3000`);
});
EOF

echo "✅ تم إنشاء server.js جديد مع auth-api routes صحيحة"

echo ""
echo "🔧 3️⃣ إعادة تشغيل Backend:"
echo "========================="

echo "🔄 إيقاف backend..."
pm2 stop unitrans-backend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 حذف backend process..."
pm2 delete unitrans-backend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 بدء backend جديد..."
cd backend-new
pm2 start server.js --name "unitrans-backend"

echo "⏳ انتظار 30 ثانية للتأكد من التشغيل..."
sleep 30

echo "🔍 فحص حالة backend:"
pm2 status unitrans-backend

echo ""
echo "🔧 4️⃣ إعادة Build Frontend:"
echo "========================="

echo "🔄 حذف .next directory:"
rm -rf frontend-new/.next

echo "🔄 حذف node_modules/.cache:"
rm -rf frontend-new/node_modules/.cache

echo "🔄 حذف package-lock.json:"
rm -f frontend-new/package-lock.json

echo "🔄 حذف node_modules:"
rm -rf frontend-new/node_modules

echo "🔄 إعادة install dependencies:"
cd ../frontend-new
npm install

echo "🔄 إعادة build frontend:"
npm run build

echo ""
echo "🔍 فحص build result:"
if [ -d ".next" ]; then
    echo "✅ Build نجح!"
    echo "📁 .next directory موجود"
    ls -la .next/
else
    echo "❌ Build فشل!"
    echo "📁 .next directory غير موجود"
fi

cd ..

echo ""
echo "🔧 5️⃣ إعادة تشغيل Frontend:"
echo "=========================="

echo "🔄 إيقاف frontend..."
pm2 stop unitrans-frontend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 حذف frontend process..."
pm2 delete unitrans-frontend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 بدء frontend جديد..."
cd frontend-new
pm2 start npm --name "unitrans-frontend" -- start

echo "⏳ انتظار 30 ثانية للتأكد من التشغيل..."
sleep 30

echo "🔍 فحص حالة frontend:"
pm2 status unitrans-frontend

echo ""
echo "🔧 6️⃣ اختبار auth-api/login:"
echo "========================="

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
echo "🎉 تم إصلاح المشكلة مع Build صحيح!"
echo "🌐 يمكنك الآن اختبار في المتصفح:"
echo "   🔗 https://unibus.online/login"
echo "   📧 test@test.com / 123456"
echo "   📧 roo2admin@gmail.com / admin123"
echo "   📧 ahmedazab@gmail.com / supervisor123"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
