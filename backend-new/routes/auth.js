const express = require('express');
const router = express.Router();
const connectDB = require('../config/database');

// Login route
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    console.log('🔍 Login attempt:', email);
    
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    const db = await connectDB();
    
    // البحث في users collection أولاً
    let user = await db.collection('users').findOne({ 
      email: email.toLowerCase() 
    });

    if (!user) {
      console.log('❌ User not found:', email);
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // فحص كلمة المرور (بسيط للآن)
    if (user.password !== password) {
      console.log('❌ Invalid password for:', email);
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    console.log('✅ Login successful:', email, 'Role:', user.role);

    // إنشاء token
    const token = 'unibus-' + Date.now() + '-' + (user.role || 'student');

    // تحديد صفحة التوجيه حسب الدور
    let redirectUrl = '/student/portal';
    if (user.role === 'admin') {
      redirectUrl = '/admin/dashboard';
    } else if (user.role === 'supervisor') {
      redirectUrl = '/admin/supervisor-dashboard';
    }

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user._id?.toString() || Date.now().toString(),
        email: user.email,
        role: user.role || 'student',
        fullName: user.fullName || user.name || 'User',
        isActive: user.isActive !== false
      },
      redirectUrl
    });

  } catch (error) {
    console.error('💥 Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error occurred'
    });
  }
});

// Register route
router.post('/register', async (req, res) => {
  try {
    const { email, password, fullName, role = 'student' } = req.body;
    
    console.log('📝 Registration attempt:', email);
    
    if (!email || !password || !fullName) {
      return res.status(400).json({
        success: false,
        message: 'All fields are required'
      });
    }

    const db = await connectDB();
    
    // فحص إذا كان المستخدم موجود
    const existingUser = await db.collection('users').findOne({
      email: email.toLowerCase()
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User already exists'
      });
    }

    // إنشاء مستخدم جديد
    const newUser = {
      email: email.toLowerCase(),
      password,
      fullName,
      role,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    const result = await db.collection('users').insertOne(newUser);

    // إذا كان طالب، أنشئ سجل في students collection
    if (role === 'student') {
      const studentData = {
        fullName,
        email: email.toLowerCase(),
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
      console.log('✅ Student record created for:', email);
    }

    console.log('✅ Registration successful:', email);

    const token = 'unibus-' + Date.now() + '-' + role;

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      token,
      user: {
        id: result.insertedId,
        email: newUser.email,
        role: newUser.role,
        fullName: newUser.fullName,
        isActive: true
      }
    });

  } catch (error) {
    console.error('💥 Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error occurred'
    });
  }
});

module.exports = router;