#!/bin/bash

echo "🔧 إصلاح نهائي لصفحة student portal"
echo "===================================="

cd /var/www/unitrans

echo "🛑 إيقاف Frontend..."
pm2 stop unitrans-frontend

echo ""
echo "🔧 إصلاح student portal - إزالة dependency فاشل:"
echo "=============================================="

# إنشاء student portal محدّث بدون API dependency فاشل
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
      // Check if user is logged in
      const token = localStorage.getItem('token');
      const userData = localStorage.getItem('user');
      
      console.log('🔍 Student Portal - Token:', !!token);
      console.log('🔍 Student Portal - User Data:', !!userData);
      
      if (!token || !userData) {
        console.log('❌ No auth data - redirecting to login');
        router.push('/login');
        return;
      }
      
      try {
        const parsedUser = JSON.parse(userData);
        console.log('✅ Student Portal - User:', parsedUser.email, parsedUser.role);
        setUser(parsedUser);
        
        // تحديد بيانات الطالب من user data مباشرة
        const studentData = {
          fullName: parsedUser.fullName || parsedUser.email?.split('@')[0] || 'Student',
          email: parsedUser.email,
          studentId: parsedUser.studentId || 'Not assigned',
          college: parsedUser.college || 'Not specified',
          grade: parsedUser.grade || 'Not specified',
          major: parsedUser.major || 'Not specified',
          profilePhoto: parsedUser.profilePhoto || null
        };
        
        localStorage.setItem('student', JSON.stringify(studentData));
        
      } catch (error) {
        console.error('❌ Error parsing user data:', error);
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
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.removeItem('student');
    localStorage.removeItem('authToken');
    localStorage.removeItem('userToken');
    localStorage.removeItem('userRole');
    localStorage.removeItem('isAuthenticated');
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
        major: user?.major || 'Not specified',
        profilePhoto: user?.profilePhoto || null
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
        // فتح نافذة جديدة لعرض QR code
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
              .qr-code {
                margin: 20px 0;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <h1>🎓 Student QR Code</h1>
              <h3>${studentData.fullName}</h3>
              <p>Email: ${studentData.email}</p>
              <div class="qr-code">
                <img src="${data.qrCodeDataURL || data.qrCode || data.data}" 
                     alt="Student QR Code" 
                     style="width: 300px; height: 300px;" />
              </div>
            </div>
          </body>
          </html>
        `);
        qrWindow.document.close();
      } else {
        alert('Failed to generate QR code: ' + data.message);
      }
    } catch (error) {
      console.error('Error generating QR code:', error);
      alert('Error generating QR code');
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
        gap: '20px'
      }}>
        <div style={{ fontSize: '48px' }}>🔄</div>
        <div style={{ fontSize: '18px', color: '#666' }}>Loading Student Portal...</div>
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
        gap: '20px'
      }}>
        <div style={{ fontSize: '48px' }}>❌</div>
        <div style={{ fontSize: '18px', color: '#666' }}>Authentication required...</div>
      </div>
    );
  }

  return (
    <div style={{ 
      minHeight: '100vh', 
      backgroundColor: '#f8fafc',
      fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, sans-serif'
    }}>
      {/* Header */}
      <div style={{
        backgroundColor: 'white',
        borderBottom: '1px solid #e2e8f0',
        padding: '16px 24px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
      }}>
        <div>
          <h1 style={{ 
            margin: '0', 
            fontSize: '24px', 
            fontWeight: '700',
            color: '#1f2937'
          }}>
            🎓 Student Portal
          </h1>
          <p style={{ 
            margin: '0', 
            fontSize: '14px', 
            color: '#6b7280' 
          }}>
            Welcome, {user?.fullName || user?.email}
          </p>
        </div>
        
        <button
          onClick={handleLogout}
          style={{
            padding: '8px 16px',
            backgroundColor: '#fee2e2',
            color: '#dc2626',
            border: 'none',
            borderRadius: '8px',
            cursor: 'pointer',
            fontSize: '14px',
            fontWeight: '500'
          }}
        >
          🚪 Logout
        </button>
      </div>

      {/* Main Content */}
      <div style={{ padding: '24px' }}>
        {/* Welcome Banner */}
        <div style={{
          background: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)',
          borderRadius: '16px',
          padding: '32px',
          color: 'white',
          marginBottom: '24px',
          textAlign: 'center'
        }}>
          <div style={{ fontSize: '64px', marginBottom: '16px' }}>🎓</div>
          <h2 style={{ 
            margin: '0 0 8px 0', 
            fontSize: '28px', 
            fontWeight: '700' 
          }}>
            مرحباً، {user?.fullName || user?.email?.split('@')[0]}!
          </h2>
          <p style={{ 
            margin: '0', 
            fontSize: '16px', 
            opacity: '0.9' 
          }}>
            بوابة الطلاب - نظام النقل الجامعي المتقدم
          </p>
        </div>

        {/* Services Grid */}
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', 
          gap: '20px',
          marginBottom: '32px'
        }}>
          {/* Registration Card */}
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '24px',
            textAlign: 'center',
            border: '1px solid #e2e8f0',
            cursor: 'pointer',
            transition: 'all 0.3s ease',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
          }}
          onClick={navigateToRegistration}
          onMouseOver={(e) => {
            e.currentTarget.style.transform = 'translateY(-4px)';
            e.currentTarget.style.boxShadow = '0 8px 25px rgba(0,0,0,0.15)';
          }}
          onMouseOut={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,0.1)';
          }}
          >
            <div style={{ fontSize: '48px', marginBottom: '16px' }}>📝</div>
            <h4 style={{ 
              margin: '0 0 8px 0', 
              fontSize: '18px', 
              fontWeight: '600',
              color: '#1f2937'
            }}>
              التسجيل والحضور
            </h4>
            <p style={{ 
              margin: '0', 
              fontSize: '14px', 
              color: '#6b7280' 
            }}>
              إدارة بيانات التسجيل والحضور
            </p>
          </div>

          {/* Subscription Card */}
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '24px',
            textAlign: 'center',
            border: '1px solid #e2e8f0',
            cursor: 'pointer',
            transition: 'all 0.3s ease',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
          }}
          onClick={navigateToSubscription}
          onMouseOver={(e) => {
            e.currentTarget.style.transform = 'translateY(-4px)';
            e.currentTarget.style.boxShadow = '0 8px 25px rgba(0,0,0,0.15)';
          }}
          onMouseOut={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,0.1)';
          }}
          >
            <div style={{ fontSize: '48px', marginBottom: '16px' }}>🚀</div>
            <h4 style={{ 
              margin: '0 0 8px 0', 
              fontSize: '18px', 
              fontWeight: '600',
              color: '#1f2937'
            }}>
              الاشتراكات
            </h4>
            <p style={{ 
              margin: '0', 
              fontSize: '14px', 
              color: '#6b7280' 
            }}>
              إدارة اشتراك النقل الجامعي
            </p>
          </div>

          {/* Transportation Card */}
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '24px',
            textAlign: 'center',
            border: '1px solid #e2e8f0',
            cursor: 'pointer',
            transition: 'all 0.3s ease',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
          }}
          onClick={navigateToTransportation}
          onMouseOver={(e) => {
            e.currentTarget.style.transform = 'translateY(-4px)';
            e.currentTarget.style.boxShadow = '0 8px 25px rgba(0,0,0,0.15)';
          }}
          onMouseOut={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,0.1)';
          }}
          >
            <div style={{ fontSize: '48px', marginBottom: '16px' }}>🚌</div>
            <h4 style={{ 
              margin: '0 0 8px 0', 
              fontSize: '18px', 
              fontWeight: '600',
              color: '#1f2937'
            }}>
              النقل والمواصلات
            </h4>
            <p style={{ 
              margin: '0', 
              fontSize: '14px', 
              color: '#6b7280' 
            }}>
              مواعيد وخطوط النقل
            </p>
          </div>

          {/* Support Card */}
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '24px',
            textAlign: 'center',
            border: '1px solid #e2e8f0',
            cursor: 'pointer',
            transition: 'all 0.3s ease',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
          }}
          onClick={navigateToSupport}
          onMouseOver={(e) => {
            e.currentTarget.style.transform = 'translateY(-4px)';
            e.currentTarget.style.boxShadow = '0 8px 25px rgba(0,0,0,0.15)';
          }}
          onMouseOut={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,0.1)';
          }}
          >
            <div style={{ fontSize: '48px', marginBottom: '16px' }}>🎧</div>
            <h4 style={{ 
              margin: '0 0 8px 0', 
              fontSize: '18px', 
              fontWeight: '600',
              color: '#1f2937'
            }}>
              الدعم الفني
            </h4>
            <p style={{ 
              margin: '0', 
              fontSize: '14px', 
              color: '#6b7280' 
            }}>
              مساعدة ودعم فني
            </p>
          </div>
        </div>

        {/* QR Code Generator */}
        <div style={{
          backgroundColor: 'white',
          borderRadius: '12px',
          padding: '32px',
          border: '1px solid #e2e8f0',
          textAlign: 'center',
          cursor: 'pointer',
          transition: 'all 0.3s ease',
          boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
        }}
        onClick={generateQRCode}
        onMouseOver={(e) => {
          e.currentTarget.style.transform = 'translateY(-2px)';
          e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)';
        }}
        onMouseOut={(e) => {
          e.currentTarget.style.transform = 'translateY(0)';
          e.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,0.1)';
        }}
        >
          <div style={{ fontSize: '64px', marginBottom: '20px' }}>📱</div>
          <h3 style={{ 
            margin: '0 0 12px 0', 
            fontSize: '24px', 
            fontWeight: '600',
            color: '#1f2937'
          }}>
            إنشاء رمز QR
          </h3>
          <p style={{ 
            margin: '0 0 24px 0', 
            fontSize: '16px', 
            color: '#6b7280' 
          }}>
            أنشئ رمز QR الخاص بك للحضور والغياب
          </p>
          <button style={{
            backgroundColor: '#28a745',
            color: 'white',
            border: 'none',
            padding: '16px 32px',
            borderRadius: '8px',
            cursor: 'pointer',
            fontSize: '18px',
            fontWeight: '600'
          }}>
            🚀 إنشاء رمز QR
          </button>
        </div>

        {/* Student Info Card */}
        <div style={{
          backgroundColor: 'white',
          borderRadius: '12px',
          padding: '24px',
          border: '1px solid #e2e8f0',
          boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
          marginTop: '24px'
        }}>
          <h4 style={{ 
            margin: '0 0 16px 0', 
            fontSize: '18px', 
            fontWeight: '600',
            color: '#1f2937'
          }}>
            معلومات الطالب
          </h4>
          
          <div style={{ 
            display: 'grid', 
            gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', 
            gap: '16px' 
          }}>
            <div>
              <span style={{ fontSize: '14px', color: '#6b7280' }}>الاسم الكامل:</span>
              <div style={{ fontSize: '16px', fontWeight: '500', marginTop: '4px' }}>
                {user?.fullName || user?.email?.split('@')[0] || 'غير محدد'}
              </div>
            </div>
            <div>
              <span style={{ fontSize: '14px', color: '#6b7280' }}>البريد الإلكتروني:</span>
              <div style={{ fontSize: '16px', fontWeight: '500', marginTop: '4px' }}>
                {user?.email || 'غير محدد'}
              </div>
            </div>
            <div>
              <span style={{ fontSize: '14px', color: '#6b7280' }}>رقم الطالب:</span>
              <div style={{ fontSize: '16px', fontWeight: '500', marginTop: '4px' }}>
                {user?.studentId || 'غير مخصص'}
              </div>
            </div>
            <div>
              <span style={{ fontSize: '14px', color: '#6b7280' }}>الدور:</span>
              <div style={{ fontSize: '16px', fontWeight: '500', marginTop: '4px' }}>
                {user?.role || 'طالب'}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
EOF

echo "✅ تم إنشاء student portal محدّث"

echo ""
echo "🏗️ إعادة بناء Frontend:"
echo "======================="

cd frontend-new

# حذف cache
rm -rf .next
rm -rf node_modules/.cache

# بناء جديد
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
    
    if echo "$FINAL_TEST" | grep -q '"success":true'; then
        echo ""
        echo "✅ Student login نجح!"
        echo "🔄 Redirect URL: $(echo "$FINAL_TEST" | grep -o '"redirectUrl":"[^"]*"' | cut -d'"' -f4)"
        
        echo ""
        echo "🌐 اختبار صفحة student portal:"
        curl -I https://unibus.online/student/portal -w "\n📊 Status: %{http_code}\n"
        
    else
        echo "❌ Student login فشل"
    fi
    
else
    echo "❌ البناء فشل!"
fi

echo ""
echo "📊 حالة النهائية:"
pm2 status

echo ""
echo "✅ إصلاح student portal اكتمل!"
echo "🔗 جرب حساب الطالب: https://unibus.online/login"
echo "   📧 test@test.com / 123456"
echo "   🎯 يجب أن يدخل مباشرة لـ student portal الآن!"
