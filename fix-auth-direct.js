// إصلاح صفحة Auth للاتصال المباشر بـ Backend
const fs = require('fs');

const fixedAuthPage = `'use client';

import { useState, useEffect } from 'react';

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
      // الاتصال المباشر بـ Backend
      const endpoint = isLogin ? 'https://unibus.online:3001/api/auth/login' : 'https://unibus.online:3001/api/auth/register';
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

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body)
      });

      console.log('API Response:', response.status);
      const data = await response.json();
      console.log('API Response Data:', data);

      if (data.success) {
        // Store authentication data
        localStorage.setItem('token', data.token);
        localStorage.setItem('userToken', data.token);
        localStorage.setItem('userRole', data.user.role);
        localStorage.setItem('user', JSON.stringify(data.user));
        localStorage.setItem('isAuthenticated', 'true');

        setMessage(\`✅ \${isLogin ? 'Login' : 'Registration'} successful! Redirecting...\`);
        
        // Redirect based on role
        setTimeout(() => {
          if (data.user.role === 'admin') {
            window.location.href = '/admin/dashboard';
          } else if (data.user.role === 'supervisor') {
            window.location.href = '/admin/supervisor-dashboard';
          } else {
            window.location.href = '/student/portal';
          }
        }, 2000);
      } else {
        setMessage('❌ ' + (data.message || 'Operation failed'));
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

function createFile() {
    console.log('🔧 إصلاح صفحة Auth للاتصال المباشر بـ Backend...\n');
    
    // إنشاء صفحة Auth المحدثة
    const authPath = 'frontend-new/app/auth/page.js';
    fs.writeFileSync(authPath, fixedAuthPage);
    console.log('✅ تم إصلاح صفحة Auth للاتصال المباشر');
    
    console.log('\n🎯 الإصلاحات:');
    console.log('  📄 صفحة Auth: اتصال مباشر بـ Backend');
    console.log('  🔗 Endpoint: https://unibus.online:3001/api/auth/login');
    console.log('  🔗 Endpoint: https://unibus.online:3001/api/auth/register');
    console.log('  🚀 لا حاجة لـ API proxy routes');
    
    console.log('\n📋 الخطوات التالية:');
    console.log('  1. git add .');
    console.log('  2. git commit -m "Fix: Direct backend connection for auth"');
    console.log('  3. git push origin main');
    console.log('  4. على السيرفر: git pull && npm run build && pm2 restart');
}

createFile();
