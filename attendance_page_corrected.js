'use client';

import React, { useState, useEffect } from 'react';

export default function AdminAttendancePage() {
  const [attendanceRecords, setAttendanceRecords] = useState([]);
  const [activeShifts, setActiveShifts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedShift, setSelectedShift] = useState(null);
  const [liveAttendance, setLiveAttendance] = useState([]);
  const [showLiveModal, setShowLiveModal] = useState(false);

  useEffect(() => {
    loadData();
    
    // Auto-refresh every 10 seconds
    const interval = setInterval(() => {
      loadData();
      if (selectedShift) {
        loadLiveAttendance(selectedShift.id);
      }
    }, 10000);

    return () => clearInterval(interval);
  }, [selectedShift]);

  const loadData = async () => {
    try {
      // ✅ استخدام API الصحيح الذي يجمع من قاعدة البيانات
      const response = await fetch('/api/attendance/all-records');
      if (response.ok) {
        const data = await response.json();
        const records = Array.isArray(data.records) ? data.records : [];
        setAttendanceRecords(records);
        console.log('📊 Loaded', records.length, 'attendance records from database');
      }

      // Load active shifts safely  
      const shiftsResponse = await fetch('/api/shifts?status=open');
      if (shiftsResponse.ok) {
        const shiftsData = await shiftsResponse.json();
        const shifts = Array.isArray(shiftsData.shifts) ? shiftsData.shifts : [];
        const openShifts = shifts.filter(shift => shift && shift.status === 'open' && !shift.shiftEnd);
        setActiveShifts(openShifts);
        console.log('🟢 Found', openShifts.length, 'active shifts');
      }
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadLiveAttendance = async (shiftId) => {
    try {
      const response = await fetch(`/api/shifts/${shiftId}/attendance`);
      if (response.ok) {
        const data = await response.json();
        const records = Array.isArray(data.attendance) ? data.attendance : [];
        setLiveAttendance(records);
        console.log('🔴 Live attendance:', records.length, 'records for shift', shiftId);
      }
    } catch (error) {
      console.error('Error loading live attendance:', error);
    }
  };

  const handleShiftClick = async (shift) => {
    setSelectedShift(shift);
    setShowLiveModal(true);
    await loadLiveAttendance(shift.id);
  };

  const closeModal = () => {
    setShowLiveModal(false);
    setSelectedShift(null);
    setLiveAttendance([]);
  };

  // 📊 تجميع السجلات حسب الوردية مع معلومات المشرف الصحيحة
  const groupedRecords = attendanceRecords.reduce((groups, record) => {
    const shiftId = record.shiftId || 'unknown';
    if (!groups[shiftId]) {
      groups[shiftId] = {
        records: [],
        supervisorId: record.supervisorId || 'Unknown Supervisor',
        supervisorName: record.supervisorName || 'Unknown Supervisor',
        shiftDate: null
      };
    }
    groups[shiftId].records.push(record);
    
    // تحديد تاريخ الوردية من أول سجل
    if (!groups[shiftId].shiftDate && record.scanTime) {
      groups[shiftId].shiftDate = new Date(record.scanTime).toLocaleDateString();
    }
    
    return groups;
  }, {});

  if (loading) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        fontSize: '18px'
      }}>
        Loading Attendance Records...
      </div>
    );
  }

  return (
    <div style={{ padding: '20px', backgroundColor: '#f8fafc', minHeight: '100vh' }}>
      <style jsx>{`
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.5; }
        }
      `}</style>

      <h1 style={{ fontSize: '28px', marginBottom: '30px', color: '#333' }}>
        Attendance Records Management
      </h1>

      {/* Summary Cards */}
      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', 
        gap: '20px', 
        marginBottom: '30px' 
      }}>
        <div style={{
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          borderRadius: '16px',
          padding: '24px',
          color: 'white',
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)'
        }}>
          <div style={{ fontSize: '36px', fontWeight: 'bold', marginBottom: '8px' }}>
            {attendanceRecords.length}
          </div>
          <div style={{ fontSize: '16px' }}>Total Records</div>
        </div>

        <div style={{
          background: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
          borderRadius: '16px',
          padding: '24px',
          color: 'white',
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)'
        }}>
          <div style={{ fontSize: '36px', fontWeight: 'bold', marginBottom: '8px' }}>
            {new Set(attendanceRecords.map(r => r.studentEmail)).size}
          </div>
          <div style={{ fontSize: '16px' }}>Unique Students</div>
        </div>

        <div style={{
          background: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
          borderRadius: '16px',
          padding: '24px',
          color: 'white',
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)'
        }}>
          <div style={{ fontSize: '36px', fontWeight: 'bold', marginBottom: '8px' }}>
            {Object.keys(groupedRecords).length}
          </div>
          <div style={{ fontSize: '16px' }}>Total Shifts</div>
        </div>

        <div style={{
          background: 'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
          borderRadius: '16px',
          padding: '24px',
          color: 'white',
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)'
        }}>
          <div style={{ fontSize: '36px', fontWeight: 'bold', marginBottom: '8px' }}>
            {activeShifts.length}
          </div>
          <div style={{ fontSize: '16px' }}>Active Shifts</div>
        </div>
      </div>

      {/* Active Shifts - Clickable Green Cards */}
      {activeShifts.length > 0 && (
        <div style={{
          background: 'white',
          borderRadius: '16px',
          padding: '24px',
          marginBottom: '30px',
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)'
        }}>
          <h2 style={{ marginBottom: '20px', color: '#333', display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{
              width: '12px',
              height: '12px',
              borderRadius: '50%',
              background: '#10b981',
              animation: 'pulse 2s infinite'
            }}></div>
            🟢 Live Supervisor Monitoring ({activeShifts.length} Active)
          </h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '20px' }}>
            {activeShifts.map((shift, index) => (
              <div
                key={shift.id || index}
                onClick={() => handleShiftClick(shift)}
                style={{
                  background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                  borderRadius: '16px',
                  padding: '20px',
                  color: 'white',
                  cursor: 'pointer',
                  transition: 'all 0.3s ease',
                  transform: 'scale(1)',
                  boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)'
                }}
                onMouseEnter={(e) => {
                  e.target.style.transform = 'scale(1.05)';
                  e.target.style.boxShadow = '0 8px 25px rgba(16, 185, 129, 0.3)';
                }}
                onMouseLeave={(e) => {
                  e.target.style.transform = 'scale(1)';
                  e.target.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)';
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '15px' }}>
                  <h3 style={{ margin: '0', fontSize: '18px', fontWeight: '600' }}>
                    {shift.supervisorName || 'Transportation Supervisor'}
                  </h3>
                  <span style={{
                    background: 'rgba(255, 255, 255, 0.2)',
                    padding: '4px 8px',
                    borderRadius: '12px',
                    fontSize: '11px',
                    fontWeight: '500'
                  }}>
                    LIVE
                  </span>
                </div>
                <div style={{ marginBottom: '8px', fontSize: '14px' }}>
                  <strong>Started:</strong> {shift.shiftStart ? new Date(shift.shiftStart).toLocaleTimeString() : 'N/A'}
                </div>
                <div style={{ marginBottom: '8px', fontSize: '14px' }}>
                  <strong>Shift ID:</strong> {shift.id || 'N/A'}
                </div>
                <div style={{ marginBottom: '8px', fontSize: '14px' }}>
                  <strong>Scans:</strong> {shift.totalScans || 0}
                </div>
                <div style={{ 
                  marginTop: '15px', 
                  padding: '8px', 
                  background: 'rgba(255, 255, 255, 0.1)', 
                  borderRadius: '8px',
                  textAlign: 'center',
                  fontSize: '12px',
                  fontWeight: '500'
                }}>
                  👆 Click to view live attendance
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Message when no active shifts */}
      {activeShifts.length === 0 && (
        <div style={{
          background: 'white',
          borderRadius: '16px',
          padding: '24px',
          marginBottom: '30px',
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
          textAlign: 'center'
        }}>
          <h2 style={{ color: '#6b7280', marginBottom: '10px' }}>
            ✅ No Active Shifts
          </h2>
          <p style={{ color: '#9ca3af', margin: '0' }}>
            All supervisors have closed their shifts. Green cards will appear when supervisors open new shifts.
          </p>
        </div>
      )}

      {/* 📚 Historical Attendance Records by Shift - من قاعدة البيانات */}
      <div style={{
        background: 'white',
        borderRadius: '16px',
        padding: '24px',
        boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)'
      }}>
        <h2 style={{ marginBottom: '20px', color: '#333', display: 'flex', alignItems: 'center', gap: '10px' }}>
          📚 Historical Attendance Records 
          <span style={{
            background: '#e0f2fe',
            color: '#0277bd',
            padding: '4px 12px',
            borderRadius: '20px',
            fontSize: '12px',
            fontWeight: '600'
          }}>
            Database Connected ✅
          </span>
        </h2>
        
        {Object.keys(groupedRecords).length > 0 ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            {Object.entries(groupedRecords).map(([shiftId, shiftData]) => (
              <div key={shiftId} style={{
                border: '1px solid #e5e7eb',
                borderRadius: '12px',
                padding: '20px',
                background: '#fafafa'
              }}>
                <div style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  marginBottom: '15px',
                  paddingBottom: '10px',
                  borderBottom: '2px solid #e5e7eb'
                }}>
                  <div>
                    <h3 style={{ margin: '0', color: '#374151', fontSize: '18px' }}>
                      📋 Shift: {shiftId}
                    </h3>
                    <p style={{ margin: '5px 0 0 0', color: '#6b7280', fontSize: '14px' }}>
                      👨‍💼 Supervisor: {shiftData.supervisorName} | 📅 Date: {shiftData.shiftDate || 'Unknown Date'}
                    </p>
                  </div>
                  <div style={{
                    background: '#dbeafe',
                    color: '#1e40af',
                    padding: '6px 12px',
                    borderRadius: '20px',
                    fontSize: '12px',
                    fontWeight: '600'
                  }}>
                    {shiftData.records.length} Records
                  </div>
                </div>
                
                <div style={{ overflowX: 'auto' }}>
                  <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                      <tr style={{ background: '#f3f4f6' }}>
                        <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600', borderRadius: '8px 0 0 8px' }}>Student</th>
                        <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600' }}>Email</th>
                        <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600' }}>College</th>
                        <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600' }}>Scan Time</th>
                        <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600', borderRadius: '0 8px 8px 0' }}>Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {shiftData.records.map((record, index) => (
                        <tr key={record._id || index} style={{ borderBottom: '1px solid #f3f4f6' }}>
                          <td style={{ padding: '12px', fontWeight: '500' }}>{record.studentName || 'N/A'}</td>
                          <td style={{ padding: '12px', color: '#6b7280' }}>{record.studentEmail || 'N/A'}</td>
                          <td style={{ padding: '12px', color: '#6b7280' }}>{record.college || 'N/A'}</td>
                          <td style={{ padding: '12px', color: '#6b7280' }}>
                            {record.scanTime ? new Date(record.scanTime).toLocaleString() : 'N/A'}
                          </td>
                          <td style={{ padding: '12px' }}>
                            <span style={{
                              background: record.status === 'Present' ? '#d1fae5' : '#fee2e2',
                              color: record.status === 'Present' ? '#065f46' : '#dc2626',
                              padding: '4px 8px',
                              borderRadius: '12px',
                              fontSize: '12px',
                              fontWeight: '500'
                            }}>
                              {record.status || 'Unknown'}
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div style={{ 
            textAlign: 'center', 
            padding: '40px', 
            color: '#6b7280',
            fontSize: '16px'
          }}>
            📋 No attendance records found in database. Records will appear when supervisors scan student QR codes and close their shifts.
          </div>
        )}
      </div>

      {/* Live Attendance Modal */}
      {showLiveModal && selectedShift && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(0, 0, 0, 0.5)',
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          zIndex: 1000
        }}>
          <div style={{
            background: 'white',
            borderRadius: '20px',
            padding: '30px',
            maxWidth: '90vw',
            maxHeight: '90vh',
            overflow: 'auto',
            boxShadow: '0 25px 50px rgba(0, 0, 0, 0.3)'
          }}>
            <div style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginBottom: '20px',
              paddingBottom: '15px',
              borderBottom: '2px solid #e5e7eb'
            }}>
              <div>
                <h2 style={{ margin: '0', color: '#1f2937', fontSize: '24px' }}>
                  🔴 Live Attendance Monitor
                </h2>
                <p style={{ margin: '5px 0 0 0', color: '#6b7280' }}>
                  Supervisor: {selectedShift.supervisorName || 'Transportation Supervisor'} | 
                  Started: {selectedShift.shiftStart ? new Date(selectedShift.shiftStart).toLocaleTimeString() : 'N/A'}
                </p>
              </div>
              <button
                onClick={closeModal}
                style={{
                  background: '#ef4444',
                  color: 'white',
                  border: 'none',
                  borderRadius: '50%',
                  width: '40px',
                  height: '40px',
                  fontSize: '18px',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center'
                }}
              >
                ✕
              </button>
            </div>

            <div style={{
              background: '#f0fdf4',
              border: '1px solid #bbf7d0',
              borderRadius: '12px',
              padding: '15px',
              marginBottom: '20px'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div style={{
                  width: '12px',
                  height: '12px',
                  borderRadius: '50%',
                  background: '#22c55e',
                  animation: 'pulse 1s infinite'
                }}></div>
                <span style={{ color: '#15803d', fontWeight: '600' }}>
                  Live Updates Every 10 Seconds | Current Scans: {liveAttendance.length}
                </span>
              </div>
            </div>

            {liveAttendance.length > 0 ? (
              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr style={{ background: '#f9fafb' }}>
                      <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600' }}>Student</th>
                      <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600' }}>Email</th>
                      <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600' }}>College</th>
                      <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600' }}>Scan Time</th>
                      <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600' }}>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {liveAttendance.map((record, index) => (
                      <tr key={record._id || index} style={{ 
                        borderBottom: '1px solid #f3f4f6',
                        background: index % 2 === 0 ? '#ffffff' : '#f8fafc'
                      }}>
                        <td style={{ padding: '12px', fontWeight: '500' }}>{record.studentName || 'N/A'}</td>
                        <td style={{ padding: '12px', color: '#6b7280' }}>{record.studentEmail || 'N/A'}</td>
                        <td style={{ padding: '12px', color: '#6b7280' }}>{record.college || 'N/A'}</td>
                        <td style={{ padding: '12px', color: '#6b7280' }}>
                          {record.scanTime ? new Date(record.scanTime).toLocaleString() : 'N/A'}
                        </td>
                        <td style={{ padding: '12px' }}>
                          <span style={{
                            background: '#d1fae5',
                            color: '#065f46',
                            padding: '4px 8px',
                            borderRadius: '12px',
                            fontSize: '12px',
                            fontWeight: '500'
                          }}>
                            {record.status || 'Present'}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div style={{ 
                textAlign: 'center', 
                padding: '40px', 
                color: '#6b7280',
                background: '#f9fafb',
                borderRadius: '12px'
              }}>
                📱 Waiting for attendance scans...
                <br />
                <small style={{ color: '#9ca3af' }}>
                  Records will appear here as the supervisor scans student QR codes
                </small>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Refresh Button */}
      <div style={{ marginTop: '20px', textAlign: 'center' }}>
        <button
          onClick={() => window.location.reload()}
          style={{
            background: '#3b82f6',
            color: 'white',
            border: 'none',
            padding: '12px 24px',
            borderRadius: '8px',
            fontSize: '14px',
            fontWeight: '600',
            cursor: 'pointer'
          }}
        >
          🔄 Refresh Data
        </button>
      </div>
    </div>
  );
}
