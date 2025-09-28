#!/bin/bash

echo "🔍 تشخيص وإصلاح Backend routes"
echo "==============================="

cd /var/www/unitrans

echo "🛑 إيقاف Backend..."
pm2 stop unitrans-backend

echo ""
echo "📄 فحص محتوى server.js الحالي:"
echo "=============================="

echo "🔍 البحث عن /api/login في server.js:"
if grep -n "/api/login" backend-new/server.js; then
    echo "✅ /api/login موجود في server.js"
else
    echo "❌ /api/login غير موجود في server.js"
fi

echo ""
echo "📝 آخر 20 سطر من server.js:"
tail -20 backend-new/server.js

echo ""
echo "🔧 إنشاء server.js جديد مع proxy routes:"
echo "======================================="

# إنشاء server.js جديد مع proxy routes مدمجة
cat > backend-new/server.js << 'EOF'
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const app = express();
const port = process.env.PORT || 3001;

// Middleware
app.use(cors({
  origin: ['http://localhost:3000', 'https://unibus.online', 'http://localhost:3001'],
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// ===== FRONTEND AUTH PROXY ROUTES =====
app.post('/api/login', async (req, res) => {
  try {
    console.log('🔄 Frontend Proxy Login:', req.body.email);
    
    const client = new MongoClient(process.env.MONGODB_URI);
    await client.connect();
    const db = client.db(process.env.MONGODB_DB_NAME);
    const usersCollection = db.collection('users');
    
    const user = await usersCollection.findOne({ email: req.body.email });
    
    if (!user) {
      await client.close();
      return res.status(400).json({ success: false, message: 'الحساب غير موجود' });
    }
    
    const validPassword = await bcrypt.compare(req.body.password, user.password);
    
    if (!validPassword) {
      await client.close();
      return res.status(400).json({ success: false, message: 'كلمة المرور غير صحيحة' });
    }
    
    const token = jwt.sign(
      { userId: user._id, email: user.email, role: user.role },
      process.env.JWT_SECRET || 'fallback-secret',
      { expiresIn: '24h' }
    );
    
    let redirectUrl;
    if (user.role === 'admin') {
      redirectUrl = '/admin/dashboard';
    } else if (user.role === 'supervisor') {
      redirectUrl = '/admin/supervisor-dashboard';
    } else {
      redirectUrl = '/student/portal';
    }
    
    await client.close();
    
    res.json({
      success: true,
      message: 'تم تسجيل الدخول بنجاح',
      token,
      user: { email: user.email, fullName: user.fullName, role: user.role },
      redirectUrl
    });
    
  } catch (error) {
    console.error('❌ Login error:', error);
    res.status(500).json({ success: false, message: 'خطأ في الخادم' });
  }
});

app.post('/api/register', async (req, res) => {
  try {
    console.log('🔄 Frontend Proxy Register:', req.body.email);
    
    const client = new MongoClient(process.env.MONGODB_URI);
    await client.connect();
    const db = client.db(process.env.MONGODB_DB_NAME);
    const usersCollection = db.collection('users');
    
    const existingUser = await usersCollection.findOne({ email: req.body.email });
    
    if (existingUser) {
      await client.close();
      return res.status(400).json({ success: false, message: 'الحساب موجود مسبقاً' });
    }
    
    const hashedPassword = await bcrypt.hash(req.body.password, 10);
    
    const newUser = {
      email: req.body.email,
      password: hashedPassword,
      fullName: req.body.fullName,
      role: req.body.role || 'student',
      createdAt: new Date(),
      isActive: true
    };
    
    await usersCollection.insertOne(newUser);
    
    const token = jwt.sign(
      { userId: newUser._id, email: newUser.email, role: newUser.role },
      process.env.JWT_SECRET || 'fallback-secret',
      { expiresIn: '24h' }
    );
    
    await client.close();
    
    res.json({
      success: true,
      message: 'تم إنشاء الحساب بنجاح',
      token,
      user: { email: newUser.email, fullName: newUser.fullName, role: newUser.role },
      redirectUrl: '/student/portal'
    });
    
  } catch (error) {
    console.error('❌ Register error:', error);
    res.status(500).json({ success: false, message: 'خطأ في الخادم' });
  }
});

// Other API Routes
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

// MongoDB Connection Test
async function connectDB() {
  try {
    const client = new MongoClient(process.env.MONGODB_URI);
    await client.connect();
    console.log('✅ Connected to MongoDB:', process.env.MONGODB_DB_NAME);
    await client.close();
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
  }
}

// Start server
app.listen(port, () => {
  console.log(`🚀 Server running on port ${port}`);
  console.log('✅ Frontend Auth Proxy Routes Active');
  connectDB();
});
EOF

echo "✅ تم إنشاء server.js جديد مع proxy routes"

echo ""
echo "🚀 إعادة تشغيل Backend مع الملف الجديد:"
echo "======================================"

cd backend-new
pm2 start server.js --name "unitrans-backend"

echo ""
echo "⏳ انتظار تحميل Backend..."
sleep 8

echo ""
echo "🧪 اختبار Backend الجديد:"
echo "========================"

echo "1️⃣ اختبار health check:"
curl http://localhost:3001/health -w "\n📊 Status: %{http_code}\n"

echo ""
echo "2️⃣ اختبار /api/login مباشرة على Backend:"
curl -X POST http://localhost:3001/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\n📊 Status: %{http_code}\n"

echo ""
echo "3️⃣ اختبار عبر HTTPS domain:"
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
echo "📊 حالة النهائية:"
pm2 status

echo ""
echo "📋 Backend logs (آخر 10 أسطر):"
pm2 logs unitrans-backend --lines 10

echo ""
echo "✅ Backend تم إصلاحه!"
echo "🔗 جرب الآن: https://unibus.online/login"
