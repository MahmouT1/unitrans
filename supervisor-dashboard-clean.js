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

  // Shift management states
  const [currentShift, setCurrentShift] = useState(null);
  const [shiftLoading, setShiftLoading] = useState(false);
  const [shiftId, setShiftId] = useState('');

  // QR Scanner states
  const [isScanning, setIsScanning] = useState(false);
  const [scannedStudent, setScannedStudent] = useState(null);
  const [cameras, setCameras] = useState([]);
  const [currentCamera, setCurrentCamera] = useState(0);

  // Notification states
  const [notification, setNotification] = useState(null);

  // Show notification function
  const showNotification = (type, title, message, duration = 5000) => {
    setNotification({ type, title, message });
    // Auto-hide notification after duration
    setTimeout(() => {
      setNotification(null);
    }, duration);
  };

  // Authentication check
  useEffect(() => {
    const checkAuth = () => {
      const token = localStorage.getItem('adminToken');
      const userRole = localStorage.getItem('userRole');
      const userEmail = localStorage.getItem('userEmail');

      if (!token || userRole !== 'supervisor') {
        showNotification('error', 'Access Denied', 'You do not have permission to access this page.');
        setTimeout(() => {
          router.push('/auth');
        }, 2000);
        return;
      }

      setUser({
        email: userEmail,
        role: userRole,
        token: token
      });
    };

    checkAuth();
  }, [router]);

  // Load active shift on component mount
  useEffect(() => {
    loadActiveShift();
  }, []);

  // Load active shift
  const loadActiveShift = async () => {
    try {
      const response = await fetch('https://unibus.online:3001/api/shifts/active', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
        }
      });
      
      if (response.ok) {
        const data = await response.json();
        if (data.success && data.shifts && data.shifts.length > 0) {
          const activeShift = data.shifts[0];
          setCurrentShift(activeShift);
          setShiftId(activeShift.id);
        }
      }
    } catch (error) {
      console.error('Error loading active shift:', error);
    }
  };

  // Open shift
  const openShift = async () => {
    if (!user) {
      showNotification('error', 'Authentication Error', 'User not authenticated');
      return;
    }

    setShiftLoading(true);
    try {
      const response = await fetch('https://unibus.online:3001/api/shifts', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${user.token}`
        },
        body: JSON.stringify({
          supervisorId: user.email,
          location: 'Main Campus'
        })
      });

      if (response.ok) {
        const data = await response.json();
        if (data.success) {
          setCurrentShift(data.shift);
          setShiftId(data.shift.id);
          showNotification('success', 'Shift Opened', 'Shift opened successfully!');
        } else {
          showNotification('error', 'Error', data.message || 'Failed to open shift');
        }
      } else {
        showNotification('error', 'Error', 'Failed to open shift');
      }
    } catch (error) {
      console.error('Error opening shift:', error);
      showNotification('error', 'Error', 'Failed to open shift');
    } finally {
      setShiftLoading(false);
    }
  };

  // Close shift
  const closeShift = async () => {
    if (!currentShift) return;

    setShiftLoading(true);
    try {
      const response = await fetch(`https://unibus.online:3001/api/shifts/${currentShift.id}/close`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${user.token}`
        }
      });

      if (response.ok) {
        const data = await response.json();
        if (data.success) {
          setCurrentShift(null);
          setShiftId('');
          showNotification('success', 'Shift Closed', 'Shift closed successfully!');
        } else {
          showNotification('error', 'Error', data.message || 'Failed to close shift');
        }
      } else {
        showNotification('error', 'Error', 'Failed to close shift');
      }
    } catch (error) {
      console.error('Error closing shift:', error);
      showNotification('error', 'Error', 'Failed to close shift');
    } finally {
      setShiftLoading(false);
    }
  };

  // Handle QR code scan
  const handleQRCodeScanned = async (qrData) => {
    if (!currentShift) {
      showNotification('error', 'No Active Shift', 'Please open a shift first');
      return;
    }

    try {
      const response = await fetch('https://unibus.online:3001/api/shifts/scan', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${user.token}`
        },
        body: JSON.stringify({
          shiftId: currentShift.id,
          qrData: qrData,
          supervisorId: user.email,
          location: 'Main Campus'
        })
      });

      if (response.ok) {
        const data = await response.json();
        if (data.success) {
          setScannedStudent(data.studentData);
          showNotification('success', 'Attendance Recorded', `Attendance recorded for ${data.studentData.fullName}`);
        } else {
          showNotification('error', 'Scan Error', data.message || 'Failed to record attendance');
        }
      } else {
        showNotification('error', 'Scan Error', 'Failed to record attendance');
      }
    } catch (error) {
      console.error('Error scanning QR code:', error);
      showNotification('error', 'Scan Error', 'Failed to record attendance');
    }
  };

  // Switch camera
  const switchCamera = () => {
    if (cameras.length > 1) {
      setCurrentCamera((prev) => (prev + 1) % cameras.length);
    }
  };

  // Go to admin attendance page
  const goToAdminAttendance = () => {
    router.push('/admin/attendance');
  };

  if (!user) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh', fontSize: '18px' }}>
        Checking authentication...
      </div>
    );
  }

  return (
    <div className="supervisor-dashboard-page" style={{ minHeight: '100vh', backgroundColor: '#f5f5f5' }}>
      {/* Notification */}
      {notification && (
        <div style={{
          position: 'fixed',
          top: '20px',
          right: '20px',
          zIndex: 1000,
          padding: '15px 20px',
          borderRadius: '8px',
          color: 'white',
          background: notification.type === 'success' ? '#10B981' : '#EF4444',
          boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
          maxWidth: '400px'
        }}>
          <h4 style={{ margin: '0 0 5px 0', fontSize: '16px' }}>{notification.title}</h4>
          <p style={{ margin: '0', fontSize: '14px' }}>{notification.message}</p>
        </div>
      )}

      {/* Header */}
      <div style={{
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        color: 'white',
        padding: '20px',
        marginBottom: '20px'
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h1 style={{ margin: '0 0 5px 0', fontSize: '28px' }}>Supervisor Dashboard</h1>
            <p style={{ margin: '0', opacity: 0.9 }}>Welcome, {user.email}</p>
          </div>
          <div style={{ display: 'flex', gap: '10px' }}>
            <button
              onClick={goToAdminAttendance}
              style={{
                background: 'rgba(255,255,255,0.2)',
                border: '1px solid rgba(255,255,255,0.3)',
                color: 'white',
                padding: '8px 16px',
                borderRadius: '6px',
                cursor: 'pointer'
              }}
            >
              📊 Admin Attendance
            </button>
          </div>
        </div>
      </div>

      <div style={{ padding: '0 20px', maxWidth: '1200px', margin: '0 auto' }}>
        {/* Shift Status Card */}
        <div style={{
          background: 'white',
          borderRadius: '12px',
          padding: '20px',
          marginBottom: '20px',
          boxShadow: '0 2px 10px rgba(0,0,0,0.1)'
        }}>
          <h2 style={{ margin: '0 0 15px 0', color: '#333' }}>Shift Status</h2>
          <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginBottom: '15px' }}>
            <div style={{
              padding: '8px 16px',
              borderRadius: '20px',
              background: currentShift ? '#10B981' : '#EF4444',
              color: 'white',
              fontWeight: 'bold'
            }}>
              {currentShift ? 'ACTIVE' : 'CLOSED'}
            </div>
            <span style={{ color: '#666' }}>
              {currentShift ? `Shift ID: ${currentShift.id}` : 'No active shift'}
            </span>
          </div>
          
          <div style={{ display: 'flex', gap: '10px' }}>
            {!currentShift ? (
              <button
                onClick={openShift}
                disabled={shiftLoading}
                style={{
                  background: '#10B981',
                  color: 'white',
                  border: 'none',
                  padding: '12px 24px',
                  borderRadius: '8px',
                  cursor: shiftLoading ? 'not-allowed' : 'pointer',
                  fontSize: '16px',
                  fontWeight: 'bold',
                  opacity: shiftLoading ? 0.7 : 1
                }}
              >
                {shiftLoading ? '🔄 Opening...' : '🚀 OPEN SHIFT'}
              </button>
            ) : (
              <button
                onClick={closeShift}
                disabled={shiftLoading}
                style={{
                  background: '#EF4444',
                  color: 'white',
                  border: 'none',
                  padding: '12px 24px',
                  borderRadius: '8px',
                  cursor: shiftLoading ? 'not-allowed' : 'pointer',
                  fontSize: '16px',
                  fontWeight: 'bold',
                  opacity: shiftLoading ? 0.7 : 1
                }}
              >
                {shiftLoading ? '🔄 Closing...' : '🛑 CLOSE SHIFT'}
              </button>
            )}
          </div>
        </div>

        {/* QR Scanner Section */}
        <div style={{
          background: 'white',
          borderRadius: '12px',
          padding: '20px',
          marginBottom: '20px',
          boxShadow: '0 2px 10px rgba(0,0,0,0.1)'
        }}>
          <h2 style={{ margin: '0 0 15px 0', color: '#333' }}>🔍 Accurate QR Scanner</h2>
          
          <div style={{ marginBottom: '15px' }}>
            <AccurateQRScanner
              onQRCodeScanned={handleQRCodeScanned}
              isActive={currentShift && currentShift.status === 'active'}
              style={{ width: '100%', height: '300px' }}
            />
          </div>

          {/* Camera Controls */}
          <div style={{ display: 'flex', gap: '10px', marginBottom: '15px' }}>
            <button
              onClick={switchCamera}
              style={{
                background: '#3B82F6',
                color: 'white',
                border: 'none',
                padding: '8px 16px',
                borderRadius: '6px',
                cursor: 'pointer'
              }}
            >
              📷 Switch Camera
            </button>
          </div>

          {!currentShift && (
            <div style={{
              background: '#FEF3C7',
              border: '1px solid #F59E0B',
              borderRadius: '8px',
              padding: '12px',
              color: '#92400E'
            }}>
              ⚠️ Please open a shift first to start scanning QR codes
            </div>
          )}
        </div>

        {/* Scanned Student Display */}
        {scannedStudent && (
          <div style={{
            background: 'white',
            borderRadius: '12px',
            padding: '20px',
            marginBottom: '20px',
            boxShadow: '0 2px 10px rgba(0,0,0,0.1)'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginBottom: '15px' }}>
              <div style={{
                background: '#10B981',
                color: 'white',
                padding: '8px 12px',
                borderRadius: '20px',
                fontSize: '14px',
                fontWeight: 'bold'
              }}>
                ✅ Attendance Confirmed!
              </div>
            </div>

            <div style={{ display: 'flex', gap: '20px', alignItems: 'flex-start' }}>
              {/* Student Photo */}
              <div style={{ flex: '0 0 120px' }}>
                {scannedStudent.photo ? (
                  <img
                    src={scannedStudent.photo}
                    alt="Student Photo"
                    style={{
                      width: '120px',
                      height: '120px',
                      borderRadius: '8px',
                      objectFit: 'cover',
                      border: '2px solid #e5e7eb'
                    }}
                  />
                ) : (
                  <div style={{
                    width: '120px',
                    height: '120px',
                    borderRadius: '8px',
                    background: '#f3f4f6',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: '#6b7280',
                    fontSize: '14px',
                    border: '2px solid #e5e7eb'
                  }}>
                    No Photo
                  </div>
                )}
              </div>

              {/* Student Details */}
              <div style={{ flex: '1' }}>
                <h4 style={{ margin: '0 0 10px 0', fontSize: '18px' }}>Student Details</h4>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '15px' }}>
                  <div>
                    <strong>Name:</strong> {scannedStudent.fullName}
                  </div>
                  <div>
                    <strong>Email:</strong> {scannedStudent.email}
                  </div>
                  <div>
                    <strong>Student ID:</strong> {scannedStudent.studentId}
                  </div>
                  <div>
                    <strong>Phone:</strong> {scannedStudent.phone || 'N/A'}
                  </div>
                  <div>
                    <strong>Department:</strong> {scannedStudent.department || 'N/A'}
                  </div>
                  <div>
                    <strong>Year:</strong> {scannedStudent.year || 'N/A'}
                  </div>
                </div>

                {/* Subscription Info */}
                {scannedStudent.subscription && (
                  <div style={{
                    background: '#f8f9fa',
                    borderRadius: '8px',
                    padding: '12px',
                    marginBottom: '15px'
                  }}>
                    <h5 style={{ margin: '0 0 8px 0', color: '#333' }}>Subscription Status</h5>
                    <div style={{ display: 'flex', gap: '15px' }}>
                      <div>
                        <strong>Plan:</strong> {scannedStudent.subscription.plan || 'N/A'}
                      </div>
                      <div>
                        <strong>Status:</strong> 
                        <span style={{
                          color: scannedStudent.subscription.status === 'active' ? '#10B981' : '#EF4444',
                          fontWeight: 'bold'
                        }}>
                          {scannedStudent.subscription.status || 'N/A'}
                        </span>
                      </div>
                    </div>
                  </div>
                )}

                {/* Action Buttons */}
                <div style={{ display: 'flex', gap: '10px' }}>
                  <button
                    onClick={() => setScannedStudent(null)}
                    style={{
                      background: '#6B7280',
                      color: 'white',
                      border: 'none',
                      padding: '8px 16px',
                      borderRadius: '6px',
                      cursor: 'pointer'
                    }}
                  >
                    Close
                  </button>
                  <button
                    onClick={() => {
                      // Open subscription payment modal
                      // This would be handled by the SubscriptionPaymentModal component
                    }}
                    style={{
                      background: '#10B981',
                      color: 'white',
                      border: 'none',
                      padding: '8px 16px',
                      borderRadius: '6px',
                      cursor: 'pointer'
                    }}
                  >
                    💳 Subscription Payment
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Shift Summary */}
        {currentShift && (
          <div style={{
            background: 'white',
            borderRadius: '12px',
            padding: '20px',
            boxShadow: '0 2px 10px rgba(0,0,0,0.1)'
          }}>
            <h3 style={{ margin: '0 0 15px 0', color: '#333' }}>Current Shift Summary</h3>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '15px' }}>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#3B82F6' }}>
                  {currentShift ? 'Active' : 'Inactive'}
                </div>
                <div style={{ color: '#666' }}>Shift Status</div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#8B5CF6' }}>
                  {currentShift ? new Date(currentShift.startTime).toLocaleTimeString() : 'N/A'}
                </div>
                <div style={{ color: '#666' }}>Start Time</div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#10B981' }}>
                  {currentShift ? currentShift.id : 'N/A'}
                </div>
                <div style={{ color: '#666' }}>Shift ID</div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Subscription Payment Modal */}
      <SubscriptionPaymentModal />
    </div>
  );
};

export default SupervisorDashboard;
