#!/bin/bash

echo "🔧 Restoring Complete Original Student Portal with Sidebar and QR Code"

cd /home/unitrans/frontend-new

# Backup current file
cp app/student/portal/page.js app/student/portal/page.js.backup3

# Restore the complete original student portal design
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

  const navigateToSubscription = () => {
    router.push('/student/subscription');
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

      // Prepare real student data for QR code
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

      console.log('Sending real student data for QR generation:', realStudentData);

      const response = await fetch('/api/students/generate-qr', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        },
        body: JSON.stringify({ studentData: realStudentData }),
      });

      const data = await response.json();
      
      if (data.success) {
        // Create a new window/tab to show the QR code
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
                <p><strong>College:</strong> ${realStudentData.college}</p>
                <p><strong>Grade:</strong> ${realStudentData.grade}</p>
                <p><strong>Major:</strong> ${realStudentData.major}</p>
              </div>
              
              <div class="qr-code">
                <img src="${data.qrCodeDataURL || data.qrCode || data.data}" alt="QR Code" style="max-width: 300px;" />
              </div>
              
              <button class="download-btn" onclick="window.print()">Print QR Code</button>
            </div>
          </body>
          </html>
        `);
      } else {
        alert('Error generating QR code: ' + data.message);
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

      <div style={{ display: 'flex', flexDirection: isMobile ? 'column' : 'row' }}>
        {/* Sidebar */}
        <div style={{
          width: isMobile ? '100%' : '280px',
          backgroundColor: 'white',
          borderRight: isMobile ? 'none' : '1px solid #e2e8f0',
          minHeight: isMobile ? 'auto' : 'calc(100vh - 80px)',
          padding: isMobile ? '16px 0' : '24px 0'
        }}>
          {/* Logo Section */}
          <div style={{
            padding: isMobile ? '0 16px 16px' : '0 24px 24px',
            borderBottom: '1px solid #e2e8f0',
            marginBottom: isMobile ? '16px' : '20px'
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
            <div style={{ marginTop: '15px', display: 'flex', justifyContent: 'center' }}>
              <LanguageSwitcher variant="compact" />
            </div>
          </div>

          {/* Navigation Menu */}
          <nav style={{ padding: isMobile ? '0 12px' : '0 16px' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {/* Dashboard */}
              <button
                style={{
                  width: '100%',
                  padding: '12px 16px',
                  border: 'none',
                  borderRadius: '8px',
                  background: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)',
                  color: 'white',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  fontSize: '14px',
                  fontWeight: '600',
                  transition: 'all 0.2s ease'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.transform = 'translateX(4px)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.transform = 'translateX(0)';
                }}
              >
                <span style={{ fontSize: '18px' }}>🏠</span>
                Dashboard
              </button>

              {/* Registration */}
              <button
                onClick={navigateToRegistration}
                style={{
                  width: '100%',
                  padding: '12px 16px',
                  border: 'none',
                  borderRadius: '8px',
                  background: 'transparent',
                  color: '#374151',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  fontSize: '14px',
                  fontWeight: '500',
                  transition: 'all 0.2s ease'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.background = '#f3f4f6';
                  e.currentTarget.style.transform = 'translateX(4px)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.background = 'transparent';
                  e.currentTarget.style.transform = 'translateX(0)';
                }}
              >
                <span style={{ fontSize: '18px' }}>📝</span>
                Registration
              </button>

              {/* QR Code Generator */}
              <button
                onClick={generateQRCode}
                style={{
                  width: '100%',
                  padding: '12px 16px',
                  border: 'none',
                  borderRadius: '8px',
                  background: 'transparent',
                  color: '#374151',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  fontSize: '14px',
                  fontWeight: '500',
                  transition: 'all 0.2s ease'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.background = '#f3f4f6';
                  e.currentTarget.style.transform = 'translateX(4px)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.background = 'transparent';
                  e.currentTarget.style.transform = 'translateX(0)';
                }}
              >
                <span style={{ fontSize: '18px' }}>📱</span>
                Generate QR Code
              </button>

              {/* Transportation */}
              <button
                onClick={navigateToTransportation}
                style={{
                  width: '100%',
                  padding: '12px 16px',
                  border: 'none',
                  borderRadius: '8px',
                  background: 'transparent',
                  color: '#374151',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  fontSize: '14px',
                  fontWeight: '500',
                  transition: 'all 0.2s ease'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.background = '#f3f4f6';
                  e.currentTarget.style.transform = 'translateX(4px)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.background = 'transparent';
                  e.currentTarget.style.transform = 'translateX(0)';
                }}
              >
                <span style={{ fontSize: '18px' }}>🚌</span>
                Transportation
              </button>

              {/* Subscription */}
              <button
                onClick={navigateToSubscription}
                style={{
                  width: '100%',
                  padding: '12px 16px',
                  border: 'none',
                  borderRadius: '8px',
                  background: 'transparent',
                  color: '#374151',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  fontSize: '14px',
                  fontWeight: '500',
                  transition: 'all 0.2s ease'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.background = '#f3f4f6';
                  e.currentTarget.style.transform = 'translateX(4px)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.background = 'transparent';
                  e.currentTarget.style.transform = 'translateX(0)';
                }}
              >
                <span style={{ fontSize: '18px' }}>💳</span>
                Subscription
              </button>

              {/* Support */}
              <button
                onClick={navigateToSupport}
                style={{
                  width: '100%',
                  padding: '12px 16px',
                  border: 'none',
                  borderRadius: '8px',
                  background: 'transparent',
                  color: '#374151',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  fontSize: '14px',
                  fontWeight: '500',
                  transition: 'all 0.2s ease'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.background = '#f3f4f6';
                  e.currentTarget.style.transform = 'translateX(4px)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.background = 'transparent';
                  e.currentTarget.style.transform = 'translateX(0)';
                }}
              >
                <span style={{ fontSize: '18px' }}>🆘</span>
                Support
              </button>
            </div>
          </nav>
        </div>

        {/* Main Content */}
        <div style={{
          flex: '1',
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
              onClick={navigateToSubscription}
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

echo "✅ Complete original student portal with sidebar and QR code restored!"
echo "🌍 Test at: https://unibus.online/student/portal"
