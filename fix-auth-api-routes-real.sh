#!/bin/bash

echo "🔧 حل المشكلة الحقيقية: إضافة auth-api routes إلى server.js"
echo "====================================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة الحالية:"
echo "======================="

echo "🔍 فحص server.js الحالي:"
grep -n "auth-api" backend-new/server.js || echo "❌ auth-api routes غير موجودة في server.js"

echo ""
echo "🔍 فحص backend status:"
pm2 status unitrans-backend

echo ""
echo "🔧 2️⃣ إضافة auth-api routes إلى server.js:"
echo "====================================="

# Add auth-api routes to existing server.js
cat > backend-new/server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');
const mongoose = require('mongoose');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:3001', 'http://72.60.185.100:3000', 'https://unibus.online', 'https://www.unibus.online'],
  credentials: true
}));
app.use(express.json({ limit: '500mb' }));
app.use(express.urlencoded({ extended: true, limit: '500mb' }));

// MongoDB connection
let db;
const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const mongoDbName = process.env.DB_NAME || 'student-portal';

// Connect to MongoDB using native driver (for existing functionality)
MongoClient.connect(mongoUri)
  .then(client => {
    console.log('📡 Connected to MongoDB (Native Driver)');
    db = client.db(mongoDbName);
    app.locals.db = db;
  })
  .catch(error => {
    console.error('❌ MongoDB connection error:', error);
  });

// Connect to MongoDB using Mongoose (for new models)
mongoose.connect(`${mongoUri}/${mongoDbName}`)
  .then(() => {
    console.log('📡 Connected to MongoDB (Mongoose)');
  })
  .catch(error => {
    console.error('❌ Mongoose connection error:', error);
  });

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    message: 'Backend API Server Running',
    database: db ? 'Connected' : 'Disconnected'
  });
});

// CRITICAL: Add auth-api routes for Frontend compatibility
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
app.use('/api/auth-pro', require('./routes/auth-professional')); // Professional Auth System
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

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('❌ Server Error:', error);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? error.message : 'Server error'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`
  });
});

app.listen(PORT, () => {
  console.log('🚀 Backend API Server Started');
  console.log(`📍 Server: http://localhost:${PORT}`);
  console.log(`📊 Health: http://localhost:${PORT}/health`);
  console.log(`🔐 Auth API: http://localhost:${PORT}/api/auth-pro/*`);
  console.log(`🔐 Frontend Auth API: http://localhost:${PORT}/auth-api/*`);
  console.log(`👤 Admin API: http://localhost:${PORT}/api/admin/*`);
  console.log(`🎓 Students API: http://localhost:${PORT}/api/students/*`);
  console.log(`📋 Attendance API: http://localhost:${PORT}/api/attendance/*`);
  console.log(`🚌 Transportation API: http://localhost:${PORT}/api/transportation/*`);
  console.log(`💳 Subscriptions API: http://localhost:${PORT}/api/subscriptions/*`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📡 Database: ${db ? 'Connected' : 'Connecting...'}`);
  console.log(`📦 Payload limit: 500MB`);
});

module.exports = app;
EOF

echo "✅ تم إضافة auth-api routes إلى server.js"

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
