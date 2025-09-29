#!/bin/bash

echo "🔧 حذف صفحة Auth واسترجاع صفحة Login الأصلية"
echo "========================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص الصفحات الحالية:"
echo "======================="

echo "🔍 فحص صفحة Auth:"
if [ -d "frontend-new/app/auth" ]; then
    echo "❌ صفحة Auth موجودة - يجب حذفها"
    ls -la frontend-new/app/auth/
else
    echo "✅ صفحة Auth غير موجودة"
fi

echo ""
echo "🔍 فحص صفحة Login:"
if [ -d "frontend-new/app/login" ]; then
    echo "✅ صفحة Login موجودة"
    ls -la frontend-new/app/login/
else
    echo "❌ صفحة Login غير موجودة"
fi

echo ""
echo "🔧 2️⃣ حذف صفحة Auth تماماً:"
echo "========================="

echo "🔄 حذف مجلد صفحة Auth:"
rm -rf frontend-new/app/auth

echo "✅ تم حذف صفحة Auth تماماً"

echo ""
echo "🔧 3️⃣ استرجاع صفحة Login الأصلية:"
echo "==============================="

echo "📝 إنشاء صفحة Login الأصلية:"

# Create original login page
cat > frontend-new/app/login/page.js << 'EOF'
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const [isLogin, setIsLogin] = useState(true);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    fullName: ''
  });

  const router = useRouter();

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
            fullName: formData.fullName,
            role: 'student'
          };

      console.log('🔄 طلب المصادقة:', endpoint, requestData.email);

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify(requestData)
      });

      const data = await response.json();
      console.log('📡 استجابة المصادقة:', data);

      if (response.ok && data.success) {
        // حفظ بيانات المصادقة
        localStorage.setItem('token', data.token);
        localStorage.setItem('authToken', data.token);
        localStorage.setItem('userToken', data.token);
        localStorage.setItem('user', JSON.stringify(data.user));
        localStorage.setItem('userRole', data.user.role);
        localStorage.setItem('isAuthenticated', 'true');

        setMessage(`✅ ${isLogin ? 'تم تسجيل الدخول' : 'تم إنشاء الحساب'} بنجاح! جاري التوجيه...`);
        
        // التوجيه بعد النجاح
        setTimeout(() => {
          const redirectUrl = data.redirectUrl || '/student/portal';
          console.log('🔄 التوجيه إلى:', redirectUrl);
          window.location.href = redirectUrl;
        }, 1500);

      } else {
        setMessage('❌ ' + (data.message || 'فشل في العملية'));
      }
    } catch (error) {
      console.error('❌ خطأ في المصادقة:', error);
      setMessage('❌ خطأ في الاتصال. يرجى التحقق من الشبكة والمحاولة مرة أخرى.');
    } finally {
      setLoading(false);
    }
  };

  const quickLogin = (email, password) => {
    setFormData({ email, password, fullName: '' });
    setIsLogin(true);
  };

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: 'Arial, sans-serif',
      padding: '20px'
    }}>
      <div style={{
        background: 'white',
        borderRadius: '20px',
        boxShadow: '0 20px 40px rgba(0,0,0,0.1)',
        padding: '40px',
        width: '100%',
        maxWidth: '450px',
        position: 'relative',
        overflow: 'hidden'
      }}>
        {/* Header */}
        <div style={{
          textAlign: 'center',
          marginBottom: '30px'
        }}>
          <div style={{
            width: '80px',
            height: '80px',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            borderRadius: '50%',
            margin: '0 auto 20px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: '32px',
            color: 'white'
          }}>
            🎓
          </div>
          <h1 style={{
            fontSize: '28px',
            fontWeight: 'bold',
            color: '#333',
            margin: '0 0 10px 0'
          }}>
            نظام إدارة النقل الجامعي
          </h1>
          <p style={{
            color: '#666',
            fontSize: '16px',
            margin: '0'
          }}>
            UniBus Portal
          </p>
        </div>

        {/* Tabs */}
        <div style={{
          display: 'flex',
          marginBottom: '30px',
          background: '#f8f9fa',
          borderRadius: '10px',
          padding: '4px'
        }}>
          <button
            onClick={() => setIsLogin(true)}
            style={{
              flex: 1,
              padding: '12px 20px',
              border: 'none',
              borderRadius: '8px',
              background: isLogin ? 'white' : 'transparent',
              color: isLogin ? '#667eea' : '#666',
              fontWeight: '600',
              cursor: 'pointer',
              transition: 'all 0.3s ease',
              boxShadow: isLogin ? '0 2px 8px rgba(0,0,0,0.1)' : 'none'
            }}
          >
            🔐 تسجيل الدخول
          </button>
          <button
            onClick={() => setIsLogin(false)}
            style={{
              flex: 1,
              padding: '12px 20px',
              border: 'none',
              borderRadius: '8px',
              background: !isLogin ? 'white' : 'transparent',
              color: !isLogin ? '#667eea' : '#666',
              fontWeight: '600',
              cursor: 'pointer',
              transition: 'all 0.3s ease',
              boxShadow: !isLogin ? '0 2px 8px rgba(0,0,0,0.1)' : 'none'
            }}
          >
            ✨ إنشاء حساب
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit}>
          {!isLogin && (
            <div style={{ marginBottom: '20px' }}>
              <label style={{
                display: 'block',
                marginBottom: '8px',
                fontWeight: '600',
                color: '#333'
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
                  padding: '12px 16px',
                  border: '2px solid #e1e5e9',
                  borderRadius: '10px',
                  fontSize: '16px',
                  transition: 'border-color 0.3s ease',
                  outline: 'none'
                }}
                onFocus={(e) => e.target.style.borderColor = '#667eea'}
                onBlur={(e) => e.target.style.borderColor = '#e1e5e9'}
                placeholder="أدخل اسمك الكامل"
              />
            </div>
          )}

          <div style={{ marginBottom: '20px' }}>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333'
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
                padding: '12px 16px',
                border: '2px solid #e1e5e9',
                borderRadius: '10px',
                fontSize: '16px',
                transition: 'border-color 0.3s ease',
                outline: 'none'
              }}
              onFocus={(e) => e.target.style.borderColor = '#667eea'}
              onBlur={(e) => e.target.style.borderColor = '#e1e5e9'}
              placeholder="أدخل بريدك الإلكتروني"
            />
          </div>

          <div style={{ marginBottom: '20px' }}>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333'
            }}>
              كلمة المرور
            </label>
            <input
              type="password"
              name="password"
              value={formData.password}
              onChange={handleInputChange}
              required
              style={{
                width: '100%',
                padding: '12px 16px',
                border: '2px solid #e1e5e9',
                borderRadius: '10px',
                fontSize: '16px',
                transition: 'border-color 0.3s ease',
                outline: 'none'
              }}
              onFocus={(e) => e.target.style.borderColor = '#667eea'}
              onBlur={(e) => e.target.style.borderColor = '#e1e5e9'}
              placeholder="أدخل كلمة المرور"
            />
          </div>

          {message && (
            <div style={{
              padding: '12px 16px',
              borderRadius: '8px',
              marginBottom: '20px',
              background: message.includes('✅') ? '#d4edda' : '#f8d7da',
              color: message.includes('✅') ? '#155724' : '#721c24',
              border: `1px solid ${message.includes('✅') ? '#c3e6cb' : '#f5c6cb'}`,
              fontSize: '14px'
            }}>
              {message}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            style={{
              width: '100%',
              padding: '14px 20px',
              background: loading ? '#ccc' : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              color: 'white',
              border: 'none',
              borderRadius: '10px',
              fontSize: '16px',
              fontWeight: '600',
              cursor: loading ? 'not-allowed' : 'pointer',
              transition: 'all 0.3s ease',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px'
            }}
          >
            {loading ? (
              <>
                <div style={{
                  width: '20px',
                  height: '20px',
                  border: '2px solid transparent',
                  borderTop: '2px solid white',
                  borderRadius: '50%',
                  animation: 'spin 1s linear infinite'
                }}></div>
                جاري المعالجة...
              </>
            ) : (
              <>
                🚀 {isLogin ? 'تسجيل الدخول' : 'إنشاء الحساب'}
              </>
            )}
          </button>
        </form>

        {/* Test Accounts */}
        <div style={{
          marginTop: '30px',
          padding: '20px',
          background: '#f8f9fa',
          borderRadius: '10px',
          border: '1px solid #e9ecef'
        }}>
          <h3 style={{
            margin: '0 0 15px 0',
            fontSize: '16px',
            fontWeight: '600',
            color: '#333',
            display: 'flex',
            alignItems: 'center',
            gap: '8px'
          }}>
            🔐 حسابات الاختبار
          </h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            <button
              onClick={() => quickLogin('test@test.com', '123456')}
              style={{
                padding: '10px 15px',
                background: '#28a745',
                color: 'white',
                border: 'none',
                borderRadius: '6px',
                cursor: 'pointer',
                fontSize: '14px',
                fontWeight: '500',
                transition: 'background 0.3s ease'
              }}
              onMouseOver={(e) => e.target.style.background = '#218838'}
              onMouseOut={(e) => e.target.style.background = '#28a745'}
            >
              👨‍🎓 طالب: test@test.com / 123456
            </button>
            <button
              onClick={() => quickLogin('roo2admin@gmail.com', 'admin123')}
              style={{
                padding: '10px 15px',
                background: '#007bff',
                color: 'white',
                border: 'none',
                borderRadius: '6px',
                cursor: 'pointer',
                fontSize: '14px',
                fontWeight: '500',
                transition: 'background 0.3s ease'
              }}
              onMouseOver={(e) => e.target.style.background = '#0056b3'}
              onMouseOut={(e) => e.target.style.background = '#007bff'}
            >
              👨‍💼 إدارة: roo2admin@gmail.com / admin123
            </button>
            <button
              onClick={() => quickLogin('ahmedazab@gmail.com', 'supervisor123')}
              style={{
                padding: '10px 15px',
                background: '#fd7e14',
                color: 'white',
                border: 'none',
                borderRadius: '6px',
                cursor: 'pointer',
                fontSize: '14px',
                fontWeight: '500',
                transition: 'background 0.3s ease'
              }}
              onMouseOver={(e) => e.target.style.background = '#e8650e'}
              onMouseOut={(e) => e.target.style.background = '#fd7e14'}
            >
              👨‍💼 مشرف: ahmedazab@gmail.com / supervisor123
            </button>
          </div>
        </div>
      </div>

      <style jsx>{`
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
}
EOF

echo "✅ تم إنشاء صفحة Login الأصلية"

echo ""
echo "🔧 4️⃣ إعادة Build Frontend:"
echo "========================="

echo "🔄 حذف .next directory:"
rm -rf frontend-new/.next

echo "🔄 حذف node_modules/.cache:"
rm -rf frontend-new/node_modules/.cache

echo "🔄 إعادة build frontend:"
cd frontend-new
npm run build

echo ""
echo "🔍 فحص build result:"
if [ -d ".next" ]; then
    echo "✅ Build نجح!"
else
    echo "❌ Build فشل!"
fi

cd ..

echo ""
echo "🔧 5️⃣ إعادة تشغيل Frontend:"
echo "========================="

echo "🔄 إعادة تشغيل frontend..."
pm2 restart unitrans-frontend

echo "⏳ انتظار 10 ثواني للتأكد من التشغيل..."
sleep 10

echo "🔍 فحص حالة frontend:"
pm2 status unitrans-frontend

echo ""
echo "🧪 6️⃣ اختبار الصفحات:"
echo "==================="

echo "🔍 اختبار صفحة Login:"
LOGIN_PAGE=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/login)
echo "$LOGIN_PAGE"

echo ""
echo "🔍 اختبار صفحة Auth (يجب أن تعطي 404):"
AUTH_PAGE=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/auth)
echo "$AUTH_PAGE"

echo ""
echo "📊 7️⃣ تقرير الإصلاح النهائي:"
echo "=========================="

echo "✅ الإصلاحات المطبقة:"
echo "   🔧 تم حذف صفحة Auth تماماً"
echo "   📝 تم إنشاء صفحة Login الأصلية"
echo "   🔄 تم إعادة build frontend"
echo "   🔄 تم إعادة تشغيل frontend"
echo "   🧪 تم اختبار الصفحات"

echo ""
echo "🎯 النتائج:"
echo "   📱 Login Page: $LOGIN_PAGE"
echo "   🚫 Auth Page: $AUTH_PAGE (يجب أن تكون 404)"

echo ""
echo "🎉 تم حذف صفحة Auth واسترجاع صفحة Login الأصلية!"
echo "🌐 يمكنك الآن اختبار صفحة Login:"
echo "   🔗 https://unibus.online/login"
echo "   📧 test@test.com / 123456"
echo "   ✅ يجب أن يعمل بالتصميم العربي!"
