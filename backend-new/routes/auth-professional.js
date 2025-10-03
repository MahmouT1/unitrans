const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { MongoClient } = require('mongodb');
require('dotenv').config();

const router = express.Router();

// MongoDB connection config
const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const mongoDbName = process.env.MONGODB_DB_NAME || 'student_portal';
const jwtSecret = process.env.JWT_SECRET || 'unibus-secret-key-2024';

/**
 * Professional Authentication Route
 * Connects directly to production database structure
 * Supports: admin, supervisor, student roles
 */

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
    
    console.log(`✅ Connected to database: ${mongoDbName}`);

    // Find user in production users collection
    const user = await db.collection('users').findOne({ 
      email: email.toLowerCase().trim() 
    });

    if (!user) {
      console.log('❌ Professional Auth: User not found:', email);
      return res.status(401).json({
        success: false,
        message: 'لم يتم العثور على الحساب. يرجى التحقق من البريد الإلكتروني أو إنشاء حساب جديد.',
        code: 'USER_NOT_FOUND'
      });
    }

    console.log(`🔍 Found user: ${user.email} with role: ${user.role}`);

    // Verify password (handle both hashed and plain passwords for compatibility)
    let isValidPassword = false;
    
    if (user.password.startsWith('$2b$') || user.password.startsWith('$2a$')) {
      // Hashed password
      isValidPassword = await bcrypt.compare(password, user.password);
    } else {
      // Plain password (for backward compatibility)
      isValidPassword = (password === user.password);
    }

    if (!isValidPassword) {
      console.log('❌ Professional Auth: Invalid password for:', email);
      return res.status(401).json({
        success: false,
        message: 'كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.',
        code: 'INVALID_PASSWORD'
      });
    }

    // Generate professional JWT token
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

    // Update last login
    await db.collection('users').updateOne(
      { _id: user._id },
      { 
        $set: { 
          lastLogin: new Date(),
          lastLoginIP: req.ip || req.connection.remoteAddress
        }
      }
    );

    console.log('✅ Professional Auth: Login successful for', email, 'with role', user.role);

    // Return comprehensive response
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
  const { email, password, fullName, name, role = 'student' } = req.body;
  let client;

  try {
    console.log('📝 Professional Auth: Registration attempt for', email);

    // Accept both 'fullName' and 'name' for compatibility
    const userName = fullName || name;

    // Input validation
    if (!email || !password || !userName) {
      return res.status(400).json({
        success: false,
        message: 'جميع الحقول مطلوبة (الاسم، البريد الإلكتروني، كلمة المرور)',
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
      fullName: userName.trim(),
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

    // If student role, create student record
    if (role === 'student') {
      const studentData = {
        fullName: userName.trim(),
        email: email.toLowerCase().trim(),
        phoneNumber: '',
        college: '',
        grade: '',
        major: '',
        address: {},
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
        message: 'رمز المصادقة مطلوب',
        code: 'TOKEN_MISSING'
      });
    }

    const decoded = jwt.verify(token, jwtSecret);
    
    // Connect to database to get fresh user data
    const client = new MongoClient(mongoUri);
    await client.connect();
    const db = client.db(mongoDbName);
    
    const user = await db.collection('users').findOne({ 
      _id: decoded.userId 
    });
    
    await client.close();

    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'الحساب غير صالح أو معطل',
        code: 'INVALID_USER'
      });
    }

    res.json({
      success: true,
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        isActive: user.isActive
      },
      permissions: getUserPermissions(user.role)
    });

  } catch (error) {
    console.error('❌ Token verification error:', error);
    res.status(401).json({
      success: false,
      message: 'رمز مصادقة غير صالح',
      code: 'INVALID_TOKEN'
    });
  }
});

// 🔧 Helper Functions
function getUserPermissions(role) {
  const permissions = {
    admin: [
      'dashboard.view',
      'users.manage',
      'students.manage', 
      'attendance.view',
      'reports.generate',
      'system.configure'
    ],
    supervisor: [
      'dashboard.view',
      'attendance.scan',
      'shifts.manage',
      'students.view',
      'reports.view'
    ],
    student: [
      'profile.view',
      'profile.edit',
      'attendance.view',
      'transportation.view',
      'support.create'
    ]
  };
  
  return permissions[role] || permissions.student;
}

function getRoleRedirectUrl(role) {
  const redirects = {
    admin: '/admin/dashboard',
    supervisor: '/admin/supervisor-dashboard', 
    student: '/student/portal'
  };
  
  return redirects[role] || '/student/portal';
}

module.exports = router;
