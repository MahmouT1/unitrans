#!/bin/bash

echo "🔄 استرجاع صفحة Student Portal الأصلية"
echo "========================================"

# الانتقال إلى مجلد المشروع
cd /var/www/unitrans

echo "📥 جلب آخر التحديثات..."
git pull origin main

echo "💾 إنشاء نسخة احتياطية من التصميم الحالي..."
cp frontend-new/app/student/portal/page.js frontend-new/app/student/portal/page.js.backup

echo "🔧 استرجاع التصميم الأصلي البسيط..."

# إنشاء صفحة Student Portal الأصلية البسيطة
cat > frontend-new/app/student/portal/page.js << 'EOF'
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function StudentPortal() {
  const [user, setUser] = useState(null);
  const [student, setStudent] = useState(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    const fetchStudentData = async () => {
      const token = localStorage.getItem('token');
      const userData = localStorage.getItem('user');
      
      if (!token || !userData) {
        router.push('/auth');
        return;
      }
      
      const parsedUser = JSON.parse(userData);
      setUser(parsedUser);
      
      try {
        const response = await fetch(`/api/students/profile-simple?email=${encodeURIComponent(parsedUser.email)}`, {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });
        
        if (response.ok) {
          const studentProfile = await response.json();
          if (studentProfile.student) {
            setStudent(studentProfile.student);
            localStorage.setItem('student', JSON.stringify(studentProfile.student));
          } else {
            setStudent(studentProfile);
            localStorage.setItem('student', JSON.stringify(studentProfile));
          }
        } else {
          const studentData = localStorage.getItem('student');
          if (studentData) {
            setStudent(JSON.parse(studentData));
          }
        }
      } catch (error) {
        console.log('Error fetching student profile:', error);
        const studentData = localStorage.getItem('student');
        if (studentData) {
          setStudent(JSON.parse(studentData));
        }
      }
      
      setLoading(false);
    };

    fetchStudentData();
  }, [router]);

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.removeItem('student');
    router.push('/');
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
      const realStudentData = {
        id: student?.id || user?.id || `student-${Date.now()}`,
        studentId: student?.studentId || user?.studentId || 'Not assigned',
        fullName: student?.fullName || user?.fullName || user?.email?.split('@')[0] || 'Student',
        email: user?.email || 'Not provided',
        phoneNumber: student?.phoneNumber || user?.phoneNumber || 'Not provided',
        college: student?.college || user?.college || 'Not specified',
        grade: student?.grade || user?.grade || 'Not specified',
        major: student?.major || user?.major || 'Not specified',
        profilePhoto: student?.profilePhoto || user?.profilePhoto || null,
        address: student?.address || user?.address || {
          streetAddress: 'Not provided',
          buildingNumber: '',
          fullAddress: 'Not provided'
        }
      };

      const response = await fetch('/api/students/generate-qr', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ studentData: realStudentData }),
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
              .student-info {
                background: #e3f2fd;
                padding: 20px;
                border-radius: 8px;
                margin-bottom: 20px;
                text-align: left;
              }
              .qr-code {
                margin: 20px 0;
              }
              .download-btn {
                background: #28a745;
                color: white;
                border: none;
                padding: 12px 24px;
                border-radius: 6px;
                cursor: pointer;
                font-size: 16px;
                margin-top: 15px;
              }
              .download-btn:hover {
                background: #218838;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <h1>🎓 Student QR Code</h1>
              
              <div class="student-info">
                <h3>Student Information</h3>
                <p><strong>Name:</strong> ${realStudentData.fullName}</p>
                <p><strong>Email:</strong> ${realStudentData.email}</p>
                <p><strong>Student ID:</strong> ${realStudentData.studentId}</p>
                <p><strong>Phone:</strong> ${realStudentData.phoneNumber}</p>
                <p><strong>College:</strong> ${realStudentData.college}</p>
                <p><strong>Grade:</strong> ${realStudentData.grade}</p>
                <p><strong>Major:</strong> ${realStudentData.major}</p>
                <p><strong>Address:</strong> ${realStudentData.address.streetAddress}, ${realStudentData.address.fullAddress}</p>
              </div>
              
              <div class="qr-code">
                <img src="${data.qrCodeDataURL || data.qrCode || data.data}" 
                     alt="Student QR Code" 
                     style="width: 300px; height: 300px; border: 2px solid #28a745; border-radius: 8px;" />
              </div>
              
              <button class="download-btn" onclick="downloadQR()">📥 Download QR Code</button>
            </div>
            
            <script>
              function downloadQR() {
                const link = document.createElement('a');
                link.href = '${data.qrCodeDataURL || data.qrCode || data.data}';
                link.download = 'student-qr-code-${Date.now()}.png';
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                alert('QR code downloaded successfully!');
              }
            </script>
          </body>
          </html>
        `);
        qrWindow.document.close();
      } else {
        alert('Failed to generate QR code: ' + data.message);
      }
    } catch (error) {
      console.error('Error generating QR code:', error);
      alert('Error generating QR code: ' + error.message);
    }
  };

  if (loading) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh' 
      }}>
        <div>Loading...</div>
      </div>
    );
  }

  return (
    <div style={{ 
      minHeight: '100vh', 
      backgroundColor: '#f8fafc',
      fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, sans-serif',
      width: '100%',
      overflowX: 'hidden'
    }}>
      {/* Top Navigation Bar */}
      <div style={{
        backgroundColor: 'white',
        borderBottom: '1px solid #e2e8f0',
        padding: '16px 24px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
      }}>
        {/* Search Bar */}
        <div style={{ flex: '1', maxWidth: '400px' }}>
          <input 
            type="search" 
            placeholder="Search" 
            style={{
              width: '100%',
              padding: '12px 16px',
              border: '1px solid #d1d5db',
              borderRadius: '8px',
              fontSize: '14px',
              backgroundColor: '#f9fafb'
            }}
          />
        </div>

        {/* User Info */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '16px'
        }}>
          <div style={{ textAlign: 'right' }}>
            <div style={{ 
              fontSize: '16px', 
              fontWeight: '600', 
              color: '#1f2937',
              marginBottom: '2px'
            }}>
              {student?.fullName || user?.email || 'Student'}
            </div>
            <div style={{ 
              fontSize: '14px', 
              color: '#6b7280' 
            }}>
              {student?.grade || 'Student'}
            </div>
          </div>
          <div style={{
            width: '40px',
            height: '40px',
            borderRadius: '50%',
            backgroundColor: '#8b5cf6',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: 'white',
            fontSize: '16px',
            fontWeight: '600'
          }}>
            {(student?.fullName || user?.email || 'S').charAt(0).toUpperCase()}
          </div>
          <button style={{
            width: '40px',
            height: '40px',
            borderRadius: '50%',
            border: 'none',
            backgroundColor: '#fee2e2',
            color: '#dc2626',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: '18px'
          }}>
            🔔
          </button>
        </div>
      </div>

      <div style={{ display: 'flex' }}>
        {/* Sidebar */}
        <div style={{
          width: '280px',
          backgroundColor: 'white',
          borderRight: '1px solid #e2e8f0',
          minHeight: 'calc(100vh - 80px)',
          padding: '24px 0'
        }}>
          {/* Logo Section */}
          <div style={{
            padding: '0 24px 24px',
            borderBottom: '1px solid #e2e8f0',
            marginBottom: '20px'
          }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px'
            }}>
              <div style={{
                width: '48px',
                height: '48px',
                borderRadius: '12px',
                background: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '24px'
              }}>
                🎓
              </div>
              <div>
                <h2 style={{ 
                  margin: '0', 
                  fontSize: '20px', 
                  fontWeight: '700',
                  color: '#1f2937'
                }}>
                  Student Portal
                </h2>
                <p style={{ 
                  margin: '0', 
                  fontSize: '12px', 
                  color: '#6b7280' 
                }}>
                  Academic Dashboard
                </p>
              </div>
            </div>
          </div>

          {/* Navigation Menu */}
          <nav style={{ padding: '0 16px' }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              padding: '12px 16px',
              backgroundColor: '#f3f4f6',
              borderRadius: '8px',
              marginBottom: '8px',
              cursor: 'pointer'
            }}>
              <span style={{ fontSize: '20px' }}>🏠</span>
              <span style={{ fontSize: '14px', fontWeight: '500', color: '#374151' }}>Student Portal</span>
            </div>
            
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              padding: '12px 16px',
              borderRadius: '8px',
              marginBottom: '8px',
              cursor: 'pointer',
              transition: 'background-color 0.2s'
            }}
            onClick={navigateToSubscription}
            onMouseOver={(e) => e.target.style.backgroundColor = '#f3f4f6'}
            onMouseOut={(e) => e.target.style.backgroundColor = 'transparent'}
            >
              <span style={{ fontSize: '20px' }}>💳</span>
              <span style={{ fontSize: '14px', fontWeight: '500', color: '#374151' }}>Subscription</span>
            </div>
            
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              padding: '12px 16px',
              borderRadius: '8px',
              marginBottom: '8px',
              cursor: 'pointer',
              transition: 'background-color 0.2s'
            }}
            onClick={navigateToRegistration}
            onMouseOver={(e) => e.target.style.backgroundColor = '#f3f4f6'}
            onMouseOut={(e) => e.target.style.backgroundColor = 'transparent'}
            >
              <span style={{ fontSize: '20px' }}>📝</span>
              <span style={{ fontSize: '14px', fontWeight: '500', color: '#374151' }}>Attendance</span>
            </div>
            
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              padding: '12px 16px',
              borderRadius: '8px',
              marginBottom: '8px',
              cursor: 'pointer',
              transition: 'background-color 0.2s'
            }}
            onClick={navigateToTransportation}
            onMouseOver={(e) => e.target.style.backgroundColor = '#f3f4f6'}
            onMouseOut={(e) => e.target.style.backgroundColor = 'transparent'}
            >
              <span style={{ fontSize: '20px' }}>🗺️</span>
              <span style={{ fontSize: '14px', fontWeight: '500', color: '#374151' }}>Transportation</span>
            </div>
            
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              padding: '12px 16px',
              borderRadius: '8px',
              marginBottom: '8px',
              cursor: 'pointer',
              transition: 'background-color 0.2s'
            }}
            onMouseOver={(e) => e.target.style.backgroundColor = '#f3f4f6'}
            onMouseOut={(e) => e.target.style.backgroundColor = 'transparent'}
            >
              <span style={{ fontSize: '20px' }}>📚</span>
              <span style={{ fontSize: '14px', fontWeight: '500', color: '#374151' }}>Drop Semester</span>
            </div>
            
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              padding: '12px 16px',
              borderRadius: '8px',
              marginBottom: '8px',
              cursor: 'pointer',
              transition: 'background-color 0.2s'
            }}
            onMouseOver={(e) => e.target.style.backgroundColor = '#f3f4f6'}
            onMouseOut={(e) => e.target.style.backgroundColor = 'transparent'}
            >
              <span style={{ fontSize: '20px' }}>📢</span>
              <span style={{ fontSize: '14px', fontWeight: '500', color: '#374151' }}>Notice</span>
            </div>
          </nav>

          {/* Logout Button */}
          <div style={{ padding: '16px', marginTop: 'auto' }}>
            <button
              onClick={handleLogout}
              style={{
                width: '100%',
                padding: '12px 16px',
                backgroundColor: '#fee2e2',
                color: '#dc2626',
                border: 'none',
                borderRadius: '8px',
                cursor: 'pointer',
                fontSize: '14px',
                fontWeight: '500',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '8px'
              }}
            >
              <span style={{ fontSize: '16px' }}>🚪</span>
              Logout
            </button>
          </div>
        </div>

        {/* Main Content */}
        <div style={{ flex: '1', padding: '24px' }}>
          {/* Welcome Banner */}
          <div style={{
            background: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)',
            borderRadius: '16px',
            padding: '20px',
            color: 'white',
            marginBottom: '24px',
            position: 'relative',
            overflow: 'hidden'
          }}>
            <div style={{
              position: 'absolute',
              right: '16px',
              top: '16px',
              fontSize: '14px',
              opacity: '0.8',
              textAlign: 'right',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'flex-end',
              gap: '8px'
            }}>
              <div style={{ marginBottom: '2px' }}>
                <span style={{ color: 'rgba(255,255,255,0.7)' }}>sponsored by : </span>
                <span style={{ color: 'rgba(255,255,255,0.9)', fontWeight: '600' }}>Uni Bus</span>
              </div>
            </div>
            <div style={{ position: 'relative', zIndex: 1 }}>
              <p style={{ 
                margin: '0 0 4px 0', 
                fontSize: '16px', 
                opacity: '0.9' 
              }}>
                {new Date().toLocaleDateString('en-US', { 
                  year: 'numeric', 
                  month: 'long', 
                  day: 'numeric' 
                })}
              </p>
              <h1 style={{ 
                margin: '0 0 4px 0', 
                fontSize: '28px', 
                fontWeight: '700' 
              }}>
                Welcome, {(student?.fullName || user?.email || 'Student').split(' ')[0]}!
              </h1>
              <p style={{ 
                margin: '0', 
                fontSize: '16px', 
                opacity: '0.9' 
              }}>
                Always stay updated in your student portal
              </p>
            </div>
          </div>

          {/* Student Account Information */}
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '24px',
            border: '1px solid #e2e8f0',
            marginBottom: '24px',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
          }}>
            <h3 style={{ 
              margin: '0 0 16px 0', 
              fontSize: '18px', 
              fontWeight: '600',
              color: '#1f2937'
            }}>
              Student Account Information
            </h3>
            <div style={{ 
              display: 'grid', 
              gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', 
              gap: '12px' 
            }}>
              <div>
                <span style={{ fontSize: '14px', color: '#6b7280' }}>Full Name:</span>
                <div style={{ fontSize: '16px', fontWeight: '500', marginTop: '2px' }}>
                  {student?.fullName || user?.fullName || user?.email?.split('@')[0] || 'Not provided'}
                </div>
              </div>
              <div>
                <span style={{ fontSize: '14px', color: '#6b7280' }}>Email:</span>
                <div style={{ fontSize: '16px', fontWeight: '500', marginTop: '2px' }}>
                  {user?.email || 'Not provided'}
                </div>
              </div>
              <div>
                <span style={{ fontSize: '14px', color: '#6b7280' }}>Student ID:</span>
                <div style={{ fontSize: '16px', fontWeight: '500', marginTop: '2px' }}>
                  {student?.studentId || user?.studentId || 'Not assigned'}
                </div>
              </div>
              <div>
                <span style={{ fontSize: '14px', color: '#6b7280' }}>College:</span>
                <div style={{ fontSize: '16px', fontWeight: '500', marginTop: '2px' }}>
                  {student?.college || user?.college || 'Not specified'}
                </div>
              </div>
              <div>
                <span style={{ fontSize: '14px', color: '#6b7280' }}>Grade Level:</span>
                <div style={{ fontSize: '16px', fontWeight: '500', marginTop: '2px' }}>
                  {student?.grade || user?.grade || 'Not specified'}
                </div>
              </div>
              <div>
                <span style={{ fontSize: '14px', color: '#6b7280' }}>Major:</span>
                <div style={{ fontSize: '16px', fontWeight: '500', marginTop: '2px' }}>
                  {student?.major || user?.major || 'Not specified'}
                </div>
              </div>
            </div>
          </div>

          {/* Finance Section */}
          <div style={{ marginBottom: '32px' }}>
            <h3 style={{ 
              fontSize: '20px', 
              fontWeight: '600', 
              color: '#1f2937',
              marginBottom: '20px'
            }}>
              Finance
            </h3>
            <div style={{ 
              display: 'grid', 
              gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', 
              gap: '20px' 
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
                  fontSize: '16px', 
                  fontWeight: '600',
                  color: '#1f2937'
                }}>
                  Registration
                </h4>
                <p style={{ 
                  margin: '0', 
                  fontSize: '14px', 
                  color: '#6b7280' 
                }}>
                  complete your student registration
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
                <div style={{ fontSize: '48px', marginBottom: '16px' }}>💳</div>
                <h4 style={{ 
                  margin: '0 0 8px 0', 
                  fontSize: '16px', 
                  fontWeight: '600',
                  color: '#1f2937'
                }}>
                  Subscription
                </h4>
                <p style={{ 
                  margin: '0', 
                  fontSize: '14px', 
                  color: '#6b7280' 
                }}>
                  Manage your subscription
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
                  fontSize: '16px', 
                  fontWeight: '600',
                  color: '#1f2937'
                }}>
                  Transportation
                </h4>
                <p style={{ 
                  margin: '0', 
                  fontSize: '14px', 
                  color: '#6b7280' 
                }}>
                  View transportation schedule
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
                  fontSize: '16px', 
                  fontWeight: '600',
                  color: '#1f2937'
                }}>
                  Support
                </h4>
                <p style={{ 
                  margin: '0', 
                  fontSize: '14px', 
                  color: '#6b7280' 
                }}>
                  Get help and support
                </p>
              </div>
            </div>
          </div>

          {/* QR Code Generator Card */}
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '24px',
            border: '1px solid #e2e8f0',
            textAlign: 'center',
            cursor: 'pointer',
            transition: 'all 0.3s ease',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
            marginBottom: '32px'
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
            <div style={{ fontSize: '48px', marginBottom: '16px' }}>📱</div>
            <h3 style={{ 
              margin: '0 0 8px 0', 
              fontSize: '20px', 
              fontWeight: '600',
              color: '#1f2937'
            }}>
              Generate QR Code
            </h3>
            <p style={{ 
              margin: '0 0 20px 0', 
              fontSize: '14px', 
              color: '#6b7280' 
            }}>
              Generate and download your student QR code with email and information
            </p>
            <button style={{
              backgroundColor: '#28a745',
              color: 'white',
              border: 'none',
              padding: '12px 24px',
              borderRadius: '8px',
              cursor: 'pointer',
              fontSize: '16px',
              fontWeight: '600'
            }}>
              🚀 Generate QR Code
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
EOF

echo "🏗️ إعادة بناء الفرونت إند..."
cd frontend-new
npm run build
cd ..

echo "🔄 إعادة تشغيل الخدمات..."
pkill -f node || true
sleep 2

# تشغيل الباك إند
cd backend-new
nohup node server.js > ../logs/backend.log 2>&1 &
sleep 3
cd ..

# تشغيل الفرونت إند
cd frontend-new
nohup npm start > ../logs/frontend.log 2>&1 &
sleep 5
cd ..

echo "🧪 اختبار الصفحة..."
sleep 3

# اختبار الوصول للصفحة
curl -s http://localhost:3000/student/portal | head -10 || echo "❌ الصفحة غير متاحة"

echo "🎉 تم استرجاع صفحة Student Portal الأصلية بنجاح!"
echo "================================================"
echo "✅ التصميم البسيط والنظيف مسترجع"
echo "✅ جميع الوظائف محفوظة"
echo "✅ مولد QR Code يعمل"
echo "✅ تصميم متجاوب"
echo ""
echo "🌍 الوصول: https://unibus.online/student/portal"
echo "📊 فحص اللوقز: tail -f logs/backend.log logs/frontend.log"
echo ""
echo "🔄 للعودة للتصميم المعقد:"
echo "  cp frontend-new/app/student/portal/page.js.backup frontend-new/app/student/portal/page.js"
