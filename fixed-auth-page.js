'use client';

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

    try {
      // Validation for registration
      if (!isLogin) {
        if (formData.password !== formData.confirmPassword) {
          setMessage('Passwords do not match');
          setLoading(false);
          return;
        }
        if (!formData.fullName || !formData.email || !formData.password) {
          setMessage('All fields are required for registration');
          setLoading(false);
          return;
        }
      }

      // Prepare request data
      const requestData = {
        email: formData.email,
        password: formData.password,
        ...(isLogin ? {} : { fullName: formData.fullName, role: 'student' })
      };

      // Choose endpoint
      const endpoint = isLogin ? '/api/proxy/auth/login' : '/api/proxy/auth/register';
      
      console.log(`🌐 API Call: POST ${endpoint}`);
      console.log(`📋 Request Data:`, requestData);

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestData),
      });

      const data = await response.json();
      console.log(`📡 API Response: ${response.status}`, data);

      if (data.success) {
        setMessage(`${isLogin ? 'Login' : 'Registration'} successful! Redirecting...`);
        
        // Save user data
        localStorage.setItem('token', data.token);
        localStorage.setItem('userToken', data.token);
        localStorage.setItem('userRole', data.user.role);
        localStorage.setItem('user', JSON.stringify(data.user));
        
        // Redirect based on role
        setTimeout(() => {
          if (data.user.role === 'admin') {
            window.location.href = '/admin/dashboard';
          } else if (data.user.role === 'supervisor') {
            window.location.href = '/admin/supervisor-dashboard';
          } else {
            window.location.href = '/student/portal';
          }
        }, 1500);
        
      } else {
        setMessage(data.message || `${isLogin ? 'Login' : 'Registration'} failed`);
      }
    } catch (error) {
      console.error('Auth error:', error);
      setMessage('Network error. Please try again.');
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
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    }}>
      <div style={{
        background: 'rgba(255, 255, 255, 0.95)',
        borderRadius: '20px',
        padding: '2rem',
        width: '100%',
        maxWidth: '400px',
        boxShadow: '0 20px 40px rgba(0,0,0,0.1)',
        backdropFilter: 'blur(10px)'
      }}>
        {/* Header */}
        <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
          <h1 style={{ 
            color: '#333', 
            marginBottom: '0.5rem',
            fontSize: '1.8rem',
            fontWeight: '600'
          }}>
            Student Transportation System
          </h1>
        </div>

        {/* Tab Navigation */}
        <div style={{
          display: 'flex',
          marginBottom: '2rem',
          backgroundColor: '#f8f9fa',
          borderRadius: '12px',
          padding: '4px'
        }}>
          <button
            type="button"
            onClick={() => setIsLogin(true)}
            style={{
              flex: 1,
              padding: '0.75rem',
              border: 'none',
              borderRadius: '8px',
              background: isLogin ? '#667eea' : 'transparent',
              color: isLogin ? 'white' : '#666',
              fontWeight: '500',
              cursor: 'pointer',
              transition: 'all 0.3s ease'
            }}
          >
            🔐 Login
          </button>
          <button
            type="button"
            onClick={() => setIsLogin(false)}
            style={{
              flex: 1,
              padding: '0.75rem',
              border: 'none',
              borderRadius: '8px',
              background: !isLogin ? '#667eea' : 'transparent',
              color: !isLogin ? 'white' : '#666',
              fontWeight: '500',
              cursor: 'pointer',
              transition: 'all 0.3s ease'
            }}
          >
            🎓 Register
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit}>
          {!isLogin && (
            <div style={{ marginBottom: '1rem' }}>
              <label style={{ 
                display: 'block', 
                marginBottom: '0.5rem', 
                color: '#333',
                fontWeight: '500'
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
                  padding: '0.75rem',
                  border: '2px solid #e9ecef',
                  borderRadius: '8px',
                  fontSize: '1rem',
                  transition: 'border-color 0.3s ease',
                  boxSizing: 'border-box'
                }}
                onFocus={(e) => e.target.style.borderColor = '#667eea'}
                onBlur={(e) => e.target.style.borderColor = '#e9ecef'}
              />
            </div>
          )}

          <div style={{ marginBottom: '1rem' }}>
            <label style={{ 
              display: 'block', 
              marginBottom: '0.5rem', 
              color: '#333',
              fontWeight: '500'
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
                padding: '0.75rem',
                border: '2px solid #e9ecef',
                borderRadius: '8px',
                fontSize: '1rem',
                transition: 'border-color 0.3s ease',
                boxSizing: 'border-box'
              }}
              onFocus={(e) => e.target.style.borderColor = '#667eea'}
              onBlur={(e) => e.target.style.borderColor = '#e9ecef'}
            />
          </div>

          <div style={{ marginBottom: '1rem' }}>
            <label style={{ 
              display: 'block', 
              marginBottom: '0.5rem', 
              color: '#333',
              fontWeight: '500'
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
                padding: '0.75rem',
                border: '2px solid #e9ecef',
                borderRadius: '8px',
                fontSize: '1rem',
                transition: 'border-color 0.3s ease',
                boxSizing: 'border-box'
              }}
              onFocus={(e) => e.target.style.borderColor = '#667eea'}
              onBlur={(e) => e.target.style.borderColor = '#e9ecef'}
            />
          </div>

          {!isLogin && (
            <div style={{ marginBottom: '1.5rem' }}>
              <label style={{ 
                display: 'block', 
                marginBottom: '0.5rem', 
                color: '#333',
                fontWeight: '500'
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
                  padding: '0.75rem',
                  border: '2px solid #e9ecef',
                  borderRadius: '8px',
                  fontSize: '1rem',
                  transition: 'border-color 0.3s ease',
                  boxSizing: 'border-box'
                }}
                onFocus={(e) => e.target.style.borderColor = '#667eea'}
                onBlur={(e) => e.target.style.borderColor = '#e9ecef'}
              />
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            style={{
              width: '100%',
              padding: '0.875rem',
              background: loading ? '#ccc' : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              fontSize: '1rem',
              fontWeight: '600',
              cursor: loading ? 'not-allowed' : 'pointer',
              transition: 'all 0.3s ease',
              marginBottom: '1rem'
            }}
          >
            {loading ? '⏳ Processing...' : (isLogin ? '🔐 Login' : '🎓 Register')}
          </button>
        </form>

        {/* Message */}
        {message && (
          <div style={{
            padding: '0.75rem',
            borderRadius: '8px',
            backgroundColor: message.includes('successful') || message.includes('✅') ? '#d4edda' : '#f8d7da',
            color: message.includes('successful') || message.includes('✅') ? '#155724' : '#721c24',
            border: `1px solid ${message.includes('successful') || message.includes('✅') ? '#c3e6cb' : '#f5c6cb'}`,
            fontSize: '0.875rem',
            textAlign: 'center'
          }}>
            {message}
          </div>
        )}
      </div>
    </div>
  );
}