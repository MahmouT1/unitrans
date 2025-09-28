// إعادة بناء النظام بالكامل كما كان يعمل على السيرفر المحلي
const fs = require('fs');

console.log('🔧 إعادة بناء النظام بالكامل...\n');

// 1. إعادة إنشاء config/database.js للـ Backend
const databaseConfig = `const { MongoClient } = require('mongodb');
require('dotenv').config();

let db;
let client;

async function connectDB() {
  if (db) {
    return db;
  }

  try {
    client = new MongoClient(process.env.MONGODB_URI || 'mongodb://localhost:27017');
    await client.connect();
    db = client.db(process.env.MONGODB_DB_NAME || 'student_portal');
    console.log('✅ Connected to MongoDB:', process.env.MONGODB_DB_NAME || 'student_portal');
    return db;
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    throw error;
  }
}

module.exports = connectDB;`;

// 2. إعادة إنشاء auth.js للـ Backend (مبسط ويعمل)
const authRoutes = `const express = require('express');
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

module.exports = router;`;

// 3. إعادة إنشاء صفحة Auth الأصلية بالضبط
const originalAuthPage = `'use client';

import { useState, useEffect } from 'react';
import { apiCall, getApiUrl } from '../../config/api';

export default function UnifiedAuth() {
  const [isLogin, setIsLogin] = useState(true);
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    fullName: ''
  });
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  // Clear cache on component mount if requested
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('clear') === '1') {
      localStorage.clear();
      sessionStorage.clear();
      setMessage('✅ Cache cleared! You can now login with your updated role.');
    }
  }, []);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage('');

    // Clear any existing cached data to prevent conflicts
    localStorage.removeItem('token');
    localStorage.removeItem('userToken');
    localStorage.removeItem('userRole');
    localStorage.removeItem('user');
    sessionStorage.clear();

    // Validation for registration
    if (!isLogin) {
      if (formData.password !== formData.confirmPassword) {
        setMessage('Passwords do not match');
        setLoading(false);
        return;
      }
      if (formData.password.length < 6) {
        setMessage('Password must be at least 6 characters');
        setLoading(false);
        return;
      }
    }

    try {
      const endpoint = isLogin ? '/api/proxy/auth/login' : '/api/proxy/auth/register';
      const body = isLogin 
        ? { email: formData.email, password: formData.password }
        : { 
            email: formData.email, 
            password: formData.password,
            fullName: formData.fullName,
            role: 'student'
          };

      console.log('API Call:', 'POST', endpoint);
      console.log('Request Data:', body);

      const response = await apiCall(endpoint, {
        method: 'POST',
        body: JSON.stringify(body)
      });

      console.log('API Response:', response);

      if (response.ok && response.data.success) {
        // Store authentication data
        localStorage.setItem('token', response.data.token);
        localStorage.setItem('userToken', response.data.token);
        localStorage.setItem('userRole', response.data.user.role);
        localStorage.setItem('user', JSON.stringify(response.data.user));
        localStorage.setItem('isAuthenticated', 'true');

        setMessage(\`✅ \${isLogin ? 'Login' : 'Registration'} successful! Redirecting...\`);
        
        // Redirect based on role
        setTimeout(() => {
          if (response.data.user.role === 'admin') {
            window.location.href = '/admin/dashboard';
          } else if (response.data.user.role === 'supervisor') {
            window.location.href = '/admin/supervisor-dashboard';
          } else {
            window.location.href = '/student/portal';
          }
        }, 2000);
      } else {
        setMessage('❌ ' + (response.data.message || 'Operation failed'));
      }
    } catch (error) {
      console.error('Error:', error);
      setMessage('❌ Connection error. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '20px',
      fontFamily: 'system-ui, sans-serif'
    }}>
      <div style={{
        maxWidth: '500px',
        width: '100%',
        backgroundColor: 'white',
        borderRadius: '20px',
        boxShadow: '0 25px 50px rgba(0, 0, 0, 0.15)',
        overflow: 'hidden'
      }}>
        {/* Header */}
        <div style={{
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          padding: '40px 40px 30px',
          textAlign: 'center',
          color: 'white'
        }}>
          <div style={{
            width: '80px',
            height: '80px',
            backgroundColor: 'rgba(255, 255, 255, 0.2)',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            margin: '0 auto 20px',
            fontSize: '36px'
          }}>
            🚌
          </div>
          <h1 style={{
            margin: '0 0 10px 0',
            fontSize: '32px',
            fontWeight: '700'
          }}>
            UniBus Portal
          </h1>
          <p style={{
            margin: '0',
            fontSize: '16px',
            opacity: 0.9
          }}>
            Student Transportation System
          </p>
        </div>

        {/* Tab Switcher */}
        <div style={{
          display: 'flex',
          backgroundColor: '#f8f9fa'
        }}>
          <button
            onClick={() => setIsLogin(true)}
            style={{
              flex: 1,
              padding: '20px',
              border: 'none',
              backgroundColor: isLogin ? 'white' : 'transparent',
              color: isLogin ? '#667eea' : '#6c757d',
              fontWeight: isLogin ? '600' : '400',
              fontSize: '16px',
              cursor: 'pointer',
              borderBottom: isLogin ? '3px solid #667eea' : '3px solid transparent',
              transition: 'all 0.3s ease'
            }}
          >
            🔐 Login
          </button>
          <button
            onClick={() => setIsLogin(false)}
            style={{
              flex: 1,
              padding: '20px',
              border: 'none',
              backgroundColor: !isLogin ? 'white' : 'transparent',
              color: !isLogin ? '#667eea' : '#6c757d',
              fontWeight: !isLogin ? '600' : '400',
              fontSize: '16px',
              cursor: 'pointer',
              borderBottom: !isLogin ? '3px solid #667eea' : '3px solid transparent',
              transition: 'all 0.3s ease'
            }}
          >
            ✨ Register
          </button>
        </div>

        {/* Form */}
        <div style={{ padding: '40px' }}>
          <form onSubmit={handleSubmit}>
            {!isLogin && (
              <div style={{ marginBottom: '25px' }}>
                <label style={{
                  display: 'block',
                  marginBottom: '8px',
                  fontWeight: '600',
                  color: '#374151',
                  fontSize: '14px'
                }}>
                  Full Name
                </label>
                <input
                  type="text"
                  name="fullName"
                  value={formData.fullName}
                  onChange={handleInputChange}
                  required={!isLogin}
                  style={{
                    width: '100%',
                    padding: '15px',
                    border: '2px solid #e5e7eb',
                    borderRadius: '12px',
                    fontSize: '16px',
                    boxSizing: 'border-box',
                    transition: 'border-color 0.3s ease',
                    outline: 'none'
                  }}
                  placeholder="Enter your full name"
                />
              </div>
            )}

            <div style={{ marginBottom: '25px' }}>
              <label style={{
                display: 'block',
                marginBottom: '8px',
                fontWeight: '600',
                color: '#374151',
                fontSize: '14px'
              }}>
                Email Address
              </label>
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleInputChange}
                required
                style={{
                  width: '100%',
                  padding: '15px',
                  border: '2px solid #e5e7eb',
                  borderRadius: '12px',
                  fontSize: '16px',
                  boxSizing: 'border-box',
                  transition: 'border-color 0.3s ease',
                  outline: 'none'
                }}
                placeholder="Enter your email address"
              />
            </div>

            <div style={{ marginBottom: !isLogin ? '25px' : '35px' }}>
              <label style={{
                display: 'block',
                marginBottom: '8px',
                fontWeight: '600',
                color: '#374151',
                fontSize: '14px'
              }}>
                Password
              </label>
              <input
                type="password"
                name="password"
                value={formData.password}
                onChange={handleInputChange}
                required
                style={{
                  width: '100%',
                  padding: '15px',
                  border: '2px solid #e5e7eb',
                  borderRadius: '12px',
                  fontSize: '16px',
                  boxSizing: 'border-box',
                  transition: 'border-color 0.3s ease',
                  outline: 'none'
                }}
                placeholder="Enter your password"
              />
            </div>

            {!isLogin && (
              <div style={{ marginBottom: '35px' }}>
                <label style={{
                  display: 'block',
                  marginBottom: '8px',
                  fontWeight: '600',
                  color: '#374151',
                  fontSize: '14px'
                }}>
                  Confirm Password
                </label>
                <input
                  type="password"
                  name="confirmPassword"
                  value={formData.confirmPassword}
                  onChange={handleInputChange}
                  required={!isLogin}
                  style={{
                    width: '100%',
                    padding: '15px',
                    border: '2px solid #e5e7eb',
                    borderRadius: '12px',
                    fontSize: '16px',
                    boxSizing: 'border-box',
                    transition: 'border-color 0.3s ease',
                    outline: 'none'
                  }}
                  placeholder="Confirm your password"
                />
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              style={{
                width: '100%',
                padding: '18px',
                backgroundColor: loading ? '#9ca3af' : '#667eea',
                color: 'white',
                border: 'none',
                borderRadius: '12px',
                fontSize: '18px',
                fontWeight: '600',
                cursor: loading ? 'not-allowed' : 'pointer',
                transition: 'all 0.3s ease',
                transform: loading ? 'scale(0.98)' : 'scale(1)'
              }}
            >
              {loading 
                ? (isLogin ? '🔄 Signing in...' : '🔄 Creating account...') 
                : (isLogin ? '🚀 Sign In' : '✨ Create Account')
              }
            </button>
          </form>

          {message && (
            <div style={{
              marginTop: '25px',
              padding: '16px',
              borderRadius: '12px',
              backgroundColor: message.includes('✅') ? '#dcfce7' : '#fef2f2',
              border: \`2px solid \${message.includes('✅') ? '#bbf7d0' : '#fecaca'}\`,
              textAlign: 'center'
            }}>
              <p style={{
                fontSize: '14px',
                margin: 0,
                color: message.includes('✅') ? '#166534' : '#dc2626',
                fontWeight: '600'
              }}>
                {message}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}`;

// 4. إنشاء proxy routes للـ Auth
const loginProxyRoute = `import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    
    // Forward to backend
    const backendUrl = 'http://localhost:3001';
    const response = await fetch(\`\${backendUrl}/api/auth/login\`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();
    
    return NextResponse.json(data, {
      status: response.status
    });

  } catch (error) {
    console.error('Login proxy error:', error);
    return NextResponse.json({
      success: false,
      message: 'Connection error'
    }, { status: 500 });
  }
}`;

const registerProxyRoute = `import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    
    // Forward to backend
    const backendUrl = 'http://localhost:3001';
    const response = await fetch(\`\${backendUrl}/api/auth/register\`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();
    
    return NextResponse.json(data, {
      status: response.status
    });

  } catch (error) {
    console.error('Register proxy error:', error);
    return NextResponse.json({
      success: false,
      message: 'Connection error'
    }, { status: 500 });
  }
}`;

function createFiles() {
    console.log('📁 إنشاء الملفات...\n');
    
    // Backend files
    if (!fs.existsSync('backend-new/config')) {
        fs.mkdirSync('backend-new/config', { recursive: true });
    }
    
    fs.writeFileSync('backend-new/config/database.js', databaseConfig);
    console.log('✅ تم إنشاء backend-new/config/database.js');
    
    fs.writeFileSync('backend-new/routes/auth.js', authRoutes);
    console.log('✅ تم إنشاء backend-new/routes/auth.js');
    
    // Frontend files
    fs.writeFileSync('frontend-new/app/auth/page.js', originalAuthPage);
    console.log('✅ تم إنشاء frontend-new/app/auth/page.js');
    
    // Proxy routes
    if (!fs.existsSync('frontend-new/app/api/proxy/auth/login')) {
        fs.mkdirSync('frontend-new/app/api/proxy/auth/login', { recursive: true });
    }
    if (!fs.existsSync('frontend-new/app/api/proxy/auth/register')) {
        fs.mkdirSync('frontend-new/app/api/proxy/auth/register', { recursive: true });
    }
    
    fs.writeFileSync('frontend-new/app/api/proxy/auth/login/route.js', loginProxyRoute);
    console.log('✅ تم إنشاء frontend-new/app/api/proxy/auth/login/route.js');
    
    fs.writeFileSync('frontend-new/app/api/proxy/auth/register/route.js', registerProxyRoute);
    console.log('✅ تم إنشاء frontend-new/app/api/proxy/auth/register/route.js');
    
    console.log('\n🎯 تم إنشاء جميع الملفات بنجاح!');
    console.log('\n📋 الخطوات التالية:');
    console.log('1. git add .');
    console.log('2. git commit -m "Rebuild system exactly as local server"');
    console.log('3. git push origin main');
    console.log('4. على السيرفر: تشغيل النشر');
}

createFiles();
