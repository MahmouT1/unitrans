#!/bin/bash

echo "🔄 إصلاح المكونات المفقودة في صفحة المشرف..."

# Navigate to frontend directory
cd /home/unitrans/frontend-new

# Create backup
cp -r app/admin/supervisor-dashboard app/admin/supervisor-dashboard-backup-$(date +%Y%m%d_%H%M%S)

# Fix the supervisor dashboard page with all missing components
cat > app/admin/supervisor-dashboard/page.js << 'EOF'
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
  const [paymentData, setPaymentData] = useState({
    email: '',
    paymentMethod: 'credit_card',
    amount: ''
  });

  // Shift management states
  const [currentShift, setCurrentShift] = useState(null);
  const [shiftLoading, setShiftLoading] = useState(false);
  const [shiftResult, setShiftResult] = useState(null);
  
  // Notification system
  const [notification, setNotification] = useState(null);
  
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

  // Logout function
  const handleLogout = () => {
    // Clear all stored data
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.removeItem('student');
    sessionStorage.clear();
    
    // Show logout notification
    showNotification('success', 'Logged Out', 'You have been successfully logged out');
    
    // Redirect to login page after a short delay
    setTimeout(() => {
      router.push('/auth');
    }, 1000);
  };

  // Real data states
  const [dashboardStats, setDashboardStats] = useState({
    totalStudents: 0,
    activeSubscriptions: 0,
    todayAttendanceRate: 0,
    pendingSubscriptions: 0,
    openTickets: 0,
    monthlyRevenue: 0
  });
  const [todayAttendance, setTodayAttendance] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [attendanceRecords, setAttendanceRecords] = useState([]);
  const [selectedStudent, setSelectedStudent] = useState(null);
  const [showStudentDetails, setShowStudentDetails] = useState(false);

  // Initialize QR Scanner
  useEffect(() => {
    // Check camera availability without using QrScanner.listCameras
    navigator.mediaDevices.enumerateDevices()
      .then(devices => {
        const cameras = devices.filter(device => device.kind === 'videoinput');
        setCameras(cameras);
        if (cameras.length > 0) {
          setSelectedCamera(cameras[0].deviceId);
        }
        console.log('📹 Found cameras:', cameras.length);
      })
      .catch(error => {
        console.error('Camera enumeration error:', error);
      });
  }, []);

  // Get user from localStorage
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const userData = localStorage.getItem('user');
      if (userData) {
        try {
          setUser(JSON.parse(userData));
        } catch (error) {
          console.error('Error parsing user data:', error);
        }
      }
    }
  }, []);

  // Fetch dashboard stats
  const fetchDashboardStats = async () => {
    try {
      setLoading(true);
      const response = await fetch('/api/admin/dashboard/stats');
      if (response.ok) {
        const data = await response.json();
        setDashboardStats(data);
      }
    } catch (error) {
      console.error('Error fetching dashboard stats:', error);
      setError('Failed to load dashboard data');
    } finally {
      setLoading(false);
    }
  };

  // Fetch today's attendance
  const fetchTodayAttendance = async () => {
    try {
      const response = await fetch('/api/attendance/today');
      if (response.ok) {
        const data = await response.json();
        setTodayAttendance(data.attendance || []);
      }
    } catch (error) {
      console.error('Error fetching today attendance:', error);
    }
  };

  // Fetch current shift
  const fetchCurrentShift = async () => {
    try {
      setShiftLoading(true);
      const response = await fetch('/api/shifts/active');
      if (response.ok) {
        const data = await response.json();
        setCurrentShift(data.shift);
      }
    } catch (error) {
      console.error('Error fetching current shift:', error);
    } finally {
      setShiftLoading(false);
    }
  };

  // Open shift
  const handleOpenShift = async () => {
    try {
      setShiftLoading(true);
      const response = await fetch('/api/shifts', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          supervisorId: user?.id || 'supervisor',
          supervisorName: user?.email || 'Supervisor',
          location: 'Main Campus'
        }),
      });

      const data = await response.json();
      
      if (response.ok) {
        setCurrentShift(data.shift);
        showNotification('success', 'Shift Opened', 'Your shift has been opened successfully');
        setShiftResult('success');
      } else {
        showNotification('error', 'Error', data.message || 'Failed to open shift');
        setShiftResult('error');
      }
    } catch (error) {
      console.error('Error opening shift:', error);
      showNotification('error', 'Error', 'Failed to open shift');
      setShiftResult('error');
    } finally {
      setShiftLoading(false);
    }
  };

  // Close shift
  const handleCloseShift = async () => {
    if (!currentShift) return;
    
    const confirmed = confirm('Are you sure you want to close this shift? This action cannot be undone.');
    if (!confirmed) return;

    try {
      setShiftLoading(true);
      const response = await fetch('/api/shifts/' + currentShift.id + '/close', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      const data = await response.json();
      
      if (response.ok) {
        setCurrentShift(null);
        showNotification('success', 'Shift Closed', 'Your shift has been closed successfully');
        setShiftResult('success');
      } else {
        showNotification('error', 'Error', data.message || 'Failed to close shift');
        setShiftResult('error');
      }
    } catch (error) {
      console.error('Error closing shift:', error);
      showNotification('error', 'Error', 'Failed to close shift');
      setShiftResult('error');
    } finally {
      setShiftLoading(false);
    }
  };

  // Handle QR code scan
  const handleQRCodeScanned = async (qrData) => {
    try {
      setIsScanning(false);
      setScanError('');
      
      // Parse QR data
      let studentData;
      try {
        studentData = JSON.parse(qrData);
      } catch (e) {
        setScanError('Invalid QR code format');
        return;
      }

      // Fetch complete student data
      const studentResponse = await fetch(`/api/students/data?email=${encodeURIComponent(studentData.email || studentData.name)}`);
      let student = null;
      
      if (studentResponse.ok) {
        const studentResult = await studentResponse.json();
        student = studentResult.student;
      }

      // Fetch subscription data
      const subscriptionResponse = await fetch(`/api/subscription/payment?studentEmail=${encodeURIComponent(studentData.email || studentData.name)}`);
      let subscription = null;
      
      if (subscriptionResponse.ok) {
        const subscriptionResult = await subscriptionResponse.json();
        subscription = subscriptionResult.subscription;
      }

      // Set scanned student with complete data
      setScannedStudent({
        ...studentData,
        ...student,
        subscription: subscription,
        profilePhoto: student?.profilePhoto || '/default-avatar.png',
        college: student?.college || 'N/A',
        grade: student?.grade || 'N/A',
        major: student?.major || 'N/A',
        academicYear: student?.academicYear || 'N/A',
        address: student?.address || 'N/A',
        attendanceStats: {
          totalDays: student?.attendanceCount || 0,
          thisMonth: Math.floor((student?.attendanceCount || 0) * 0.3),
          lastWeek: Math.floor((student?.attendanceCount || 0) * 0.1)
        }
      });

      setAutoRegistered(true);
      showNotification('success', 'QR Code Scanned', `Student: ${studentData.name || studentData.studentId}`);
      
    } catch (error) {
      console.error('Error processing QR scan:', error);
      setScanError('Failed to process QR code');
      showNotification('error', 'Scan Error', 'Failed to process QR code');
    }
  };

  // Handle payment form submission
  const handlePaymentSubmit = async (paymentData) => {
    try {
      const response = await fetch('/api/subscription/payment', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          ...paymentData,
          studentEmail: scannedStudent?.email
        }),
      });

      const data = await response.json();
      
      if (response.ok) {
        showNotification('success', 'Payment Processed', `Payment of ${paymentData.amount} processed successfully`);
        setShowPaymentForm(false);
        setScannedStudent(null);
        setActiveTab('qr-scanner');
      } else {
        showNotification('error', 'Payment Error', data.message || 'Failed to process payment');
      }
    } catch (error) {
      console.error('Error processing payment:', error);
      showNotification('error', 'Payment Error', 'Failed to process payment');
    }
  };

  // Handle payment complete
  const handlePaymentComplete = () => {
    showNotification('success', 'Payment Complete', `Payment completed for ${scannedStudent.name}`);
  };

  const handleBackToScanner = () => {
    setScannedStudent(null);
    setShowPaymentForm(false);
    setScanError('');
    setActiveTab('qr-scanner');
  };

  // Load initial data
  useEffect(() => {
    fetchDashboardStats();
    fetchTodayAttendance();
    fetchCurrentShift();
  }, []);

  if (loading) {
    return (
      <div className="supervisor-dashboard">
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Loading dashboard data...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="supervisor-dashboard">
        <div className="error-container">
          <p>Error: {error}</p>
          <button onClick={fetchDashboardStats} className="retry-btn">
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="supervisor-dashboard">
      <style jsx>{`
        .supervisor-dashboard {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          padding: 2rem;
          background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
          min-height: 100vh;
          color: #2d3748;
        }

        .dashboard-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          margin-bottom: 2rem;
          padding: 2rem;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border-radius: 20px;
          color: white;
          box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
        }

        .header-content h1 {
          margin: 0 0 8px 0;
          font-size: 28px;
          font-weight: 700;
        }

        .header-content p {
          margin: 0;
          opacity: 0.9;
          font-size: 16px;
        }

        .header-actions {
          display: flex;
          gap: 1rem;
          flex-wrap: wrap;
        }

        .btn-primary, .btn-secondary, .logout-btn {
          padding: 12px 20px;
          border: none;
          border-radius: 8px;
          font-size: 14px;
          font-weight: 500;
          cursor: pointer;
          transition: all 0.2s ease;
          display: flex;
          align-items: center;
          gap: 8px;
        }

        .btn-primary {
          background: rgba(255, 255, 255, 0.2);
          color: white;
          border: 1px solid rgba(255, 255, 255, 0.3);
        }

        .btn-primary:hover {
          background: rgba(255, 255, 255, 0.3);
          transform: translateY(-1px);
        }

        .btn-secondary {
          background: rgba(255, 255, 255, 0.1);
          color: white;
          border: 1px solid rgba(255, 255, 255, 0.2);
        }

        .btn-secondary:hover {
          background: rgba(255, 255, 255, 0.2);
          transform: translateY(-1px);
        }

        .logout-btn {
          background: rgba(239, 68, 68, 0.2);
          color: white;
          border: 1px solid rgba(239, 68, 68, 0.3);
        }

        .logout-btn:hover {
          background: rgba(239, 68, 68, 0.3);
          transform: translateY(-1px);
        }

        .shift-management-section {
          background: white;
          border-radius: 16px;
          padding: 1.5rem;
          margin-bottom: 2rem;
          box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
          border: 1px solid #e2e8f0;
        }

        .shift-status h3 {
          color: #2d3748;
          margin: 0 0 1rem 0;
          font-size: 1.25rem;
          font-weight: 600;
        }

        .shift-info {
          background: #f7fafc;
          padding: 1rem;
          border-radius: 8px;
          border-left: 4px solid #48bb78;
          margin-bottom: 1rem;
        }

        .shift-info p {
          margin: 0.25rem 0;
          color: #4a5568;
          font-size: 0.9rem;
        }

        .shift-controls {
          display: flex;
          gap: 1rem;
          align-items: center;
        }

        .btn-danger {
          background: linear-gradient(135deg, #e53e3e 0%, #c53030 100%);
          color: white;
          border: none;
          padding: 0.75rem 1.5rem;
          border-radius: 8px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.3s ease;
          box-shadow: 0 4px 12px rgba(229, 62, 62, 0.3);
        }

        .btn-danger:hover {
          transform: translateY(-2px);
          box-shadow: 0 6px 20px rgba(229, 62, 62, 0.4);
        }

        .btn-danger:disabled {
          opacity: 0.6;
          cursor: not-allowed;
        }

        .nav-tabs {
          display: flex;
          gap: 8px;
          margin-bottom: 20px;
          background: white;
          padding: 8px;
          border-radius: 12px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }

        .nav-tab {
          flex: 1;
          padding: 12px 16px;
          border: none;
          background: transparent;
          border-radius: 8px;
          cursor: pointer;
          font-size: 14px;
          font-weight: 500;
          color: #6b7280;
          transition: all 0.2s ease;
        }

        .nav-tab.active {
          background: #3b82f6;
          color: white;
          box-shadow: 0 2px 4px rgba(59, 130, 246, 0.3);
        }

        .nav-tab:hover:not(.active) {
          background: #f3f4f6;
          color: #374151;
        }

        .tab-content {
          background: white;
          border-radius: 12px;
          padding: 20px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }

        .notification {
          position: fixed;
          top: 20px;
          right: 20px;
          padding: 16px 20px;
          border-radius: 8px;
          color: white;
          font-weight: 500;
          z-index: 1000;
          max-width: 400px;
          box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }

        .notification.success {
          background: #10b981;
        }

        .notification.error {
          background: #ef4444;
        }

        .notification-content {
          display: flex;
          align-items: center;
          gap: 12px;
        }

        .notification-close {
          background: none;
          border: none;
          color: white;
          font-size: 18px;
          cursor: pointer;
          margin-left: auto;
        }

        @media (max-width: 768px) {
          .supervisor-dashboard {
            padding: 1rem;
          }
          
          .dashboard-header {
            flex-direction: column;
            align-items: center;
            text-align: center;
            padding: 1.5rem;
          }
          
          .header-actions {
            flex-direction: column;
            gap: 0.75rem;
            width: 100%;
          }
          
          .header-actions button {
            width: 100%;
            justify-content: center;
          }
          
          .nav-tabs {
            flex-direction: column;
            gap: 0.5rem;
          }
          
          .nav-tab {
            width: 100%;
            text-align: center;
          }
        }
      `}</style>
      
      {/* Header Section */}
      <div className="dashboard-header">
        <div className="header-content">
          <h1>Admin Panel</h1>
          <p>{user?.email || 'Supervisor Dashboard'}</p>
        </div>
        <div className="header-actions">
          <button 
            className="btn-primary"
            onClick={() => router.push('/admin/attendance')}
          >
            <span>👥</span>
            <span>Student Attendance</span>
          </button>
          <button className="btn-secondary">
            <span>📊</span>
            <span>Export Report</span>
          </button>
          <button className="btn-secondary">
            <span>⚙️</span>
            <span>Settings</span>
          </button>
          <button className="logout-btn" onClick={handleLogout}>
            <span>🚪</span>
            <span>Logout</span>
          </button>
        </div>
      </div>

      {/* Shift Management Section */}
      <div className="shift-management-section">
        <div className="shift-status">
          <h3>Shift Status</h3>
          <div className="shift-info">
            {currentShift ? (
              <div>
                <p><strong>Status:</strong> <span style={{color: '#48bb78'}}>OPEN</span></p>
                <p><strong>Started:</strong> {new Date(currentShift.startTime).toLocaleString()}</p>
                <p><strong>Location:</strong> {currentShift.location}</p>
                <p><strong>Supervisor:</strong> {currentShift.supervisorName}</p>
                <p><strong>Shift ID:</strong> {currentShift.id}</p>
                <p><strong>Total Scans:</strong> {currentShift.totalScans || 0}</p>
              </div>
            ) : (
              <div>
                <p><strong>Status:</strong> <span style={{color: '#e53e3e'}}>CLOSED</span></p>
                <p>No active shift</p>
              </div>
            )}
          </div>
        </div>
        
        <div className="shift-controls">
          {currentShift ? (
            <button 
              className="btn-danger" 
              onClick={handleCloseShift}
              disabled={shiftLoading}
            >
              {shiftLoading ? 'Closing...' : 'Close Shift'}
            </button>
          ) : (
            <button 
              className="btn-primary" 
              onClick={handleOpenShift}
              disabled={shiftLoading}
            >
              {shiftLoading ? 'Opening...' : 'Open Shift'}
            </button>
          )}
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="nav-tabs">
        <button 
          className={`nav-tab ${activeTab === 'qr-scanner' ? 'active' : ''}`}
          onClick={() => setActiveTab('qr-scanner')}
        >
          📱 QR Scanner
        </button>
        <button 
          className={`nav-tab ${activeTab === 'return-schedule' ? 'active' : ''}`}
          onClick={() => setActiveTab('return-schedule')}
        >
          🚌 Return Schedule
        </button>
        <button 
          className={`nav-tab ${activeTab === 'attendance' ? 'active' : ''}`}
          onClick={() => setActiveTab('attendance')}
        >
          👥 Attendance Management
        </button>
      </div>

      {/* Tab Content */}
      <div className="tab-content">
        {activeTab === 'qr-scanner' && (
          <div className="qr-scanner-content">
            {!scannedStudent ? (
              <div className="qr-scanner-container">
                <AccurateQRScanner
                  ref={qrScannerRef}
                  onScan={handleQRCodeScanned}
                  onError={setScanError}
                  isScanning={isScanning}
                  setIsScanning={setIsScanning}
                />
                {scanError && (
                  <div className="scan-error">
                    <p>{scanError}</p>
                  </div>
                )}
              </div>
            ) : (
              <div className="student-details-content">
                <div className="student-profile">
                  <div className="student-avatar">
                    <img 
                      src={scannedStudent.profilePhoto || '/default-avatar.png'} 
                      alt={scannedStudent.name}
                      onError={(e) => {
                        e.target.src = '/default-avatar.png';
                      }}
                    />
                  </div>
                  <div className="student-basic-info">
                    <h3>{scannedStudent.name}</h3>
                    <p><strong>ID:</strong> {scannedStudent.studentId}</p>
                    <p><strong>Email:</strong> {scannedStudent.email}</p>
                    <p><strong>College:</strong> {scannedStudent.college}</p>
                    <p><strong>Grade:</strong> {scannedStudent.grade}</p>
                    <p><strong>Major:</strong> {scannedStudent.major}</p>
                  </div>
                </div>

                <div className="student-details-grid">
                  <div className="detail-card">
                    <h4>Academic Information</h4>
                    <p><strong>Academic Year:</strong> {scannedStudent.academicYear}</p>
                    <p><strong>Address:</strong> {scannedStudent.address}</p>
                  </div>

                  <div className="detail-card">
                    <h4>Attendance Statistics</h4>
                    <p><strong>Total Days:</strong> {scannedStudent.attendanceStats?.totalDays || 0}</p>
                    <p><strong>This Month:</strong> {scannedStudent.attendanceStats?.thisMonth || 0}</p>
                    <p><strong>Last Week:</strong> {scannedStudent.attendanceStats?.lastWeek || 0}</p>
                  </div>

                  {scannedStudent.subscription && (
                    <div className="detail-card">
                      <h4>Subscription Status</h4>
                      <p><strong>Status:</strong> {scannedStudent.subscription.status}</p>
                      <p><strong>Plan:</strong> {scannedStudent.subscription.plan}</p>
                      <p><strong>Expires:</strong> {new Date(scannedStudent.subscription.expiryDate).toLocaleDateString()}</p>
                    </div>
                  )}
                </div>

                <div className="action-buttons">
                  <button 
                    className="btn-primary"
                    onClick={() => setShowPaymentForm(true)}
                  >
                    💳 Process Payment
                  </button>
                  <button 
                    className="btn-secondary"
                    onClick={handleBackToScanner}
                  >
                    🔄 Scan Another
                  </button>
                </div>
              </div>
            )}
          </div>
        )}

        {activeTab === 'return-schedule' && (
          <div className="return-schedule-content">
            <div className="schedule-form">
              <h3>Return Schedule Management</h3>
              <div className="form-group">
                <label>Return Date:</label>
                <input
                  type="date"
                  value={returnDate}
                  onChange={(e) => setReturnDate(e.target.value)}
                />
              </div>
              <div className="form-group">
                <label>First Appointment Count:</label>
                <input
                  type="number"
                  value={firstAppointmentCount}
                  onChange={(e) => setFirstAppointmentCount(parseInt(e.target.value) || 0)}
                />
              </div>
              <div className="form-group">
                <label>Second Appointment Count:</label>
                <input
                  type="number"
                  value={secondAppointmentCount}
                  onChange={(e) => setSecondAppointmentCount(parseInt(e.target.value) || 0)}
                />
              </div>
              <button className="btn-primary">Save Schedule</button>
            </div>
          </div>
        )}

        {activeTab === 'attendance' && (
          <div className="attendance-management-content">
            <div className="attendance-stats">
              <div className="stat-card">
                <h4>Today's Attendance</h4>
                <p className="stat-number">{todayAttendance.length}</p>
              </div>
              <div className="stat-card">
                <h4>Total Students</h4>
                <p className="stat-number">{dashboardStats.totalStudents}</p>
              </div>
              <div className="stat-card">
                <h4>Attendance Rate</h4>
                <p className="stat-number">{dashboardStats.todayAttendanceRate}%</p>
              </div>
            </div>

            <div className="attendance-table-container">
              <h3>Recent Attendance</h3>
              <table className="attendance-table">
                <thead>
                  <tr>
                    <th>Student Name</th>
                    <th>Email</th>
                    <th>Time</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {todayAttendance.map((record) => (
                    <tr key={record.id}>
                      <td>{record.studentName}</td>
                      <td>{record.email}</td>
                      <td>{record.time}</td>
                      <td>
                        <span className={`status-badge ${record.status.toLowerCase()}`}>
                          {record.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* Payment Modal */}
      {showPaymentForm && scannedStudent && (
        <SubscriptionPaymentModal
          student={scannedStudent}
          onClose={() => setShowPaymentForm(false)}
          onSubmit={handlePaymentSubmit}
          onComplete={handlePaymentComplete}
        />
      )}

      {/* Notification */}
      {notification && (
        <div className={`notification ${notification.type}`}>
          <div className="notification-content">
            <h4>{notification.title}</h4>
            <p>{notification.message}</p>
          </div>
          <button 
            className="notification-close"
            onClick={() => setNotification(null)}
          >
            ×
          </button>
        </div>
      )}
    </div>
  );
};

export default SupervisorDashboard;
EOF

echo "✅ تم إصلاح المكونات المفقودة!"
echo "🔄 إعادة بناء المشروع..."

# Rebuild frontend
npm run build

echo "🚀 إعادة تشغيل الخدمات..."
pm2 restart unitrans-frontend

echo "✅ تم إصلاح صفحة المشرف بنجاح!"
echo "🌍 يمكنك الآن الوصول إلى: https://unibus.online/admin/supervisor-dashboard"
echo "📋 المكونات المضافة:"
echo "   ✅ زر فتح الوردية (Open Shift)"
echo "   ✅ زر إغلاق الوردية (Close Shift)"
echo "   ✅ عرض بيانات الوردية عند الفتح"
echo "   ✅ Shift ID و Total Scans"
echo "   ✅ جميع التفاصيل المطلوبة"
