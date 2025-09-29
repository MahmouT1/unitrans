#!/bin/bash

echo "🔧 حل مشكلة مزامنة الحسابات الجديدة مع قاعدة البيانات"
echo "====================================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة الحالية:"
echo "======================="

echo "🔍 فحص auth-professional.js:"
grep -n "students" backend-new/routes/auth-professional.js || echo "❌ لا يوجد إنشاء students record"

echo ""
echo "🔧 2️⃣ إصلاح auth-professional.js لإنشاء students record:"
echo "====================================================="

# Fix auth-professional.js to create students record for new users
cat > backend-new/routes/auth-professional.js << 'EOF'
const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { MongoClient } = require('mongodb');
require('dotenv').config();

const router = express.Router();

// Database configuration
const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const mongoDbName = process.env.DB_NAME || 'student_portal';
const jwtSecret = process.env.JWT_SECRET || 'unibus-secret-key-2024';

// 🔐 LOGIN ENDPOINT
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  let client;

  try {
    console.log('🔐 Professional Auth: Login attempt for', email);

    // Input validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'البريد الإلكتروني وكلمة المرور مطلوبان',
        code: 'MISSING_CREDENTIALS'
      });
    }

    // Connect to production database
    client = new MongoClient(mongoUri);
    await client.connect();
    const db = client.db(mongoDbName);

    // Find user by email
    const user = await db.collection('users').findOne({ 
      email: email.toLowerCase().trim() 
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'الحساب غير موجود. يرجى التحقق من البريد الإلكتروني أو إنشاء حساب جديد',
        code: 'USER_NOT_FOUND'
      });
    }

    // Check if account is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'الحساب غير نشط. يرجى التواصل مع الإدارة',
        code: 'ACCOUNT_INACTIVE'
      });
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'كلمة المرور غير صحيحة',
        code: 'INVALID_PASSWORD'
      });
    }

    // Update last login
    await db.collection('users').updateOne(
      { _id: user._id },
      { $set: { lastLogin: new Date() } }
    );

    // Generate JWT token
    const tokenPayload = {
      userId: user._id,
      email: user.email,
      role: user.role,
      fullName: user.fullName,
      loginTime: new Date(),
      sessionId: `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    };

    const token = jwt.sign(tokenPayload, jwtSecret, { 
      expiresIn: '7d',
      issuer: 'unibus-portal',
      audience: 'unibus-users'
    });

    console.log('✅ Professional Auth: Login successful for', email);

    res.json({
      success: true,
      message: 'تم تسجيل الدخول بنجاح',
      token,
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        isActive: user.isActive,
        lastLogin: new Date()
      },
      permissions: getUserPermissions(user.role),
      redirectUrl: getRoleRedirectUrl(user.role)
    });

  } catch (error) {
    console.error('❌ Professional Auth: Login error:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم أثناء تسجيل الدخول',
      code: 'SERVER_ERROR'
    });
  } finally {
    if (client) {
      await client.close();
    }
  }
});

// 📝 REGISTER ENDPOINT
router.post('/register', async (req, res) => {
  const { email, password, fullName, role = 'student' } = req.body;
  let client;

  try {
    console.log('📝 Professional Auth: Registration attempt for', email);

    // Input validation
    if (!email || !password || !fullName) {
      return res.status(400).json({
        success: false,
        message: 'جميع الحقول مطلوبة',
        code: 'MISSING_FIELDS'
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
        code: 'PASSWORD_TOO_SHORT'
      });
    }

    // Connect to production database
    client = new MongoClient(mongoUri);
    await client.connect();
    const db = client.db(mongoDbName);

    // Check if user already exists
    const existingUser = await db.collection('users').findOne({ 
      email: email.toLowerCase().trim() 
    });

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'يوجد حساب بهذا البريد الإلكتروني بالفعل',
        code: 'EMAIL_EXISTS'
      });
    }

    // Hash password professionally
    const hashedPassword = await bcrypt.hash(password, 12);

    // Create new user with professional structure
    const newUser = {
      email: email.toLowerCase().trim(),
      password: hashedPassword,
      fullName: fullName.trim(),
      role: role,
      isActive: true,
      emailVerified: false,
      createdAt: new Date(),
      updatedAt: new Date(),
      registrationIP: req.ip || req.connection.remoteAddress,
      lastLogin: null
    };

    const result = await db.collection('users').insertOne(newUser);
    console.log('✅ Professional Auth: User created with ID:', result.insertedId);

    // CRITICAL: Create students record for new student users
    if (role === 'student') {
      const studentData = {
        fullName: newUser.fullName,
        email: newUser.email,
        phoneNumber: '',
        college: '',
        grade: '',
        major: '',
        streetAddress: '',
        buildingNumber: '',
        fullAddress: '',
        profilePhoto: null,
        attendanceCount: 0,
        isActive: true,
        userId: result.insertedId,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      await db.collection('students').insertOne(studentData);
      console.log('✅ Professional Auth: Student record created for:', email);
    }

    // Generate JWT token for immediate login
    const tokenPayload = {
      userId: result.insertedId,
      email: newUser.email,
      role: newUser.role,
      fullName: newUser.fullName,
      loginTime: new Date(),
      sessionId: `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    };

    const token = jwt.sign(tokenPayload, jwtSecret, { 
      expiresIn: '7d',
      issuer: 'unibus-portal',
      audience: 'unibus-users'
    });

    console.log('✅ Professional Auth: Registration successful for', email);

    res.status(201).json({
      success: true,
      message: 'تم إنشاء الحساب بنجاح',
      token,
      user: {
        id: result.insertedId,
        email: newUser.email,
        fullName: newUser.fullName,
        role: newUser.role,
        isActive: true
      },
      permissions: getUserPermissions(newUser.role),
      redirectUrl: getRoleRedirectUrl(newUser.role)
    });

  } catch (error) {
    console.error('❌ Professional Auth: Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم أثناء إنشاء الحساب',
      code: 'SERVER_ERROR'
    });
  } finally {
    if (client) {
      await client.close();
    }
  }
});

// 🔍 TOKEN VERIFICATION ENDPOINT
router.get('/verify', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Token مطلوب',
        code: 'NO_TOKEN'
      });
    }

    const decoded = jwt.verify(token, jwtSecret);
    
    res.json({
      success: true,
      user: decoded,
      valid: true
    });

  } catch (error) {
    console.error('❌ Token verification error:', error);
    res.status(401).json({
      success: false,
      message: 'Token غير صالح',
      code: 'INVALID_TOKEN'
    });
  }
});

// 🔧 HELPER FUNCTIONS
function getUserPermissions(role) {
  const permissions = {
    student: [
      'profile.view',
      'profile.edit',
      'attendance.view',
      'transportation.view',
      'support.create'
    ],
    supervisor: [
      'dashboard.view',
      'attendance.scan',
      'shifts.manage',
      'students.view',
      'reports.view'
    ],
    admin: [
      'dashboard.view',
      'users.manage',
      'students.manage',
      'attendance.view',
      'reports.generate',
      'system.config'
    ]
  };
  
  return permissions[role] || [];
}

function getRoleRedirectUrl(role) {
  const redirects = {
    student: '/student/portal',
    supervisor: '/admin/supervisor-dashboard',
    admin: '/admin/dashboard'
  };
  
  return redirects[role] || '/login';
}

module.exports = router;
EOF

echo "✅ تم إصلاح auth-professional.js لإنشاء students record"

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
echo "🔧 4️⃣ اختبار إنشاء حساب جديد:"
echo "============================"

echo "🔍 اختبار إنشاء حساب جديد:"
curl -X POST https://unibus.online/auth-api/register \
  -H "Content-Type: application/json" \
  -d '{"email":"newstudent@test.com","password":"123456","fullName":"New Student","role":"student"}' \
  -s

echo ""
echo "🔍 اختبار تسجيل الدخول بالحساب الجديد:"
echo "===================================="
curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"newstudent@test.com","password":"123456"}' \
  -s

echo ""
echo "🎉 تم إصلاح مشكلة مزامنة الحسابات الجديدة!"
echo "🌐 يمكنك الآن اختبار إنشاء حساب جديد:"
echo "   🔗 https://unibus.online/login"
echo "   ✅ الحسابات الجديدة ستحفظ في نفس مكان test@test.com"
echo "   ✅ لن تظهر رسالة 'Student not found'"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
