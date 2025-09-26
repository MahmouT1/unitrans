#!/bin/bash

echo "🔧 Restoring Original Student Portal Design with Purple Background"

cd /home/unitrans/frontend-new

# Backup current file
cp app/student/portal/page.js app/student/portal/page.js.backup2

# Restore the original student portal design with purple background
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
        height: '100vh',
        background: 'linear-gradient(180deg, #8B5CF6 0%, #6D28D9 100%)',
        color: 'white'
      }}>
        <div>Loading...</div>
      </div>
    );
  }

  return (
    <div style={{ 
      minHeight: '100vh', 
      background: 'linear-gradient(180deg, #8B5CF6 0%, #6D28D9 100%)',
      fontFamily: 'Poppins, sans-serif',
      color: 'white',
      width: '100%',
      overflowX: 'hidden'
    }}>
      {/* Top Bar */}
      <div style={{
        padding: isMobile ? '12px 16px' : '16px 24px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
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
              padding: '10px 15px',
              border: 'none',
              borderRadius: '20px',
              fontSize: '14px',
              backgroundColor: '#f0f0f5',
              outline: 'none'
            }}
          />
        </div>

        {/* User Info */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '15px',
          order: isMobile ? '1' : '2'
        }}>
          <LanguageSwitcher variant="student" />
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px'
          }}>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontWeight: 'bold', display: 'block' }}>
                {user?.fullName || user?.email}
              </div>
              <div style={{ fontSize: '12px', color: 'rgba(255,255,255,0.7)' }}>
                {student?.grade || 'N/A'}
              </div>
            </div>
            {student?.profilePhoto ? (
              <img 
                src={student.profilePhoto} 
                alt="Profile" 
                style={{
                  width: '40px',
                  height: '40px',
                  borderRadius: '50%',
                  objectFit: 'cover'
                }}
              />
            ) : (
              <div style={{
                width: '40px',
                height: '40px',
                borderRadius: '50%',
                backgroundColor: 'rgba(255,255,255,0.2)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '16px',
                color: 'white'
              }}>
                {user?.fullName?.charAt(0) || user?.email?.charAt(0) || 'U'}
              </div>
            )}
            <button 
              onClick={handleLogout}
              style={{
                background: '#fff',
                border: 'none',
                padding: '8px',
                borderRadius: '50%',
                boxShadow: '0 2px 5px rgba(0,0,0,0.1)',
                cursor: 'pointer'
              }}
            >
              🚪
            </button>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div style={{
        padding: isMobile ? '16px' : '25px',
        maxWidth: '1200px',
        margin: '0 auto'
      }}>
        {/* Welcome Banner */}
        <div style={{
          background: 'linear-gradient(90deg, #7a3cff, #a16dff)',
          borderRadius: '15px',
          padding: '20px',
          color: 'white',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '25px',
          flexWrap: 'wrap',
          gap: '15px'
        }}>
          <div>
            <p style={{ fontSize: '14px', opacity: '0.8', margin: '0 0 5px 0' }}>
              {new Date().toLocaleDateString('en-US', { 
                year: 'numeric', 
                month: 'long', 
                day: 'numeric' 
              })}
            </p>
            <h2 style={{ fontSize: '22px', margin: '5px 0', fontWeight: 'bold' }}>
              Welcome back, {user?.fullName?.split(' ')[0] || user?.email?.split('@')[0] || 'Student'}!
            </h2>
            <p style={{ margin: '0', opacity: '0.9' }}>
              Always stay updated in your student portal!
            </p>
          </div>
          
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: '12px', opacity: '0.9' }}>
              sponsored by : Uni Bus
            </div>
          </div>
        </div>

        {/* Student Account Information */}
        {student && (
          <div style={{
            backgroundColor: 'rgba(255,255,255,0.1)',
            borderRadius: '15px',
            padding: '20px',
            marginBottom: '25px',
            border: '1px solid rgba(255,255,255,0.2)'
          }}>
            <h3 style={{ 
              margin: '0 0 15px 0', 
              fontSize: '18px', 
              fontWeight: '600',
              opacity: '0.95'
            }}>
              Student Account Information
            </h3>
            
            <div style={{ 
              display: 'grid',
              gridTemplateColumns: isMobile ? '1fr' : 'repeat(2, 1fr)',
              gap: '15px'
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ opacity: '0.8' }}>Full Name:</span>
                <span style={{ fontWeight: '500' }}>{student.fullName}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ opacity: '0.8' }}>Email:</span>
                <span style={{ fontWeight: '500' }}>{student.email}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ opacity: '0.8' }}>Major:</span>
                <span style={{ fontWeight: '500' }}>{student.major || 'Not specified'}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ opacity: '0.8' }}>Student ID:</span>
                <span style={{ fontWeight: '500' }}>{student.studentId || 'Not assigned'}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ opacity: '0.8' }}>College:</span>
                <span style={{ fontWeight: '500' }}>{student.college || 'Not specified'}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ opacity: '0.8' }}>Grade Level:</span>
                <span style={{ fontWeight: '500' }}>{student.grade || 'Not specified'}</span>
              </div>
            </div>

            {/* Debug Info */}
            <div style={{ marginTop: '20px', padding: '15px', backgroundColor: 'rgba(255,255,255,0.05)', borderRadius: '8px' }}>
              <h4 style={{ margin: '0 0 10px 0', fontSize: '14px', opacity: '0.8' }}>Debug Info:</h4>
              <div style={{ fontSize: '12px', opacity: '0.7' }}>
                <div>User Data: Loaded</div>
                <div>Student Data: Loaded</div>
                <div>User Email: {user?.email}</div>
                <div>Student Name: {student.fullName}</div>
              </div>
              <button 
                onClick={() => {
                  // Save test data functionality
                  console.log('Saving test data...');
                }}
                style={{
                  marginTop: '10px',
                  padding: '8px 16px',
                  background: 'rgba(255,255,255,0.2)',
                  color: 'white',
                  border: 'none',
                  borderRadius: '6px',
                  cursor: 'pointer',
                  fontSize: '12px'
                }}
              >
                Save Test Data
              </button>
            </div>
          </div>
        )}

        {/* Finance Section */}
        <div style={{ marginBottom: '25px' }}>
          <h3 style={{ marginBottom: '15px', textAlign: 'center', fontSize: '18px' }}>Finance</h3>
          <div style={{
            display: 'grid',
            gridTemplateColumns: isMobile ? 'repeat(2, 1fr)' : 'repeat(3, 1fr)',
            gap: '15px',
            marginBottom: '20px'
          }}>
            {/* Registration Card */}
            <div style={{
              backgroundColor: 'white',
              borderRadius: '12px',
              padding: '20px',
              textAlign: 'center',
              cursor: 'pointer',
              transition: 'transform 0.2s ease',
              color: '#333'
            }}
            onClick={navigateToRegistration}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-2px)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
            }}>
              <div style={{ fontSize: '32px', marginBottom: '10px' }}>📝</div>
              <div style={{ fontWeight: '600' }}>Registration</div>
            </div>

            {/* Subscriptions Card */}
            <div style={{
              backgroundColor: 'white',
              borderRadius: '12px',
              padding: '20px',
              textAlign: 'center',
              cursor: 'pointer',
              transition: 'transform 0.2s ease',
              color: '#333'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-2px)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
            }}>
              <div style={{ fontSize: '32px', marginBottom: '10px' }}>💳</div>
              <div style={{ fontWeight: '600' }}>Subscriptions</div>
            </div>

            {/* Help Center Card */}
            <div style={{
              backgroundColor: 'white',
              borderRadius: '12px',
              padding: '20px',
              textAlign: 'center',
              cursor: 'pointer',
              transition: 'transform 0.2s ease',
              color: '#333'
            }}
            onClick={navigateToSupport}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-2px)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
            }}>
              <div style={{ fontSize: '32px', marginBottom: '10px' }}>🎧</div>
              <div style={{ fontWeight: '600' }}>Help Center</div>
            </div>
          </div>

          {/* Subscription Plan Card */}
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '20px',
            marginBottom: '15px',
            color: '#333',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center'
          }}>
            <div>
              <h4 style={{ margin: '0 0 5px 0', fontSize: '16px', fontWeight: '600' }}>
                Your subscription plan
              </h4>
              <p style={{ margin: '0', fontSize: '14px', opacity: '0.7' }}>
                Manage your current plan
              </p>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <div style={{ fontSize: '24px' }}>🚀</div>
              <button style={{
                background: '#8B5CF6',
                color: 'white',
                border: 'none',
                padding: '8px 16px',
                borderRadius: '6px',
                cursor: 'pointer',
                fontSize: '14px'
              }}>
                View
              </button>
            </div>
          </div>

          {/* Transportation Card */}
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '20px',
            color: '#333',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            cursor: 'pointer'
          }}
          onClick={navigateToTransportation}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'translateY(-2px)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
          }}>
            <div>
              <h4 style={{ margin: '0 0 5px 0', fontSize: '16px', fontWeight: '600' }}>
                Dates and locations Transportation
              </h4>
              <p style={{ margin: '0', fontSize: '14px', opacity: '0.7' }}>
                View schedules and routes
              </p>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <div style={{ fontSize: '24px' }}>📅</div>
              <button style={{
                background: '#8B5CF6',
                color: 'white',
                border: 'none',
                padding: '8px 16px',
                borderRadius: '6px',
                cursor: 'pointer',
                fontSize: '14px'
              }}>
                View
              </button>
            </div>
          </div>
        </div>
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

echo "✅ Original student portal design with purple background restored!"
echo "🌍 Test at: https://unibus.online/student/portal"
