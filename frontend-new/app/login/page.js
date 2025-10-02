'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function ProfessionalLogin() {
  const router = useRouter();
  const [isLogin, setIsLogin] = useState(true);
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    fullName: ''
  });
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  // Clear any existing session on load
  useEffect(() => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.removeItem('userRole');
    sessionStorage.clear();
  }, []);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    // Clear message when user starts typing
    if (message) setMessage('');
  };

  const validateForm = () => {
    if (!formData.email.trim()) {
      setMessage('❌ البريد الإلكتروني مطلوب');
      return false;
    }

    if (!formData.password) {
      setMessage('❌ كلمة المرور مطلوبة');
      return false;
    }

    if (!isLogin) {
      if (!formData.fullName.trim()) {
        setMessage('❌ الاسم الكامل مطلوب');
        return false;
      }
      
      if (formData.password !== formData.confirmPassword) {
        setMessage('❌ كلمة المرور وتأكيدها غير متطابقتان');
        return false;
      }
      
      if (formData.password.length < 6) {
        setMessage('❌ كلمة المرور يجب أن تكون 6 أحرف على الأقل');
        return false;
      }
    }

    return true;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    setLoading(true);
    setMessage('');

    try {
      const endpoint = isLogin ? '/auth-api/login' : '/auth-api/register';
      const requestData = isLogin 
        ? { 
            email: formData.email.trim(),
            password: formData.password 
          }
        : { 
            email: formData.email.trim(),
            password: formData.password,
            fullName: formData.fullName.trim(),
            role: 'student'
          };

      console.log('🔄 Professional Auth Request:', endpoint, requestData.email);

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify(requestData)
      });

      const data = await response.json();
      console.log('📡 Professional Auth Response:', data);

      if (response.ok && data.success) {
        // Store authentication data professionally
        const authData = {
          token: data.token,
          user: data.user,
          permissions: data.permissions,
          loginTime: new Date().toISOString(),
          sessionId: `session_${Date.now()}`
        };

        // Save to localStorage immediately
        localStorage.setItem('token', data.token);
        localStorage.setItem('authToken', data.token);
        localStorage.setItem('userToken', data.token);
        localStorage.setItem('user', JSON.stringify(data.user));
        localStorage.setItem('userRole', data.user.role);
        localStorage.setItem('permissions', JSON.stringify(data.permissions));
        localStorage.setItem('isAuthenticated', 'true');
        localStorage.setItem('authData', JSON.stringify(authData));

        // Verify token was saved
        const savedToken = localStorage.getItem('token');
        console.log('✅ Token saved:', savedToken ? 'Yes' : 'No');

        setMessage(`✅ ${isLogin ? 'تم تسجيل الدخول' : 'تم إنشاء الحساب'} بنجاح! جاري التوجيه...`);
        
        // Immediate redirect after saving
        const redirectUrl = data.redirectUrl || '/student/portal';
        console.log('🔄 Redirecting to:', redirectUrl);
        
        // Use setTimeout with minimal delay to ensure localStorage is written
        setTimeout(() => {
          window.location.href = redirectUrl;
        }, 100);  // Reduced to 100ms

      } else {
        setMessage('❌ ' + (data.message || 'فشل في العملية'));
      }

    } catch (error) {
      console.error('❌ Professional Auth Error:', error);
      setMessage('❌ خطأ في الاتصال. يرجى التحقق من الشبكة والمحاولة مرة أخرى.');
    } finally {
      setLoading(false);
    }
  };

  const quickLogin = (email, password) => {
    setFormData({
      email,
      password,
      confirmPassword: '',
      fullName: ''
    });
    setIsLogin(true);
  };

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '20px',
      fontFamily: "'Inter', 'Segoe UI', 'Roboto', sans-serif"
    }}>
      <div style={{
        maxWidth: '480px',
        width: '100%',
        backgroundColor: 'white',
        borderRadius: '24px',
        boxShadow: '0 32px 64px rgba(0, 0, 0, 0.12)',
        overflow: 'hidden',
        border: '1px solid rgba(255, 255, 255, 0.2)'
      }}>
        
        {/* Professional Header */}
        <div style={{
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          padding: '48px 40px 40px',
          textAlign: 'center',
          color: 'white',
          position: 'relative'
        }}>
          <div style={{
            width: '88px',
            height: '88px',
            backgroundColor: 'rgba(255, 255, 255, 0.15)',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            margin: '0 auto 24px',
            fontSize: '40px',
            backdropFilter: 'blur(10px)'
          }}>
            🚌
          </div>
          <h1 style={{
            margin: '0 0 12px 0',
            fontSize: '36px',
            fontWeight: '800',
            letterSpacing: '-0.02em'
          }}>
            UniBus Portal
          </h1>
          <p style={{
            margin: '0',
            fontSize: '16px',
            opacity: 0.95,
            fontWeight: '400'
          }}>
            نظام النقل الجامعي المتقدم
          </p>
        </div>

        {/* Professional Tab Switcher */}
        <div style={{
          display: 'flex',
          backgroundColor: '#f8fafc',
          borderBottom: '1px solid #e2e8f0'
        }}>
          <button
            onClick={() => setIsLogin(true)}
            style={{
              flex: 1,
              padding: '20px 24px',
              border: 'none',
              backgroundColor: isLogin ? 'white' : 'transparent',
              color: isLogin ? '#667eea' : '#64748b',
              fontWeight: isLogin ? '700' : '500',
              fontSize: '16px',
              cursor: 'pointer',
              borderBottom: isLogin ? '3px solid #667eea' : '3px solid transparent',
              transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
              position: 'relative'
            }}
          >
            🔐 تسجيل الدخول
          </button>
          <button
            onClick={() => setIsLogin(false)}
            style={{
              flex: 1,
              padding: '20px 24px',
              border: 'none',
              backgroundColor: !isLogin ? 'white' : 'transparent',
              color: !isLogin ? '#667eea' : '#64748b',
              fontWeight: !isLogin ? '700' : '500',
              fontSize: '16px',
              cursor: 'pointer',
              borderBottom: !isLogin ? '3px solid #667eea' : '3px solid transparent',
              transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
              position: 'relative'
            }}
          >
            ✨ إنشاء حساب
          </button>
        </div>

        {/* Professional Form */}
        <div style={{ padding: '48px 40px' }}>
          <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
            
            {/* Full Name (Register only) */}
            {!isLogin && (
              <div>
                <label style={{
                  display: 'block',
                  marginBottom: '8px',
                  fontWeight: '600',
                  color: '#1e293b',
                  fontSize: '14px'
                }}>
                  الاسم الكامل
                </label>
                <input
                  type="text"
                  name="fullName"
                  value={formData.fullName}
                  onChange={handleInputChange}
                  required={!isLogin}
                  style={{
                    width: '100%',
                    padding: '16px 20px',
                    border: '2px solid #e2e8f0',
                    borderRadius: '16px',
                    fontSize: '16px',
                    boxSizing: 'border-box',
                    transition: 'all 0.3s ease',
                    outline: 'none',
                    backgroundColor: '#fafbfc'
                  }}
                  onFocus={(e) => e.target.style.borderColor = '#667eea'}
                  onBlur={(e) => e.target.style.borderColor = '#e2e8f0'}
                  placeholder="أدخل اسمك الكامل"
                />
              </div>
            )}

            {/* Email */}
            <div>
              <label style={{
                display: 'block',
                marginBottom: '8px',
                fontWeight: '600',
                color: '#1e293b',
                fontSize: '14px'
              }}>
                البريد الإلكتروني
              </label>
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleInputChange}
                required
                style={{
                  width: '100%',
                  padding: '16px 20px',
                  border: '2px solid #e2e8f0',
                  borderRadius: '16px',
                  fontSize: '16px',
                  boxSizing: 'border-box',
                  transition: 'all 0.3s ease',
                  outline: 'none',
                  backgroundColor: '#fafbfc'
                }}
                onFocus={(e) => e.target.style.borderColor = '#667eea'}
                onBlur={(e) => e.target.style.borderColor = '#e2e8f0'}
                placeholder="أدخل بريدك الإلكتروني"
              />
            </div>

            {/* Password */}
            <div>
              <label style={{
                display: 'block',
                marginBottom: '8px',
                fontWeight: '600',
                color: '#1e293b',
                fontSize: '14px'
              }}>
                كلمة المرور
              </label>
              <div style={{ position: 'relative' }}>
                <input
                  type={showPassword ? 'text' : 'password'}
                  name="password"
                  value={formData.password}
                  onChange={handleInputChange}
                  required
                  style={{
                    width: '100%',
                    padding: '16px 20px',
                    paddingRight: '52px',
                    border: '2px solid #e2e8f0',
                    borderRadius: '16px',
                    fontSize: '16px',
                    boxSizing: 'border-box',
                    transition: 'all 0.3s ease',
                    outline: 'none',
                    backgroundColor: '#fafbfc'
                  }}
                  onFocus={(e) => e.target.style.borderColor = '#667eea'}
                  onBlur={(e) => e.target.style.borderColor = '#e2e8f0'}
                  placeholder="أدخل كلمة المرور"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  style={{
                    position: 'absolute',
                    right: '16px',
                    top: '50%',
                    transform: 'translateY(-50%)',
                    background: 'none',
                    border: 'none',
                    cursor: 'pointer',
                    fontSize: '20px',
                    color: '#64748b'
                  }}
                >
                  {showPassword ? '🙈' : '👁️'}
                </button>
              </div>
            </div>

            {/* Confirm Password (Register only) */}
            {!isLogin && (
              <div>
                <label style={{
                  display: 'block',
                  marginBottom: '8px',
                  fontWeight: '600',
                  color: '#1e293b',
                  fontSize: '14px'
                }}>
                  تأكيد كلمة المرور
                </label>
                <input
                  type="password"
                  name="confirmPassword"
                  value={formData.confirmPassword}
                  onChange={handleInputChange}
                  required={!isLogin}
                  style={{
                    width: '100%',
                    padding: '16px 20px',
                    border: '2px solid #e2e8f0',
                    borderRadius: '16px',
                    fontSize: '16px',
                    boxSizing: 'border-box',
                    transition: 'all 0.3s ease',
                    outline: 'none',
                    backgroundColor: '#fafbfc'
                  }}
                  onFocus={(e) => e.target.style.borderColor = '#667eea'}
                  onBlur={(e) => e.target.style.borderColor = '#e2e8f0'}
                  placeholder="أعد إدخال كلمة المرور"
                />
              </div>
            )}

            {/* Professional Submit Button */}
            <button
              type="submit"
              disabled={loading}
              style={{
                width: '100%',
                padding: '18px 24px',
                backgroundColor: loading ? '#94a3b8' : '#667eea',
                color: 'white',
                border: 'none',
                borderRadius: '16px',
                fontSize: '18px',
                fontWeight: '700',
                cursor: loading ? 'not-allowed' : 'pointer',
                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                transform: loading ? 'scale(0.98)' : 'scale(1)',
                boxShadow: loading ? 'none' : '0 8px 32px rgba(102, 126, 234, 0.24)',
                position: 'relative',
                overflow: 'hidden'
              }}
              onMouseEnter={(e) => {
                if (!loading) e.target.style.backgroundColor = '#5a67d8';
              }}
              onMouseLeave={(e) => {
                if (!loading) e.target.style.backgroundColor = '#667eea';
              }}
            >
              {loading ? (
                <span style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                  <span style={{ 
                    width: '20px', 
                    height: '20px', 
                    border: '2px solid rgba(255,255,255,0.3)',
                    borderTop: '2px solid white',
                    borderRadius: '50%',
                    animation: 'spin 1s linear infinite'
                  }}></span>
                  {isLogin ? 'جاري تسجيل الدخول...' : 'جاري إنشاء الحساب...'}
                </span>
              ) : (
                isLogin ? '🚀 تسجيل الدخول' : '✨ إنشاء حساب جديد'
              )}
            </button>
          </form>

          {/* Message Display */}
          {message && (
            <div style={{
              marginTop: '24px',
              padding: '16px 20px',
              borderRadius: '16px',
              backgroundColor: message.includes('✅') ? '#dcfce7' : '#fef2f2',
              border: `2px solid ${message.includes('✅') ? '#bbf7d0' : '#fecaca'}`,
              textAlign: 'center',
              animation: 'fadeIn 0.3s ease-in-out'
            }}>
              <p style={{
                fontSize: '15px',
                margin: 0,
                color: message.includes('✅') ? '#166534' : '#dc2626',
                fontWeight: '600',
                lineHeight: 1.5
              }}>
                {message}
              </p>
            </div>
          )}

          {/* Professional Test Accounts */}
          <div style={{
            marginTop: '32px',
            padding: '24px',
            backgroundColor: '#f8fafc',
            borderRadius: '16px',
            border: '1px solid #e2e8f0'
          }}>
            <h4 style={{
              margin: '0 0 16px 0',
              fontSize: '16px',
              fontWeight: '700',
              color: '#1e293b',
              textAlign: 'center',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px'
            }}>
              🔐 حسابات الاختبار
            </h4>
            
            <div style={{ 
              display: 'flex', 
              flexDirection: 'column', 
              gap: '12px',
              fontSize: '13px',
              color: '#475569'
            }}>
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '8px 12px',
                backgroundColor: 'white',
                borderRadius: '8px',
                border: '1px solid #e2e8f0'
              }}>
                <span><strong>🎓 طالب:</strong> test@test.com</span>
                <button
                  onClick={() => quickLogin('test@test.com', '123456')}
                  style={{
                    padding: '4px 8px',
                    backgroundColor: '#10b981',
                    color: 'white',
                    border: 'none',
                    borderRadius: '6px',
                    fontSize: '11px',
                    cursor: 'pointer'
                  }}
                >
                  دخول سريع
                </button>
              </div>
              
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '8px 12px',
                backgroundColor: 'white',
                borderRadius: '8px',
                border: '1px solid #e2e8f0'
              }}>
                <span><strong>👨‍💼 إدارة:</strong> roo2admin@gmail.com</span>
                <button
                  onClick={() => quickLogin('roo2admin@gmail.com', 'admin123')}
                  style={{
                    padding: '4px 8px',
                    backgroundColor: '#3b82f6',
                    color: 'white',
                    border: 'none',
                    borderRadius: '6px',
                    fontSize: '11px',
                    cursor: 'pointer'
                  }}
                >
                  دخول سريع
                </button>
              </div>
              
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '8px 12px',
                backgroundColor: 'white',
                borderRadius: '8px',
                border: '1px solid #e2e8f0'
              }}>
                <span><strong>👷‍♂️ مشرف:</strong> ahmedazab@gmail.com</span>
                <button
                  onClick={() => quickLogin('ahmedazab@gmail.com', 'supervisor123')}
                  style={{
                    padding: '4px 8px',
                    backgroundColor: '#f59e0b',
                    color: 'white',
                    border: 'none',
                    borderRadius: '6px',
                    fontSize: '11px',
                    cursor: 'pointer'
                  }}
                >
                  دخول سريع
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      {/* Professional CSS Animations */}
      <style jsx>{`
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
        
        @keyframes fadeIn {
          0% { opacity: 0; transform: translateY(10px); }
          100% { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  );
}
