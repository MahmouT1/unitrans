'use client';

import React, { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import AccurateQRScanner from '../../../components/AccurateQRScanner';
import SubscriptionPaymentModal from '../../../components/SubscriptionPaymentModal';
import '../../../components/admin/SupervisorDashboard.css';

const SupervisorDashboard = () => {
  const [user, setUser] = useState(null);
  const router = useRouter();
  const videoRef = useRef(null);
  const qrScannerRef = useRef(null);

  const [returnDate, setReturnDate] = useState('');
  const [firstAppointmentCount, setFirstAppointmentCount] = useState(0);
  const [secondAppointmentCount, setSecondAppointmentCount] = useState(0);
  const [activeTab, setActiveTab] = useState('qr-scanner');
  const [isScanning, setIsScanning] = useState(false);
  const [scannedStudent, setScannedStudent] = useState(null);
  const [autoRegistered, setAutoRegistered] = useState(false);
  const [showPaymentForm, setShowPaymentForm] = useState(false);
  const [scanError, setScanError] = useState('');
  const [cameras, setCameras] = useState([]);
  const [selectedCamera, setSelectedCamera] = useState('');

  // Shift management states
  const [currentShift, setCurrentShift] = useState(null);
  const [shiftLoading, setShiftLoading] = useState(false);
  const [shiftResult, setShiftResult] = useState(null);
  
  // Live attendance data
  const [liveAttendance, setLiveAttendance] = useState([]);
  const [attendanceCount, setAttendanceCount] = useState(0);
  const [showAttendanceDetails, setShowAttendanceDetails] = useState(false);

  // Notification system
  const [notification, setNotification] = useState(null);

  const [paymentData, setPaymentData] = useState({
    email: '',
    paymentMethod: 'credit_card',
    amount: ''
  });

  // Show notification function
  const showNotification = (type, title, message, duration = 5000) => {
    setNotification({
      type, // 'success' or 'error'
      title,
      message,
      id: Date.now()
    });

    // Auto-hide notification after duration
    setTimeout(() => {
      setNotification(null);
    }, duration);
  };

  // Check authentication
  useEffect(() => {
    const userData = localStorage.getItem('user');
    if (userData) {
      const parsedUser = JSON.parse(userData);
      setUser(parsedUser);
      
      // Check user role
      if (parsedUser.role !== 'admin' && parsedUser.role !== 'supervisor') {
        showNotification('error', 'Access Denied', 'You do not have permission to access this page.');
        router.push('/auth');
      }
    } else {
      router.push('/auth');
    }
  }, [router]);

  // Load active shift on component mount
  useEffect(() => {
    if (user) {
      loadActiveShift();
    }
  }, [user]);

  // Auto-refresh live attendance every 10 seconds when shift is active
  useEffect(() => {
    let interval;
    if (currentShift && currentShift.status === 'active') {
      interval = setInterval(() => {
        loadLiveAttendance();
      }, 10000); // Refresh every 10 seconds
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [currentShift]);

  // Load active shift
  const loadActiveShift = async () => {
    try {
      const response = await fetch('https://unibus.online:3001/api/shifts/active', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        if (data.shifts && data.shifts.length > 0) {
          const activeShift = data.shifts[0];
          setCurrentShift(activeShift);
          // Load live attendance for this shift
          loadLiveAttendance(activeShift.id);
        } else {
          setCurrentShift(null);
        }
      }
    } catch (error) {
      console.error('Error loading active shift:', error);
    }
  };

  // Load live attendance for current shift
  const loadLiveAttendance = async (shiftId = null) => {
    if (!currentShift && !shiftId) return;
    
    const targetShiftId = shiftId || currentShift.id;
    
    try {
      const response = await fetch(`https://unibus.online:3001/api/shifts/${targetShiftId}/attendance`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        setLiveAttendance(data.attendance || []);
        setAttendanceCount(data.attendance ? data.attendance.length : 0);
      }
    } catch (error) {
      console.error('Error loading live attendance:', error);
    }
  };

  // Open shift function
  const openShift = async () => {
    if (!user) {
      showNotification('error', 'Authentication Error', 'User not authenticated');
      return;
    }

    setShiftLoading(true);
    setShiftResult(null);

    try {
      const response = await fetch('https://unibus.online:3001/api/shifts', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          supervisorId: user._id || user.id,
          supervisorName: user.fullName || user.name || user.email,
          location: 'Main Campus',
          status: 'active'
        }),
      });

      const data = await response.json();

      if (response.ok) {
        setCurrentShift(data.shift);
        setShiftResult({
          type: 'success',
          message: 'Shift opened successfully!'
        });
        showNotification('success', 'Shift Opened', 'Your shift has been started successfully. You can now scan QR codes.');
        
        // Start loading live attendance
        loadLiveAttendance(data.shift.id);
      } else {
        setShiftResult({
          type: 'error',
          message: data.message || 'Failed to open shift'
        });
        showNotification('error', 'Shift Error', data.message || 'Failed to open shift');
      }
    } catch (error) {
      console.error('Open shift error:', error);
      setShiftResult({
        type: 'error',
        message: 'Network error occurred'
      });
      showNotification('error', 'Network Error', 'Failed to connect to server');
    } finally {
      setShiftLoading(false);
    }
  };

  // Close shift function
  const closeShift = async () => {
    if (!currentShift) {
      showNotification('error', 'No Active Shift', 'No active shift to close');
      return;
    }

    const confirmClose = window.confirm('Are you sure you want to close this shift? This action cannot be undone. Shift ID: ' + (currentShift.id || currentShift._id));
    
    if (!confirmClose) return;

    setShiftLoading(true);

    try {
      const shiftId = currentShift.id || currentShift._id;
      const response = await fetch(`https://unibus.online:3001/api/shifts/${shiftId}/close`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          endTime: new Date().toISOString(),
          status: 'completed'
        }),
      });

      const data = await response.json();

      if (response.ok) {
        setCurrentShift(null);
        setLiveAttendance([]);
        setAttendanceCount(0);
        setShowAttendanceDetails(false);
        setShiftResult({
          type: 'success',
          message: 'Shift closed successfully!'
        });
        showNotification('success', 'Shift Closed', 'Your shift has been closed successfully. All attendance records have been saved.');
      } else {
        setShiftResult({
          type: 'error',
          message: data.message || 'Failed to close shift'
        });
        showNotification('error', 'Close Shift Error', data.message || 'Failed to close shift');
      }
    } catch (error) {
      console.error('Close shift error:', error);
      setShiftResult({
        type: 'error',
        message: 'Network error occurred'
      });
      showNotification('error', 'Network Error', 'Failed to connect to server');
    } finally {
      setShiftLoading(false);
    }
  };

  // QR Scanner handlers
  const handleQRCodeScanned = async (data) => {
    if (!currentShift) {
      showNotification('error', 'No Active Shift', 'Please open a shift first before scanning QR codes');
      return;
    }

    try {
      // Parse QR data
      let qrData;
      try {
        qrData = JSON.parse(data);
      } catch (e) {
        qrData = { studentId: data };
      }

      if (!qrData.studentId && !qrData.id) {
        showNotification('error', 'Invalid QR Code', 'QR code does not contain valid student information');
        return;
      }

      // Fetch complete student data from database using student ID
      const studentResponse = await fetch(`https://unibus.online:3001/api/students/data?email=${encodeURIComponent(qrData.email)}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        }
      });

      if (studentResponse.ok) {
        const dbStudentResult = await studentResponse.json();
        if (dbStudentResult.success && dbStudentResult.student) {
          const dbStudent = dbStudentResult.student;

          // Fetch subscription data
          const subscriptionResponse = await fetch(`https://unibus.online:3001/api/subscription/payment?studentEmail=${encodeURIComponent(qrData.email)}`, {
            method: 'GET',
            headers: {
              'Content-Type': 'application/json',
            }
          });

          let subscriptionData = {
            status: 'Active',
            startDate: new Date().toISOString(),
            endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
          };

          if (subscriptionResponse.ok) {
            const subResult = await subscriptionResponse.json();
            if (subResult.success && subResult.subscription) {
              subscriptionData = subResult.subscription;
            }
          }

          // Set complete student data from database
          setScannedStudent({
            id: dbStudent._id || dbStudent.id,
            studentId: dbStudent.studentId,
            name: dbStudent.fullName,
            email: dbStudent.email,
            phoneNumber: dbStudent.phoneNumber,
            college: dbStudent.college,
            grade: dbStudent.grade,
            major: dbStudent.major,
            academicYear: dbStudent.academicYear,
            address: dbStudent.address,
            photo: dbStudent.profilePhoto, // Profile photo from database
            attendanceStats: dbStudent.attendanceStats || {
              daysRegistered: 0,
              remainingDays: 180,
              attendanceRate: 0
            },
            subscription: subscriptionData,
            status: dbStudent.status
          });

          console.log('Complete student data loaded:', dbStudent);
        }
      }

      // Register attendance
      const response = await fetch('https://unibus.online:3001/api/shifts/scan', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          shiftId: currentShift.id || currentShift._id,
          qrData: qrData,
          supervisorId: user._id || user.id,
          location: currentShift.location || 'Main Campus'
        }),
      });

      const result = await response.json();

      if (response.ok) {
        // Show success notification
        showNotification('success', 'Attendance Registered', `Successfully registered attendance for ${result.studentData?.name || qrData.fullName || 'student'}`);
        
        // Refresh live attendance
        loadLiveAttendance();
        
        // Set autoRegistered flag
        setAutoRegistered(true);
        
        // Switch to student details tab
        setActiveTab('student-details');
        
        // Clear after 3 seconds
        setTimeout(() => {
          setAutoRegistered(false);
        }, 3000);
      } else {
        showNotification('error', 'Attendance Error', result.message || 'Failed to register attendance');
      }
    } catch (error) {
      console.error('QR scan error:', error);
      showNotification('error', 'Scan Error', 'Failed to process QR code');
    }
  };

  const handleScanError = (error) => {
    console.error('QR Scanner Error:', error);
    setScanError('Camera error: ' + error.message);
  };

  const startScanning = () => {
    if (!currentShift) {
      showNotification('error', 'No Active Shift', 'Please open a shift first before scanning QR codes');
      return;
    }
    setIsScanning(true);
    setScanError('');
  };

  const stopScanning = () => {
    setIsScanning(false);
  };

  // Go to admin attendance page
  const goToAdminAttendance = () => {
    router.push('/admin/attendance');
  };

  // Handle subscription payment
  const handleSubscriptionPayment = () => {
    setShowPaymentForm(true);
  };

  const handlePaymentComplete = (paymentResult) => {
    console.log('Payment completed:', paymentResult);
    setShowPaymentForm(false);
    showNotification(
      'success',
      'Payment Processed Successfully!',
      `Payment of ${paymentResult.amount} EGP processed successfully for ${scannedStudent?.name}`
    );
  };

  const handleBackToScanner = () => {
    setScannedStudent(null);
    setShowPaymentForm(false);
    setScanError('');
    setActiveTab('qr-scanner');
  };

  if (!user) {
    return (
      <div style={{ padding: '20px', textAlign: 'center' }}>
        <p>Loading...</p>
      </div>
    );
  }

  return (
    <div style={{ 
      minHeight: '100vh', 
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      padding: '20px'
    }}>
      {/* Notification */}
      {notification && (
        <div style={{
          position: 'fixed',
          top: '20px',
          right: '20px',
          background: notification.type === 'success' ? '#10B981' : '#EF4444',
          color: 'white',
          padding: '15px 20px',
          borderRadius: '8px',
          boxShadow: '0 4px 12px rgba(0,0,0,0.3)',
          zIndex: 1000,
          maxWidth: '400px'
        }}>
          <h4 style={{ margin: '0 0 5px 0', fontSize: '16px' }}>{notification.title}</h4>
          <p style={{ margin: '0', fontSize: '14px' }}>{notification.message}</p>
        </div>
      )}

      <div style={{ 
        maxWidth: '1200px', 
        margin: '0 auto',
        background: 'rgba(255, 255, 255, 0.95)',
        borderRadius: '20px',
        padding: '30px',
        boxShadow: '0 20px 40px rgba(0,0,0,0.2)'
      }}>
        {/* Header */}
        <div style={{ 
          textAlign: 'center', 
          marginBottom: '30px',
          borderBottom: '3px solid #667eea',
          paddingBottom: '20px'
        }}>
          <h1 style={{ 
            margin: '0 0 10px 0', 
            fontSize: '32px', 
            fontWeight: '700',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            backgroundClip: 'text'
          }}>
            👨‍💼 Supervisor Dashboard
          </h1>
          <p style={{ 
            margin: '0', 
            fontSize: '16px', 
            color: '#6b7280',
            fontWeight: '500'
          }}>
            Welcome, {user.fullName || user.name || user.email}
          </p>
        </div>

        {/* Shift Status Section */}
        <div style={{
          background: 'linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%)',
          borderRadius: '15px',
          padding: '25px',
          marginBottom: '30px',
          border: '2px solid #e2e8f0'
        }}>
          <h2 style={{ 
            margin: '0 0 20px 0', 
            fontSize: '24px', 
            fontWeight: '600',
            color: '#1f2937',
            display: 'flex',
            alignItems: 'center',
            gap: '10px'
          }}>
            🕐 Shift Status
          </h2>

          {currentShift ? (
            <div style={{
              background: 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
              color: 'white',
              padding: '20px',
              borderRadius: '12px',
              marginBottom: '20px'
            }}>
              <h3 style={{ margin: '0 0 15px 0', fontSize: '20px' }}>✅ Active Shift</h3>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '15px' }}>
                <div>
                  <strong>Status:</strong> {currentShift.status || 'Active'}
                </div>
                <div>
                  <strong>Started:</strong> {new Date(currentShift.startTime || currentShift.createdAt).toLocaleString()}
                </div>
                <div>
                  <strong>Location:</strong> {currentShift.location || 'Main Campus'}
                </div>
                <div>
                  <strong>Supervisor:</strong> {currentShift.supervisorName || user.fullName || user.name}
                </div>
                <div>
                  <strong>Shift ID:</strong> {currentShift.id || currentShift._id}
                </div>
                <div>
                  <strong>Total Scans:</strong> {attendanceCount}
                </div>
              </div>
            </div>
          ) : (
            <div style={{
              background: '#f3f4f6',
              border: '2px dashed #d1d5db',
              borderRadius: '12px',
              padding: '20px',
              textAlign: 'center',
              color: '#6b7280',
              marginBottom: '20px'
            }}>
              <p style={{ fontSize: '18px', margin: '0 0 10px 0' }}>
                No active shift. Click "Open Shift" to start working.
              </p>
              <p style={{ fontSize: '14px', margin: '0' }}>
                Shifts stay open until manually closed by the supervisor.
              </p>
            </div>
          )}

          {/* Shift Controls */}
          <div style={{ display: 'flex', gap: '15px', flexWrap: 'wrap', justifyContent: 'center' }}>
            {!currentShift ? (
              <button
                onClick={openShift}
                disabled={shiftLoading}
                style={{
                  background: 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
                  color: 'white',
                  border: '3px solid #059669',
                  padding: '15px 30px',
                  borderRadius: '12px',
                  fontSize: '18px',
                  fontWeight: '700',
                  cursor: shiftLoading ? 'not-allowed' : 'pointer',
                  transition: 'all 0.3s ease',
                  boxShadow: '0 4px 12px rgba(16, 185, 129, 0.3)',
                  textTransform: 'uppercase',
                  letterSpacing: '0.5px'
                }}
                onMouseOver={(e) => {
                  if (!shiftLoading) {
                    e.target.style.transform = 'translateY(-2px)';
                    e.target.style.boxShadow = '0 6px 20px rgba(16, 185, 129, 0.4)';
                  }
                }}
                onMouseOut={(e) => {
                  if (!shiftLoading) {
                    e.target.style.transform = 'translateY(0)';
                    e.target.style.boxShadow = '0 4px 12px rgba(16, 185, 129, 0.3)';
                  }
                }}
              >
                {shiftLoading ? '🔄 Opening...' : '🚀 OPEN SHIFT'}
              </button>
            ) : (
              <>
                <button
                  onClick={closeShift}
                  disabled={shiftLoading}
                  style={{
                    background: 'linear-gradient(135deg, #e53e3e 0%, #c53030 100%)',
                    color: 'white',
                    border: '3px solid #dc2626',
                    padding: '15px 30px',
                    borderRadius: '12px',
                    fontSize: '18px',
                    fontWeight: '700',
                    cursor: shiftLoading ? 'not-allowed' : 'pointer',
                    transition: 'all 0.3s ease',
                    boxShadow: '0 6px 20px rgba(229, 62, 62, 0.4)',
                    textTransform: 'uppercase',
                    letterSpacing: '0.5px'
                  }}
                  onMouseOver={(e) => {
                    if (!shiftLoading) {
                      e.target.style.transform = 'translateY(-2px)';
                      e.target.style.boxShadow = '0 8px 25px rgba(229, 62, 62, 0.5)';
                    }
                  }}
                  onMouseOut={(e) => {
                    if (!shiftLoading) {
                      e.target.style.transform = 'translateY(0)';
                      e.target.style.boxShadow = '0 6px 20px rgba(229, 62, 62, 0.4)';
                    }
                  }}
                >
                  {shiftLoading ? '🔄 Closing...' : '🛑 CLOSE SHIFT'}
                </button>
                
                <button
                  onClick={goToAdminAttendance}
                  style={{
                    background: 'linear-gradient(135deg, #3B82F6 0%, #2563EB 100%)',
                    color: 'white',
                    border: '3px solid #2563EB',
                    padding: '15px 30px',
                    borderRadius: '12px',
                    fontSize: '18px',
                    fontWeight: '700',
                    cursor: 'pointer',
                    transition: 'all 0.3s ease',
                    boxShadow: '0 4px 12px rgba(59, 130, 246, 0.3)',
                    textTransform: 'uppercase',
                    letterSpacing: '0.5px'
                  }}
                  onMouseOver={(e) => {
                    e.target.style.transform = 'translateY(-2px)';
                    e.target.style.boxShadow = '0 6px 20px rgba(59, 130, 246, 0.4)';
                  }}
                  onMouseOut={(e) => {
                    e.target.style.transform = 'translateY(0)';
                    e.target.style.boxShadow = '0 4px 12px rgba(59, 130, 246, 0.3)';
                  }}
                >
                  📊 ADMIN ATTENDANCE
                </button>
              </>
            )}
          </div>
        </div>

        {/* Live Attendance Green Card - Only show when shift is active */}
        {currentShift && (
          <div 
            onClick={() => setShowAttendanceDetails(!showAttendanceDetails)}
            style={{
              background: 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
              color: 'white',
              padding: '25px',
              borderRadius: '15px',
              marginBottom: '30px',
              cursor: 'pointer',
              transition: 'all 0.3s ease',
              boxShadow: '0 8px 25px rgba(16, 185, 129, 0.3)',
              border: '3px solid #059669'
            }}
            onMouseOver={(e) => {
              e.target.style.transform = 'translateY(-3px)';
              e.target.style.boxShadow = '0 12px 35px rgba(16, 185, 129, 0.4)';
            }}
            onMouseOut={(e) => {
              e.target.style.transform = 'translateY(0)';
              e.target.style.boxShadow = '0 8px 25px rgba(16, 185, 129, 0.3)';
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '15px' }}>
              <h3 style={{ margin: '0', fontSize: '22px', fontWeight: '700' }}>
                🎯 Live Attendance Supervisor
              </h3>
              <div style={{ fontSize: '24px', fontWeight: '800' }}>
                {attendanceCount} Scans
              </div>
            </div>
            
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: '15px', marginBottom: '15px' }}>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: '28px', fontWeight: '800', marginBottom: '5px' }}>{attendanceCount}</div>
                <div style={{ fontSize: '14px', opacity: '0.9' }}>Total Scans</div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: '28px', fontWeight: '800', marginBottom: '5px' }}>
                  {currentShift ? Math.floor((new Date() - new Date(currentShift.startTime || currentShift.createdAt)) / (1000 * 60)) : 0}
                </div>
                <div style={{ fontSize: '14px', opacity: '0.9' }}>Minutes Active</div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: '28px', fontWeight: '800', marginBottom: '5px' }}>
                  {liveAttendance.filter(record => {
                    const recordTime = new Date(record.timestamp || record.createdAt);
                    const now = new Date();
                    return (now - recordTime) < (5 * 60 * 1000); // Last 5 minutes
                  }).length}
                </div>
                <div style={{ fontSize: '14px', opacity: '0.9' }}>Recent (5min)</div>
              </div>
            </div>
            
            <div style={{ 
              fontSize: '14px', 
              opacity: '0.9', 
              textAlign: 'center',
              borderTop: '1px solid rgba(255,255,255,0.3)',
              paddingTop: '15px'
            }}>
              Click to {showAttendanceDetails ? 'hide' : 'view'} detailed attendance records
            </div>
          </div>
        )}

        {/* Live Attendance Details Table */}
        {showAttendanceDetails && currentShift && liveAttendance.length > 0 && (
          <div style={{
            background: 'white',
            borderRadius: '15px',
            padding: '25px',
            marginBottom: '30px',
            border: '2px solid #10B981',
            boxShadow: '0 8px 25px rgba(16, 185, 129, 0.1)'
          }}>
            <h3 style={{ 
              margin: '0 0 20px 0', 
              fontSize: '20px', 
              color: '#10B981',
              fontWeight: '700'
            }}>
              📋 Live Attendance Records
            </h3>
            
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ background: '#f8fafc' }}>
                    <th style={{ padding: '12px', textAlign: 'left', borderBottom: '2px solid #e2e8f0', fontWeight: '600' }}>Time</th>
                    <th style={{ padding: '12px', textAlign: 'left', borderBottom: '2px solid #e2e8f0', fontWeight: '600' }}>Student</th>
                    <th style={{ padding: '12px', textAlign: 'left', borderBottom: '2px solid #e2e8f0', fontWeight: '600' }}>College</th>
                    <th style={{ padding: '12px', textAlign: 'left', borderBottom: '2px solid #e2e8f0', fontWeight: '600' }}>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {liveAttendance.slice(0, 10).map((record, index) => (
                    <tr key={index} style={{ background: index % 2 === 0 ? 'white' : '#f8fafc' }}>
                      <td style={{ padding: '10px', borderBottom: '1px solid #e2e8f0' }}>
                        {new Date(record.timestamp || record.createdAt).toLocaleTimeString()}
                      </td>
                      <td style={{ padding: '10px', borderBottom: '1px solid #e2e8f0' }}>
                        {record.studentName || record.name || 'Unknown'}
                      </td>
                      <td style={{ padding: '10px', borderBottom: '1px solid #e2e8f0' }}>
                        {record.college || 'N/A'}
                      </td>
                      <td style={{ padding: '10px', borderBottom: '1px solid #e2e8f0' }}>
                        <span style={{
                          padding: '4px 8px',
                          borderRadius: '12px',
                          background: '#10B981',
                          color: 'white',
                          fontSize: '12px',
                          fontWeight: '600'
                        }}>
                          ✅ Present
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            
            {liveAttendance.length > 10 && (
              <p style={{ 
                margin: '15px 0 0 0', 
                textAlign: 'center', 
                color: '#6b7280',
                fontSize: '14px'
              }}>
                Showing latest 10 records. Total: {liveAttendance.length}
              </p>
            )}
          </div>
        )}

        {/* QR Scanner Section */}
        <div style={{
          background: 'linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%)',
          borderRadius: '15px',
          padding: '25px',
          marginBottom: '30px',
          border: '2px solid #e2e8f0'
        }}>
          <h2 style={{ 
            margin: '0 0 20px 0', 
            fontSize: '24px', 
            fontWeight: '600',
            color: '#1f2937',
            display: 'flex',
            alignItems: 'center',
            gap: '10px'
          }}>
            📱 QR Code Scanner
          </h2>

          {!currentShift && (
            <div style={{
              background: '#FEF3C7',
              border: '2px solid #F59E0B',
              borderRadius: '12px',
              padding: '15px',
              marginBottom: '20px',
              color: '#92400E'
            }}>
              <strong>⚠️ Notice:</strong> Please open a shift before scanning QR codes.
            </div>
          )}

          <div style={{
            background: 'white',
            borderRadius: '12px',
            padding: '20px',
            border: '3px solid #10B981'
          }}>
            <AccurateQRScanner 
              onScanSuccess={handleQRCodeScanned}
              onScanError={handleScanError}
              style={{ width: '100%', maxWidth: '500px', margin: '0 auto' }}
            />
          </div>

          {scanError && (
            <div style={{
              background: '#FEE2E2',
              border: '2px solid #EF4444',
              borderRadius: '8px',
              padding: '15px',
              marginTop: '15px',
              color: '#DC2626'
            }}>
              <strong>Error:</strong> {scanError}
            </div>
          )}
        </div>

        {/* Scanned Student Display */}
        {scannedStudent && (
          <div style={{
            background: 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
            color: 'white',
            padding: '25px',
            borderRadius: '15px',
            marginBottom: '30px',
            border: '3px solid #059669',
            animation: 'pulse 2s infinite'
          }}>
            <h3 style={{ margin: '0 0 15px 0', fontSize: '22px' }}>
              ✅ Attendance Confirmed!
            </h3>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '15px', marginBottom: '20px' }}>
              <div>
                <strong>Name:</strong> {scannedStudent.name || scannedStudent.fullName}
              </div>
              <div>
                <strong>Student ID:</strong> {scannedStudent.studentId}
              </div>
              <div>
                <strong>College:</strong> {scannedStudent.college}
              </div>
              <div>
                <strong>Time:</strong> {new Date().toLocaleTimeString()}
              </div>
            </div>

            {/* Student Photo and Details */}
            <div style={{
              background: 'rgba(255,255,255,0.1)',
              borderRadius: '12px',
              padding: '20px',
              marginBottom: '20px'
            }}>
              <div style={{ display: 'flex', gap: '20px', alignItems: 'center', flexWrap: 'wrap' }}>
                <div style={{
                  width: '80px',
                  height: '80px',
                  borderRadius: '50%',
                  overflow: 'hidden',
                  border: '3px solid white',
                  background: 'rgba(255,255,255,0.2)'
                }}>
                  {scannedStudent.photo ? (
                    <img 
                      src={scannedStudent.photo} 
                      alt={scannedStudent.name}
                      style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                      onError={(e) => {
                        e.target.style.display = 'none';
                        e.target.nextSibling.style.display = 'flex';
                      }}
                    />
                  ) : null}
                  <div style={{ 
                    display: scannedStudent.photo ? 'none' : 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    height: '100%',
                    fontSize: '32px',
                    fontWeight: 'bold'
                  }}>
                    {scannedStudent.name ? scannedStudent.name.charAt(0) : 'S'}
                  </div>
                </div>
                
                <div style={{ flex: 1 }}>
                  <h4 style={{ margin: '0 0 10px 0', fontSize: '18px' }}>Student Details</h4>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: '10px' }}>
                    <div><strong>Grade:</strong> {scannedStudent.grade}</div>
                    <div><strong>Major:</strong> {scannedStudent.major}</div>
                    <div><strong>Phone:</strong> {scannedStudent.phoneNumber}</div>
                    <div><strong>Email:</strong> {scannedStudent.email}</div>
                  </div>
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div style={{ display: 'flex', gap: '15px', justifyContent: 'center', flexWrap: 'wrap' }}>
              <button
                onClick={handleSubscriptionPayment}
                style={{
                  background: 'rgba(255,255,255,0.2)',
                  color: 'white',
                  border: '2px solid white',
                  padding: '12px 20px',
                  borderRadius: '8px',
                  fontSize: '16px',
                  fontWeight: '600',
                  cursor: 'pointer',
                  transition: 'all 0.3s ease'
                }}
                onMouseOver={(e) => {
                  e.target.style.background = 'white';
                  e.target.style.color = '#059669';
                }}
                onMouseOut={(e) => {
                  e.target.style.background = 'rgba(255,255,255,0.2)';
                  e.target.style.color = 'white';
                }}
              >
                💳 Subscription Payment
              </button>
              
              <button
                onClick={handleBackToScanner}
                style={{
                  background: 'rgba(255,255,255,0.2)',
                  color: 'white',
                  border: '2px solid white',
                  padding: '12px 20px',
                  borderRadius: '8px',
                  fontSize: '16px',
                  fontWeight: '600',
                  cursor: 'pointer',
                  transition: 'all 0.3s ease'
                }}
                onMouseOver={(e) => {
                  e.target.style.background = 'white';
                  e.target.style.color = '#059669';
                }}
                onMouseOut={(e) => {
                  e.target.style.background = 'rgba(255,255,255,0.2)';
                  e.target.style.color = 'white';
                }}
              >
                📱 Back to Scanner
              </button>
            </div>
          </div>
        )}

        {/* Shift Result Display */}
        {shiftResult && (
          <div style={{
            background: shiftResult.type === 'success' ? 
              'linear-gradient(135deg, #10B981 0%, #059669 100%)' : 
              'linear-gradient(135deg, #EF4444 0%, #DC2626 100%)',
            color: 'white',
            padding: '20px',
            borderRadius: '12px',
            marginBottom: '20px',
            textAlign: 'center'
          }}>
            <h3 style={{ margin: '0 0 10px 0' }}>
              {shiftResult.type === 'success' ? '✅' : '❌'} Shift Update
            </h3>
            <p style={{ margin: '0', fontSize: '16px' }}>{shiftResult.message}</p>
          </div>
        )}
      </div>

      {/* Subscription Payment Modal */}
      {showPaymentForm && (
        <SubscriptionPaymentModal
          isOpen={showPaymentForm}
          onClose={() => setShowPaymentForm(false)}
          paymentData={paymentData}
          setPaymentData={setPaymentData}
          studentData={scannedStudent}
          onPaymentComplete={handlePaymentComplete}
        />
      )}

      {/* Custom CSS for animations */}
      <style jsx>{`
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.8; }
        }
      `}</style>
    </div>
  );
};

export default SupervisorDashboard;
