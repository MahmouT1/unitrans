#!/bin/bash

echo "🔧 Restoring Original Student Portal Design"

cd /home/unitrans/frontend-new

# Backup current file
cp app/student/portal/page.js app/student/portal/page.js.backup

# Restore original student portal design
cat > app/student/portal/page.js << 'EOF'
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useLanguage } from '../../../lib/contexts/LanguageContext';
import LanguageSwitcher from '../../../components/LanguageSwitcher';

export default function StudentPortal() {
  const [user, setUser] = useState(null);
  const [student, setStudent] = useState(null);
  const [loading, setLoading] = useState(true);
  const [isMobile, setIsMobile] = useState(false);
  const router = useRouter();
  const { t, isRTL } = useLanguage();

  useEffect(() => {
    const fetchStudentData = async () => {
      // Check if user is logged in
      const token = localStorage.getItem('token');
      const userData = localStorage.getItem('user');
      const studentData = localStorage.getItem('student');
      
      if (!token || !userData) {
        router.push('/login');
        return;
      }
      
      const parsedUser = JSON.parse(userData);
      setUser(parsedUser);
      
      // Try to fetch fresh student data from API
      try {
        const response = await fetch(`/api/students/data?email=${encodeURIComponent(parsedUser.email)}`, {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });
        
        if (response.ok) {
          const studentProfile = await response.json();
          console.log('Fetched student profile:', studentProfile);
          if (studentProfile.student) {
            console.log('Student profile photo:', studentProfile.student.profilePhoto);
            setStudent(studentProfile.student);
            // Update localStorage with fresh data
            localStorage.setItem('student', JSON.stringify(studentProfile.student));
          } else {
            console.log('Student profile photo (direct):', studentProfile.profilePhoto);
            setStudent(studentProfile);
            localStorage.setItem('student', JSON.stringify(studentProfile));
          }
        } else {
          console.log('Failed to fetch student profile, using localStorage data');
          if (studentData) {
            setStudent(JSON.parse(studentData));
          }
        }
      } catch (error) {
        console.log('Error fetching student profile:', error);
        if (studentData) {
          setStudent(JSON.parse(studentData));
        }
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

    // Set initial value
    handleResize();

    // Add event listener
    window.addEventListener('resize', handleResize);

    // Cleanup
    return () => window.removeEventListener('resize', handleResize);
  }, []);

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

  const navigateToTransportation = () => {
    router.push('/student/transportation');
  };

  const navigateToQRGenerator = () => {
    router.push('/student/qr-generator');
  };

  const generateQRCode = async () => {
    try {
      if (!student) {
        alert('Please complete your registration first');
        return;
      }

      const response = await fetch('/api/students/generate-qr', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        },
        body: JSON.stringify({ 
          studentData: {
            id: student._id || student.id,
            studentId: student.studentId,
            fullName: student.fullName,
            email: student.email,
            phoneNumber: student.phoneNumber,
            college: student.college,
            grade: student.grade,
            major: student.major,
            address: student.address,
            profilePhoto: student.profilePhoto
          }
        })
      });

      if (response.ok) {
        const data = await response.json();
        if (data.success) {
          // Open QR code in new window
          const qrWindow = window.open('', '_blank');
          qrWindow.document.write(`
            <html>
              <head>
                <title>Student QR Code</title>
                <style>
                  body { 
                    font-family: Arial, sans-serif; 
                    text-align: center; 
                    padding: 20px;
                    background: #f5f5f5;
                  }
                  .qr-container {
                    background: white;
                    padding: 30px;
                    border-radius: 10px;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                    max-width: 400px;
                    margin: 0 auto;
                  }
                  .qr-code {
                    margin: 20px 0;
                  }
                  .student-info {
                    margin-top: 20px;
                    text-align: left;
                    background: #f8f9fa;
                    padding: 15px;
                    border-radius: 5px;
                  }
                  .print-btn {
                    background: #007bff;
                    color: white;
                    border: none;
                    padding: 10px 20px;
                    border-radius: 5px;
                    cursor: pointer;
                    margin-top: 15px;
                  }
                </style>
              </head>
              <body>
                <div class="qr-container">
                  <h2>Student QR Code</h2>
                  <div class="qr-code">
                    <img src="${data.qrCodeDataURL || data.qrCode || data.data}" alt="QR Code" style="max-width: 200px;" />
                  </div>
                  <div class="student-info">
                    <p><strong>Name:</strong> ${student.fullName}</p>
                    <p><strong>Student ID:</strong> ${student.studentId || 'Not assigned'}</p>
                    <p><strong>College:</strong> ${student.college || 'Not specified'}</p>
                    <p><strong>Grade:</strong> ${student.grade || 'Not specified'}</p>
                  </div>
                  <button class="print-btn" onclick="window.print()">Print QR Code</button>
                </div>
              </body>
            </html>
          `);
        } else {
          alert('Error generating QR code: ' + data.message);
        }
      } else {
        const errorData = await response.json();
        alert('Error generating QR code: ' + errorData.message);
      }
    } catch (error) {
      console.error('QR generation error:', error);
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
        padding: isMobile ? '12px 16px' : '16px 24px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
        flexWrap: isMobile ? 'wrap' : 'nowrap',
        gap: isMobile ? '12px' : '0'
      }}>
        {/* Search Bar */}
        <div style={{ flex: '1', maxWidth: isMobile ? '100%' : '400px', order: isMobile ? '2' : '1' }}>
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
          gap: '12px',
          order: isMobile ? '1' : '2'
        }}>
          <LanguageSwitcher variant="student" />
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px'
          }}>
            {student?.profilePhoto ? (
              <img 
                src={student.profilePhoto} 
                alt="Profile" 
                style={{
                  width: '32px',
                  height: '32px',
                  borderRadius: '50%',
                  objectFit: 'cover'
                }}
              />
            ) : (
              <div style={{
                width: '32px',
                height: '32px',
                borderRadius: '50%',
                backgroundColor: '#e5e7eb',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '14px',
                color: '#6b7280'
              }}>
                {user?.fullName?.charAt(0) || user?.email?.charAt(0) || 'U'}
              </div>
            )}
            <span style={{ fontSize: '14px', color: '#374151' }}>
              {user?.fullName || user?.email}
            </span>
            <button 
              onClick={handleLogout}
              style={{
                padding: '8px 12px',
                backgroundColor: '#ef4444',
                color: 'white',
                border: 'none',
                borderRadius: '6px',
                fontSize: '12px',
                cursor: 'pointer'
              }}
            >
              Logout
            </button>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div style={{
        padding: isMobile ? '16px' : '24px',
        maxWidth: '1200px',
        margin: '0 auto'
      }}>
        {/* Welcome Section */}
        <div style={{
          backgroundColor: 'white',
          borderRadius: '12px',
          padding: isMobile ? '20px' : '24px',
          marginBottom: '24px',
          boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
          border: '1px solid #e2e8f0'
        }}>
          <h1 style={{
            fontSize: isMobile ? '24px' : '32px',
            fontWeight: 'bold',
            color: '#1f2937',
            margin: '0 0 8px 0'
          }}>
            Welcome, {user?.fullName || user?.email}!
          </h1>
          <p style={{
            fontSize: '16px',
            color: '#6b7280',
            margin: '0'
          }}>
            {student ? 'Manage your student profile and access all features' : 'Complete your registration to access all features'}
          </p>
        </div>

        {/* Quick Actions */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: isMobile ? '1fr' : 'repeat(auto-fit, minmax(250px, 1fr))',
          gap: '16px',
          marginBottom: '24px'
        }}>
          {/* Registration Card */}
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '20px',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
            border: '1px solid #e2e8f0',
            cursor: 'pointer',
            transition: 'all 0.2s ease',
            borderLeft: '4px solid #10b981'
          }}
          onClick={navigateToRegistration}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'translateY(-2px)';
            e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,0.1)';
          }}>
            <div style={{ display: 'flex', alignItems: 'center', marginBottom: '12px' }}>
              <div style={{
                width: '40px',
                height: '40px',
                backgroundColor: '#10b981',
                borderRadius: '8px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                marginRight: '12px'
              }}>
                <span style={{ fontSize: '20px' }}>📝</span>
              </div>
              <div>
                <h3 style={{ margin: '0', fontSize: '18px', color: '#1f2937' }}>
                  {student ? 'Update Registration' : 'Complete Registration'}
                </h3>
                <p style={{ margin: '0', fontSize: '14px', color: '#6b7280' }}>
                  {student ? 'Update your student information' : 'Register as a student'}
                </p>
              </div>
            </div>
          </div>

          {/* QR Code Card */}
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '20px',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
            border: '1px solid #e2e8f0',
            cursor: 'pointer',
            transition: 'all 0.2s ease',
            borderLeft: '4px solid #f59e0b'
          }}
          onClick={student ? generateQRCode : navigateToQRGenerator}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'translateY(-2px)';
            e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,0.1)';
          }}>
            <div style={{ display: 'flex', alignItems: 'center', marginBottom: '12px' }}>
              <div style={{
                width: '40px',
                height: '40px',
                backgroundColor: '#f59e0b',
                borderRadius: '8px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                marginRight: '12px'
              }}>
                <span style={{ fontSize: '20px' }}>📱</span>
              </div>
              <div>
                <h3 style={{ margin: '0', fontSize: '18px', color: '#1f2937' }}>
                  QR Code
                </h3>
                <p style={{ margin: '0', fontSize: '14px', color: '#6b7280' }}>
                  {student ? 'Generate your QR code' : 'Complete registration first'}
                </p>
              </div>
            </div>
          </div>

          {/* Transportation Card */}
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '20px',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
            border: '1px solid #e2e8f0',
            cursor: 'pointer',
            transition: 'all 0.2s ease',
            borderLeft: '4px solid #8b5cf6'
          }}
          onClick={navigateToTransportation}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'translateY(-2px)';
            e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,0.1)';
          }}>
            <div style={{ display: 'flex', alignItems: 'center', marginBottom: '12px' }}>
              <div style={{
                width: '40px',
                height: '40px',
                backgroundColor: '#8b5cf6',
                borderRadius: '8px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                marginRight: '12px'
              }}>
                <span style={{ fontSize: '20px' }}>🚌</span>
              </div>
              <div>
                <h3 style={{ margin: '0', fontSize: '18px', color: '#1f2937' }}>
                  Transportation
                </h3>
                <p style={{ margin: '0', fontSize: '14px', color: '#6b7280' }}>
                  View bus schedules and routes
                </p>
              </div>
            </div>
          </div>

          {/* Support Card */}
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '20px',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
            border: '1px solid #e2e8f0',
            cursor: 'pointer',
            transition: 'all 0.2s ease',
            borderLeft: '4px solid #3b82f6'
          }}
          onClick={navigateToSupport}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'translateY(-2px)';
            e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,0.1)';
          }}>
            <div style={{ display: 'flex', alignItems: 'center', marginBottom: '12px' }}>
              <div style={{
                width: '40px',
                height: '40px',
                backgroundColor: '#3b82f6',
                borderRadius: '8px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                marginRight: '12px'
              }}>
                <span style={{ fontSize: '20px' }}>🆘</span>
              </div>
              <div>
                <h3 style={{ margin: '0', fontSize: '18px', color: '#1f2937' }}>
                  Support
                </h3>
                <p style={{ margin: '0', fontSize: '14px', color: '#6b7280' }}>
                  Get help and support
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Student Profile Section */}
        {student && (
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: isMobile ? '20px' : '24px',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
            border: '1px solid #e2e8f0'
          }}>
            <h2 style={{
              fontSize: '20px',
              fontWeight: 'bold',
              color: '#1f2937',
              margin: '0 0 20px 0'
            }}>
              Your Profile
            </h2>
            
            <div style={{
              display: 'grid',
              gridTemplateColumns: isMobile ? '1fr' : 'repeat(auto-fit, minmax(300px, 1fr))',
              gap: '20px'
            }}>
              {/* Personal Information */}
              <div>
                <h3 style={{
                  fontSize: '16px',
                  fontWeight: '600',
                  color: '#374151',
                  margin: '0 0 12px 0'
                }}>
                  Personal Information
                </h3>
                <div style={{ display: 'grid', gap: '8px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ color: '#6b7280' }}>Name:</span>
                    <span style={{ color: '#1f2937', fontWeight: '500' }}>{student.fullName}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ color: '#6b7280' }}>Email:</span>
                    <span style={{ color: '#1f2937', fontWeight: '500' }}>{student.email}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ color: '#6b7280' }}>Phone:</span>
                    <span style={{ color: '#1f2937', fontWeight: '500' }}>{student.phoneNumber || 'Not provided'}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ color: '#6b7280' }}>Student ID:</span>
                    <span style={{ color: '#1f2937', fontWeight: '500' }}>{student.studentId || 'Not assigned'}</span>
                  </div>
                </div>
              </div>

              {/* Academic Information */}
              <div>
                <h3 style={{
                  fontSize: '16px',
                  fontWeight: '600',
                  color: '#374151',
                  margin: '0 0 12px 0'
                }}>
                  Academic Information
                </h3>
                <div style={{ display: 'grid', gap: '8px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ color: '#6b7280' }}>College:</span>
                    <span style={{ color: '#1f2937', fontWeight: '500' }}>{student.college || 'Not specified'}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ color: '#6b7280' }}>Grade:</span>
                    <span style={{ color: '#1f2937', fontWeight: '500' }}>{student.grade || 'Not specified'}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ color: '#6b7280' }}>Major:</span>
                    <span style={{ color: '#1f2937', fontWeight: '500' }}>{student.major || 'Not specified'}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ color: '#6b7280' }}>Address:</span>
                    <span style={{ color: '#1f2937', fontWeight: '500' }}>{student.address || 'Not provided'}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
EOF

# Rebuild frontend
echo "🏗️ Rebuilding frontend..."
npm run build

# Restart frontend
echo "🔄 Restarting frontend..."
pm2 stop unitrans-frontend
pm2 start "npm run start" --name "unitrans-frontend"

echo "✅ Original student portal design restored!"
echo "🌍 Test at: https://unibus.online/student/portal"
