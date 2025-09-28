#!/bin/bash

echo "🔧 إصلاح localStorage keys"
echo "=========================="

cd /var/www/unitrans

echo "🛑 إيقاف Frontend..."
pm2 stop unitrans-frontend

echo ""
echo "🔧 إصلاح localStorage keys في student portal:"
echo "=============================================="

# إصلاح student portal للبحث عن الـ keys الصحيحة
cat > frontend-new/app/student/portal/page.js << 'EOF'
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function StudentPortal() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [isMobile, setIsMobile] = useState(false);
  const router = useRouter();

  useEffect(() => {
    const fetchStudentData = async () => {
      // البحث في جميع localStorage keys المحتملة
      const token = localStorage.getItem('token') || 
                    localStorage.getItem('authToken') || 
                    localStorage.getItem('userToken');
      
      const userData = localStorage.getItem('user') || 
                       localStorage.getItem('userData') ||
                       localStorage.getItem('authData');
      
      console.log('🔍 Student Portal - Token exists:', !!token);
      console.log('🔍 Student Portal - User Data exists:', !!userData);
      console.log('🔍 Student Portal - All localStorage keys:', Object.keys(localStorage));
      
      if (!token || !userData) {
        console.log('❌ No auth data found - redirecting to login');
        router.push('/login');
        return;
      }
      
      try {
        let parsedUser;
        
        // محاولة parse البيانات
        if (typeof userData === 'string') {
          parsedUser = JSON.parse(userData);
          // إذا كانت البيانات محفوظة في authData format
          if (parsedUser.user) {
            parsedUser = parsedUser.user;
          }
        } else {
          parsedUser = userData;
        }
        
        console.log('✅ Student Portal - Parsed User:', parsedUser.email, parsedUser.role);
        
        // التحقق من أن المستخدم طالب
        if (parsedUser.role !== 'student') {
          console.log('❌ User is not a student - redirecting based on role');
          if (parsedUser.role === 'admin') {
            router.push('/admin/dashboard');
          } else if (parsedUser.role === 'supervisor') {
            router.push('/admin/supervisor-dashboard');
          } else {
            router.push('/login');
          }
          return;
        }
        
        setUser(parsedUser);
        console.log('✅ Student Portal loaded successfully for:', parsedUser.email);
        
      } catch (error) {
        console.error('❌ Error parsing user data:', error);
        console.log('❌ Clearing localStorage and redirecting');
        localStorage.clear();
        router.push('/login');
        return;
      }
      
      setLoading(false);
    };

    fetchStudentData();
  }, [router]);

  // Handle window resize for mobile responsiveness
  useEffect(() => {
    const handleResize = () => {
      setIsMobile(window.innerWidth < 768);
    };

    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  const handleLogout = () => {
    console.log('🚪 Logging out - clearing all localStorage');
    localStorage.clear();
    router.push('/login');
  };

  const navigateToRegistration = () => {
    router.push('/student/registration');
  };

  const navigateToSupport = () => {
    router.push('/student/support');
  };

  const navigateToSubscription = () => {
    router.push('/student/subscription');
  };

  const navigateToTransportation = () => {
    router.push('/student/transportation');
  };

  const generateQRCode = async () => {
    try {
      const studentData = {
        id: user?.id || `student-${Date.now()}`,
        studentId: user?.studentId || 'Not assigned',
        fullName: user?.fullName || user?.email?.split('@')[0] || 'Student',
        email: user?.email || 'Not provided',
        phoneNumber: user?.phoneNumber || 'Not provided',
        college: user?.college || 'Not specified',
        grade: user?.grade || 'Not specified',
        major: user?.major || 'Not specified'
      };

      console.log('🔄 Generating QR for student:', studentData.email);

      const response = await fetch('/api/students/generate-qr', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ studentData }),
      });

      const data = await response.json();
      
      if (data.success) {
        const qrWindow = window.open('', '_blank', 'width=600,height=700');
        qrWindow.document.write(`
          <!DOCTYPE html>
          <html>
          <head>
            <title>Student QR Code</title>
            <style>
              body { 
                font-family: Arial, sans-serif; 
                padding: 20px; 
                text-align: center; 
                background: #f8f9fa;
              }
              .container {
                max-width: 500px;
                margin: 0 auto;
                background: white;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 4px 6px rgba(0,0,0,0.1);
              }
            </style>
          </head>
          <body>
            <div class="container">
              <h1>🎓 رمز QR للطالب</h1>
              <h3>${studentData.fullName}</h3>
              <p>البريد: ${studentData.email}</p>
              <div>
                <img src="${data.qrCodeDataURL || data.qrCode || data.data}" 
                     alt="Student QR Code" 
                     style="width: 300px; height: 300px; border: 2px solid #28a745;" />
              </div>
            </div>
          </body>
          </html>
        `);
        qrWindow.document.close();
      } else {
        alert('فشل في إنشاء رمز QR: ' + data.message);
      }
    } catch (error) {
      console.error('خطأ في إنشاء رمز QR:', error);
      alert('خطأ في إنشاء رمز QR');
    }
  };

  if (loading) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        flexDirection: 'column',
        gap: '20px',
        backgroundColor: '#f8fafc'
      }}>
        <div style={{ fontSize: '64px' }}>🔄</div>
        <div style={{ fontSize: '20px', color: '#666' }}>جاري تحميل بوابة الطلاب...</div>
      </div>
    );
  }

  if (!user) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        flexDirection: 'column',
        gap: '20px',
        backgroundColor: '#f8fafc'
      }}>
        <div style={{ fontSize: '64px' }}>❌</div>
        <div style={{ fontSize: '20px', color: '#666' }}>مطلوب تسجيل الدخول...</div>
      </div>
    );
  }

  return (
    <div style={{ 
      minHeight: '100vh', 
      backgroundColor: '#f8fafc',
      fontFamily: 'Cairo, Arial, sans-serif'
    }}>
      {/* Header */}
      <div style={{
        background: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)',
        padding: '24px',
        color: 'white',
        textAlign: 'center'
      }}>
        <div style={{ fontSize: '48px', marginBottom: '16px' }}>🎓</div>
        <h1 style={{ 
          margin: '0 0 8px 0', 
          fontSize: '32px', 
          fontWeight: '700' 
        }}>
          بوابة الطلاب
        </h1>
        <p style={{ 
          margin: '0 0 16px 0', 
          fontSize: '18px', 
          opacity: '0.9' 
        }}>
          مرحباً، {user?.fullName || user?.email?.split('@')[0]}
        </p>
        <div style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '12px',
          backgroundColor: 'rgba(255,255,255,0.1)',
          padding: '12px 20px',
          borderRadius: '25px',
          border: '1px solid rgba(255,255,255,0.2)'
        }}>
          <span style={{ fontSize: '16px' }}>📧</span>
          <span style={{ fontSize: '16px' }}>{user?.email}</span>
        </div>
      </div>

      {/* Navigation Cards */}
      <div style={{ 
        padding: '32px 24px',
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', 
        gap: '24px',
        maxWidth: '1200px',
        margin: '0 auto'
      }}>
        
        {/* Registration Card */}
        <div style={{
          backgroundColor: 'white',
          borderRadius: '16px',
          padding: '32px',
          textAlign: 'center',
          border: '1px solid #e2e8f0',
          cursor: 'pointer',
          transition: 'all 0.3s ease',
          boxShadow: '0 4px 6px rgba(0,0,0,0.07)'
        }}
        onClick={navigateToRegistration}
        onMouseOver={(e) => {
          e.currentTarget.style.transform = 'translateY(-8px)';
          e.currentTarget.style.boxShadow = '0 12px 30px rgba(0,0,0,0.15)';
        }}
        onMouseOut={(e) => {
          e.currentTarget.style.transform = 'translateY(0)';
          e.currentTarget.style.boxShadow = '0 4px 6px rgba(0,0,0,0.07)';
        }}
        >
          <div style={{ fontSize: '64px', marginBottom: '20px' }}>📝</div>
          <h3 style={{ 
            margin: '0 0 12px 0', 
            fontSize: '24px', 
            fontWeight: '700',
            color: '#1f2937'
          }}>
            التسجيل والحضور
          </h3>
          <p style={{ 
            margin: '0', 
            fontSize: '16px', 
            color: '#6b7280',
            lineHeight: '1.5'
          }}>
            إدارة بيانات التسجيل وتتبع الحضور
          </p>
        </div>

        {/* Subscription Card */}
        <div style={{
          backgroundColor: 'white',
          borderRadius: '16px',
          padding: '32px',
          textAlign: 'center',
          border: '1px solid #e2e8f0',
          cursor: 'pointer',
          transition: 'all 0.3s ease',
          boxShadow: '0 4px 6px rgba(0,0,0,0.07)'
        }}
        onClick={navigateToSubscription}
        onMouseOver={(e) => {
          e.currentTarget.style.transform = 'translateY(-8px)';
          e.currentTarget.style.boxShadow = '0 12px 30px rgba(0,0,0,0.15)';
        }}
        onMouseOut={(e) => {
          e.currentTarget.style.transform = 'translateY(0)';
          e.currentTarget.style.boxShadow = '0 4px 6px rgba(0,0,0,0.07)';
        }}
        >
          <div style={{ fontSize: '64px', marginBottom: '20px' }}>💳</div>
          <h3 style={{ 
            margin: '0 0 12px 0', 
            fontSize: '24px', 
            fontWeight: '700',
            color: '#1f2937'
          }}>
            الاشتراكات
          </h3>
          <p style={{ 
            margin: '0', 
            fontSize: '16px', 
            color: '#6b7280',
            lineHeight: '1.5'
          }}>
            إدارة اشتراك النقل الجامعي
          </p>
        </div>

        {/* Transportation Card */}
        <div style={{
          backgroundColor: 'white',
          borderRadius: '16px',
          padding: '32px',
          textAlign: 'center',
          border: '1px solid #e2e8f0',
          cursor: 'pointer',
          transition: 'all 0.3s ease',
          boxShadow: '0 4px 6px rgba(0,0,0,0.07)'
        }}
        onClick={navigateToTransportation}
        onMouseOver={(e) => {
          e.currentTarget.style.transform = 'translateY(-8px)';
          e.currentTarget.style.boxShadow = '0 12px 30px rgba(0,0,0,0.15)';
        }}
        onMouseOut={(e) => {
          e.currentTarget.style.transform = 'translateY(0)';
          e.currentTarget.style.boxShadow = '0 4px 6px rgba(0,0,0,0.07)';
        }}
        >
          <div style={{ fontSize: '64px', marginBottom: '20px' }}>🚌</div>
          <h3 style={{ 
            margin: '0 0 12px 0', 
            fontSize: '24px', 
            fontWeight: '700',
            color: '#1f2937'
          }}>
            النقل والمواصلات
          </h3>
          <p style={{ 
            margin: '0', 
            fontSize: '16px', 
            color: '#6b7280',
            lineHeight: '1.5'
          }}>
            مواعيد وخطوط النقل الجامعي
          </p>
        </div>

        {/* Support Card */}
        <div style={{
          backgroundColor: 'white',
          borderRadius: '16px',
          padding: '32px',
          textAlign: 'center',
          border: '1px solid #e2e8f0',
          cursor: 'pointer',
          transition: 'all 0.3s ease',
          boxShadow: '0 4px 6px rgba(0,0,0,0.07)'
        }}
        onClick={navigateToSupport}
        onMouseOver={(e) => {
          e.currentTarget.style.transform = 'translateY(-8px)';
          e.currentTarget.style.boxShadow = '0 12px 30px rgba(0,0,0,0.15)';
        }}
        onMouseOut={(e) => {
          e.currentTarget.style.transform = 'translateY(0)';
          e.currentTarget.style.boxShadow = '0 4px 6px rgba(0,0,0,0.07)';
        }}
        >
          <div style={{ fontSize: '64px', marginBottom: '20px' }}>🎧</div>
          <h3 style={{ 
            margin: '0 0 12px 0', 
            fontSize: '24px', 
            fontWeight: '700',
            color: '#1f2937'
          }}>
            الدعم الفني
          </h3>
          <p style={{ 
            margin: '0', 
            fontSize: '16px', 
            color: '#6b7280',
            lineHeight: '1.5'
          }}>
            المساعدة والدعم الفني
          </p>
        </div>

        {/* QR Code Generator */}
        <div style={{
          backgroundColor: 'white',
          borderRadius: '16px',
          padding: '32px',
          textAlign: 'center',
          border: '1px solid #e2e8f0',
          cursor: 'pointer',
          transition: 'all 0.3s ease',
          boxShadow: '0 4px 6px rgba(0,0,0,0.07)',
          gridColumn: isMobile ? 'span 1' : 'span 2'
        }}
        onClick={generateQRCode}
        onMouseOver={(e) => {
          e.currentTarget.style.transform = 'translateY(-8px)';
          e.currentTarget.style.boxShadow = '0 12px 30px rgba(0,0,0,0.15)';
        }}
        onMouseOut={(e) => {
          e.currentTarget.style.transform = 'translateY(0)';
          e.currentTarget.style.boxShadow = '0 4px 6px rgba(0,0,0,0.07)';
        }}
        >
          <div style={{ fontSize: '80px', marginBottom: '24px' }}>📱</div>
          <h3 style={{ 
            margin: '0 0 16px 0', 
            fontSize: '28px', 
            fontWeight: '700',
            color: '#1f2937'
          }}>
            إنشاء رمز QR
          </h3>
          <p style={{ 
            margin: '0 0 24px 0', 
            fontSize: '18px', 
            color: '#6b7280',
            lineHeight: '1.6'
          }}>
            أنشئ رمز QR الخاص بك للحضور والغياب في النقل الجامعي
          </p>
          <button style={{
            backgroundColor: '#28a745',
            color: 'white',
            border: 'none',
            padding: '16px 32px',
            borderRadius: '12px',
            cursor: 'pointer',
            fontSize: '18px',
            fontWeight: '600',
            boxShadow: '0 4px 12px rgba(40, 167, 69, 0.3)'
          }}>
            🚀 إنشاء رمز QR الآن
          </button>
        </div>
      </div>

      {/* Logout Button */}
      <div style={{ 
        padding: '24px',
        textAlign: 'center'
      }}>
        <button
          onClick={handleLogout}
          style={{
            padding: '16px 32px',
            backgroundColor: '#fee2e2',
            color: '#dc2626',
            border: '2px solid #fecaca',
            borderRadius: '12px',
            cursor: 'pointer',
            fontSize: '16px',
            fontWeight: '600',
            display: 'inline-flex',
            alignItems: 'center',
            gap: '8px'
          }}
        >
          <span style={{ fontSize: '18px' }}>🚪</span>
          تسجيل الخروج
        </button>
      </div>
    </div>
  );
}
EOF

echo "✅ تم إصلاح student portal"

echo ""
echo "🏗️ إعادة بناء Frontend:"
echo "======================="

cd frontend-new
rm -rf .next
npm run build

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ البناء نجح!"
    
    echo ""
    echo "🚀 إعادة تشغيل Frontend..."
    pm2 start unitrans-frontend
    
    echo ""
    echo "⏳ انتظار استقرار النظام..."
    sleep 8
    
    echo ""
    echo "🧪 اختبار student login نهائي:"
    echo "=============================="
    
    FINAL_TEST=$(curl -s -X POST https://unibus.online/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"test@test.com","password":"123456"}')
    
    echo "Student Login Response:"
    echo "$FINAL_TEST" | jq '.' 2>/dev/null || echo "$FINAL_TEST"
    
    echo ""
    echo "🌐 اختبار صفحة student portal:"
    curl -I https://unibus.online/student/portal -w "\n📊 Status: %{http_code}\n"
    
else
    echo "❌ البناء فشل!"
fi

echo ""
echo "📊 حالة النهائية:"
pm2 status

echo ""
echo "✅ إصلاح localStorage keys اكتمل!"
echo "🔗 جرب حساب الطالب: https://unibus.online/login"
echo "   📧 test@test.com / 123456"
echo "   🎯 الآن سيدخل مباشرة لـ student portal!"
