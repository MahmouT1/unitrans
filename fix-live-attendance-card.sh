#!/bin/bash

echo "🔧 Adding Live Attendance Supervisor Card"

cd /home/unitrans/frontend-new

# Backup current file
cp app/admin/attendance/page.js app/admin/attendance/page.js.backup2

# Add the live attendance supervisor card
echo "🔧 Adding live attendance supervisor card..."

# Create the enhanced attendance page with live supervisor card
cat > app/admin/attendance/page.js << 'EOF'
'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useLanguage } from '../../../lib/contexts/LanguageContext';
import LanguageSwitcher from '../../../components/LanguageSwitcher';
import '../../../components/admin/StudentAttendance.css';

// Helper function to calculate summary statistics
const calculateSummaryStats = (studentsList = []) => {
  if (!Array.isArray(studentsList)) {
    return {
      totalStudents: 0,
      activeStudents: 0,
      inactiveStudents: 0,
      criticalStatus: 0
    };
  }
  
  return {
    totalStudents: studentsList.length,
    activeStudents: studentsList.filter(s => s.status === 'Active').length,
    inactiveStudents: studentsList.filter(s => s.status === 'Inactive').length,
    criticalStatus: studentsList.filter(s => s.status === 'Critical').length
  };
};

function AdminAttendancePageContent() {
  const [user, setUser] = useState(null);
  const router = useRouter();
  const { t, isRTL } = useLanguage();
  const [loading, setLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  
  // Attendance records states
  const [attendanceRecords, setAttendanceRecords] = useState([]);
  const [pagination, setPagination] = useState({
    currentPage: 1,
    totalPages: 1,
    totalRecords: 0,
    limit: 20,
    hasNextPage: false,
    hasPrevPage: false
  });
  
  // Filter states
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [selectedSupervisor, setSelectedSupervisor] = useState('All Supervisors');
  const [supervisors, setSupervisors] = useState([]);
  
  // Active shifts for live monitoring
  const [activeShifts, setActiveShifts] = useState([]);
  const [shiftIndicator, setShiftIndicator] = useState(null);
  
  // Shift-based pagination states
  const [supervisorShifts, setSupervisorShifts] = useState([]);
  const [shiftPages, setShiftPages] = useState([]);
  const [currentShiftPage, setCurrentShiftPage] = useState(1);
  
  // Summary stats
  const [summaryStats, setSummaryStats] = useState({
    totalRecords: 0,
    totalStudents: 0,
    totalShifts: 0,
    todayRecords: 0,
    activeSupervisors: 0
  });

  // Initialize user and load data
  useEffect(() => {
    const userData = localStorage.getItem('user');
    if (userData) {
      try {
        const parsedUser = JSON.parse(userData);
        setUser(parsedUser);
      } catch (error) {
        console.error('Error parsing user data:', error);
        router.push('/auth');
      }
    } else {
      router.push('/login');
    }
  }, [router]);

  // Load attendance records when user, date, or supervisor changes
  useEffect(() => {
    if (user) {
      loadAttendanceRecords();
      loadSupervisors();
      loadActiveShifts();
    }
  }, [user, selectedDate, selectedSupervisor, pagination.currentPage]);

  // Auto-refresh data every 30 seconds
  useEffect(() => {
    if (!user) return;

    const interval = setInterval(() => {
      loadAttendanceRecords();
      loadActiveShifts();
    }, 30000);

    return () => clearInterval(interval);
  }, [user, selectedDate, selectedSupervisor]);

  const loadAttendanceRecords = async (isRefresh = false) => {
    try {
      if (isRefresh) {
        setIsRefreshing(true);
      }

      const token = localStorage.getItem('token');
      const params = new URLSearchParams({
        page: pagination.currentPage.toString(),
        limit: pagination.limit.toString()
      });

      if (selectedDate) {
        params.append('date', selectedDate);
      }

      if (selectedSupervisor && selectedSupervisor !== 'All Supervisors') {
        params.append('supervisorId', selectedSupervisor);
      }

      const response = await fetch(`/api/attendance/all-records?${params}`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        if (data.success && Array.isArray(data.records)) {
          setAttendanceRecords(data.records);
          setPagination(data.pagination || {
            currentPage: 1,
            totalPages: 1,
            totalRecords: 0,
            limit: 20,
            hasNextPage: false,
            hasPrevPage: false
          });
          
          // Calculate summary stats with null checks
          const records = data.records;
          const uniqueStudents = new Set(records.map(record => record.studentEmail).filter(Boolean));
          const uniqueShifts = new Set(records.map(record => record.shiftId).filter(Boolean));
          
          setSummaryStats({
            totalRecords: data.pagination?.totalRecords || 0,
            totalStudents: uniqueStudents.size,
            totalShifts: uniqueShifts.size,
            todayRecords: records.filter(record => 
              record.scanTime && new Date(record.scanTime).toDateString() === new Date().toDateString()
            ).length,
            activeSupervisors: uniqueShifts.size
          });
        } else {
          setAttendanceRecords([]);
          setSummaryStats({
            totalRecords: 0,
            totalStudents: 0,
            totalShifts: 0,
            todayRecords: 0,
            activeSupervisors: 0
          });
        }
      } else {
        console.error('Failed to load attendance records:', response.status);
        setAttendanceRecords([]);
      }
    } catch (error) {
      console.error('Error loading attendance records:', error);
      setAttendanceRecords([]);
    } finally {
      setLoading(false);
      if (isRefresh) {
        setIsRefreshing(false);
      }
    }
  };

  const loadSupervisors = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/shifts?date=${selectedDate}&status=closed`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        if (data.success && Array.isArray(data.shifts)) {
          const supervisorMap = new Map();
          data.shifts.forEach(shift => {
            if (shift.supervisorId && shift.supervisorName) {
              supervisorMap.set(shift.supervisorId, {
                id: shift.supervisorId,
                name: shift.supervisorName
              });
            }
          });
          const uniqueSupervisors = Array.from(supervisorMap.values());
          setSupervisors(uniqueSupervisors);
        } else {
          setSupervisors([]);
        }
      } else {
        setSupervisors([]);
      }
    } catch (error) {
      console.error('Error loading supervisors:', error);
      setSupervisors([]);
    }
  };

  const loadActiveShifts = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/shifts?date=${selectedDate}&status=open`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        if (data.success && Array.isArray(data.shifts)) {
          setActiveShifts(data.shifts);
          
          if (data.shifts && data.shifts.length > 0) {
            setShiftIndicator({
              isActive: true,
              count: data.shifts.length,
              shifts: data.shifts
            });
          } else {
            setShiftIndicator(null);
          }
          console.log('Active shifts loaded:', data.shifts.length);
        } else {
          setActiveShifts([]);
          setShiftIndicator(null);
        }
      } else {
        setActiveShifts([]);
        setShiftIndicator(null);
      }
    } catch (error) {
      console.error('Error loading active shifts:', error);
      setActiveShifts([]);
      setShiftIndicator(null);
    }
  };

  const formatTime = (date) => {
    if (!date) return 'N/A';
    return new Date(date).toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: true
    });
  };

  const formatDate = (dateString) => {
    if (!dateString) return 'All Dates';
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  const formatGrade = (grade) => {
    if (!grade) return 'N/A';
    const gradeMap = {
      'first-year': 'First Year',
      'second-year': 'Second Year',
      'third-year': 'Third Year',
      'fourth-year': 'Fourth Year'
    };
    return gradeMap[grade] || grade;
  };

  const handlePageChange = (newPage) => {
    setPagination(prev => ({ ...prev, currentPage: newPage }));
  };

  const handleRefresh = () => {
    loadAttendanceRecords(true);
    loadSupervisors();
    loadActiveShifts();
  };

  const handleDateChange = (newDate) => {
    setSelectedDate(newDate);
    setPagination(prev => ({ ...prev, currentPage: 1 }));
  };

  const handleSupervisorChange = (newSupervisor) => {
    setSelectedSupervisor(newSupervisor);
    setPagination(prev => ({ ...prev, currentPage: 1 }));
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
      padding: '20px', 
      maxWidth: '1600px', 
      margin: '0 auto',
      fontFamily: 'Arial, sans-serif',
      background: 'linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%)',
      minHeight: '100vh'
    }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '30px' }}>
        <h1 style={{ 
          color: '#333', 
          margin: '0',
          fontSize: '28px'
        }}>
          Attendance Records Management
        </h1>
        
        <div style={{ 
          display: 'flex', 
          alignItems: 'center', 
          gap: '15px'
        }}>
          <LanguageSwitcher variant="admin" />
          <button
            onClick={handleRefresh}
            disabled={isRefreshing}
            style={{
              padding: '10px 20px',
              background: isRefreshing ? '#9ca3af' : '#3b82f6',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              cursor: isRefreshing ? 'not-allowed' : 'pointer',
              fontSize: '14px',
              fontWeight: '600'
            }}
          >
            {isRefreshing ? 'Refreshing...' : 'Refresh'}
          </button>
        </div>
      </div>

      {/* Live Attendance Supervisor Card */}
      {shiftIndicator && shiftIndicator.isActive && (
        <div style={{
          background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
          color: 'white',
          padding: '20px',
          borderRadius: '12px',
          marginBottom: '30px',
          boxShadow: '0 8px 25px rgba(16, 185, 129, 0.3)',
          border: '2px solid rgba(255, 255, 255, 0.2)',
          position: 'relative',
          overflow: 'hidden'
        }}>
          <div style={{
            position: 'absolute',
            top: '-10px',
            right: '-10px',
            width: '40px',
            height: '40px',
            background: 'rgba(255, 255, 255, 0.2)',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: '20px'
          }}>
            🟢
          </div>
          
          <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginBottom: '15px' }}>
            <div style={{
              background: 'rgba(255, 255, 255, 0.2)',
              padding: '10px',
              borderRadius: '8px',
              fontSize: '24px'
            }}>
              👨‍💼
            </div>
            <div>
              <h3 style={{ margin: '0', fontSize: '20px', fontWeight: 'bold' }}>
                Live Attendance Supervisor
              </h3>
              <p style={{ margin: '5px 0 0 0', opacity: '0.9', fontSize: '14px' }}>
                Active supervisors are currently monitoring attendance
              </p>
            </div>
          </div>
          
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '15px' }}>
            <div style={{
              background: 'rgba(255, 255, 255, 0.15)',
              padding: '15px',
              borderRadius: '8px',
              textAlign: 'center'
            }}>
              <div style={{ fontSize: '24px', fontWeight: 'bold', marginBottom: '5px' }}>
                {shiftIndicator.count}
              </div>
              <div style={{ fontSize: '12px', opacity: '0.9' }}>
                Active Shifts
              </div>
            </div>
            
            <div style={{
              background: 'rgba(255, 255, 255, 0.15)',
              padding: '15px',
              borderRadius: '8px',
              textAlign: 'center'
            }}>
              <div style={{ fontSize: '24px', fontWeight: 'bold', marginBottom: '5px' }}>
                {summaryStats.todayRecords}
              </div>
              <div style={{ fontSize: '12px', opacity: '0.9' }}>
                Today's Records
              </div>
            </div>
            
            <div style={{
              background: 'rgba(255, 255, 255, 0.15)',
              padding: '15px',
              borderRadius: '8px',
              textAlign: 'center'
            }}>
              <div style={{ fontSize: '24px', fontWeight: 'bold', marginBottom: '5px' }}>
                {summaryStats.totalStudents}
              </div>
              <div style={{ fontSize: '12px', opacity: '0.9' }}>
                Total Students
              </div>
            </div>
          </div>
          
          <div style={{ marginTop: '15px', fontSize: '12px', opacity: '0.8' }}>
            Last updated: {new Date().toLocaleTimeString()}
          </div>
        </div>
      )}

      {/* Summary Cards */}
      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', 
        gap: '20px', 
        marginBottom: '30px' 
      }}>
        <div style={{ 
          background: 'white', 
          padding: '20px', 
          borderRadius: '12px', 
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
          textAlign: 'center'
        }}>
          <h3 style={{ margin: '0 0 10px 0', color: '#6b7280', fontSize: '14px' }}>Total Records</h3>
          <p style={{ margin: '0', fontSize: '24px', fontWeight: 'bold', color: '#1f2937' }}>
            {summaryStats.totalRecords}
          </p>
        </div>
        
        <div style={{ 
          background: 'white', 
          padding: '20px', 
          borderRadius: '12px', 
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
          textAlign: 'center'
        }}>
          <h3 style={{ margin: '0 0 10px 0', color: '#6b7280', fontSize: '14px' }}>Total Students</h3>
          <p style={{ margin: '0', fontSize: '24px', fontWeight: 'bold', color: '#1f2937' }}>
            {summaryStats.totalStudents}
          </p>
        </div>
        
        <div style={{ 
          background: 'white', 
          padding: '20px', 
          borderRadius: '12px', 
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
          textAlign: 'center'
        }}>
          <h3 style={{ margin: '0 0 10px 0', color: '#6b7280', fontSize: '14px' }}>Today Records</h3>
          <p style={{ margin: '0', fontSize: '24px', fontWeight: 'bold', color: '#1f2937' }}>
            {summaryStats.todayRecords}
          </p>
        </div>
        
        <div style={{ 
          background: 'white', 
          padding: '20px', 
          borderRadius: '12px', 
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
          textAlign: 'center'
        }}>
          <h3 style={{ margin: '0 0 10px 0', color: '#6b7280', fontSize: '14px' }}>Active Shifts</h3>
          <p style={{ margin: '0', fontSize: '24px', fontWeight: 'bold', color: '#1f2937' }}>
            {summaryStats.activeSupervisors}
          </p>
        </div>
      </div>

      {/* Filters */}
      <div style={{ 
        background: 'white', 
        padding: '20px', 
        borderRadius: '12px', 
        boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
        marginBottom: '20px'
      }}>
        <div style={{ display: 'flex', gap: '20px', alignItems: 'center', flexWrap: 'wrap' }}>
          <div>
            <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600', color: '#374151' }}>
              Date:
            </label>
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => handleDateChange(e.target.value)}
              style={{
                padding: '8px 12px',
                border: '1px solid #d1d5db',
                borderRadius: '6px',
                fontSize: '14px'
              }}
            />
          </div>
          
          <div>
            <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600', color: '#374151' }}>
              Supervisor:
            </label>
            <select
              value={selectedSupervisor}
              onChange={(e) => handleSupervisorChange(e.target.value)}
              style={{
                padding: '8px 12px',
                border: '1px solid #d1d5db',
                borderRadius: '6px',
                fontSize: '14px',
                minWidth: '200px'
              }}
            >
              <option value="All Supervisors">All Supervisors</option>
              {Array.isArray(supervisors) && supervisors.map(supervisor => (
                <option key={supervisor.id} value={supervisor.id}>
                  {supervisor.name}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Attendance Records Table */}
      <div style={{ 
        background: 'white', 
        borderRadius: '12px', 
        boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
        overflow: 'hidden'
      }}>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: '#f8fafc' }}>
                <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600', color: '#374151' }}>Student</th>
                <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600', color: '#374151' }}>College</th>
                <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600', color: '#374151' }}>Grade</th>
                <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600', color: '#374151' }}>Scan Time</th>
                <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600', color: '#374151' }}>Location</th>
                <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600', color: '#374151' }}>Status</th>
                <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600', color: '#374151' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {Array.isArray(attendanceRecords) && attendanceRecords.length > 0 ? (
                attendanceRecords.map((record, index) => (
                  <tr key={record._id || index} style={{ borderBottom: '1px solid #e5e7eb' }}>
                    <td style={{ padding: '12px' }}>
                      <div>
                        <div style={{ fontWeight: '600', color: '#1f2937' }}>
                          {record.studentName || 'N/A'}
                        </div>
                        <div style={{ fontSize: '12px', color: '#6b7280' }}>
                          {record.studentEmail || 'N/A'}
                        </div>
                      </div>
                    </td>
                    <td style={{ padding: '12px', color: '#374151' }}>
                      {record.college || 'N/A'}
                    </td>
                    <td style={{ padding: '12px', color: '#374151' }}>
                      {formatGrade(record.grade)}
                    </td>
                    <td style={{ padding: '12px', color: '#374151' }}>
                      {formatTime(record.scanTime)}
                    </td>
                    <td style={{ padding: '12px', color: '#374151' }}>
                      {record.location || 'N/A'}
                    </td>
                    <td style={{ padding: '12px' }}>
                      <span style={{
                        padding: '4px 8px',
                        borderRadius: '4px',
                        fontSize: '12px',
                        fontWeight: '600',
                        background: record.status === 'Present' ? '#dcfce7' : '#fef3c7',
                        color: record.status === 'Present' ? '#166534' : '#92400e'
                      }}>
                        {record.status || 'Unknown'}
                      </span>
                    </td>
                    <td style={{ padding: '12px' }}>
                      <button
                        onClick={() => {
                          if (confirm('Are you sure you want to delete this record?')) {
                            console.log('Delete record:', record._id);
                          }
                        }}
                        style={{
                          background: 'none',
                          border: 'none',
                          cursor: 'pointer',
                          padding: '8px',
                          borderRadius: '8px',
                          color: '#ef4444'
                        }}
                        title="Delete record"
                      >
                        🗑️
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="7" style={{ 
                    padding: '40px 20px', 
                    textAlign: 'center', 
                    color: '#6b7280',
                    fontSize: '16px'
                  }}>
                    No attendance records found
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Pagination */}
      {pagination.totalPages > 1 && (
        <div style={{ 
          display: 'flex', 
          justifyContent: 'center', 
          alignItems: 'center', 
          gap: '10px',
          marginTop: '24px',
          paddingTop: '20px',
          borderTop: '1px solid #e5e7eb'
        }}>
          <button
            onClick={() => handlePageChange(pagination.currentPage - 1)}
            disabled={!pagination.hasPrevPage}
            style={{
              padding: '8px 16px',
              border: '1px solid #d1d5db',
              borderRadius: '8px',
              background: pagination.hasPrevPage ? 'white' : '#f9fafb',
              color: pagination.hasPrevPage ? '#374151' : '#9ca3af',
              cursor: pagination.hasPrevPage ? 'pointer' : 'not-allowed',
              fontSize: '14px',
              fontWeight: '500'
            }}
          >
            ← Previous
          </button>
          
          <span style={{ padding: '8px 16px', color: '#6b7280' }}>
            Page {pagination.currentPage} of {pagination.totalPages}
          </span>
          
          <button
            onClick={() => handlePageChange(pagination.currentPage + 1)}
            disabled={!pagination.hasNextPage}
            style={{
              padding: '8px 16px',
              border: '1px solid #d1d5db',
              borderRadius: '8px',
              background: pagination.hasNextPage ? 'white' : '#f9fafb',
              color: pagination.hasNextPage ? '#374151' : '#9ca3af',
              cursor: pagination.hasNextPage ? 'pointer' : 'not-allowed',
              fontSize: '14px',
              fontWeight: '500'
            }}
          >
            Next →
          </button>
        </div>
      )}
    </div>
  );
}

export default function AdminAttendancePage() {
  return <AdminAttendancePageContent />;
}
EOF

# Rebuild frontend
echo "🏗️ Rebuilding frontend..."
npm run build

# Restart frontend
echo "🔄 Restarting frontend..."
pm2 stop unitrans-frontend
pm2 start "npm run start" --name "unitrans-frontend"

echo "✅ Live attendance supervisor card added!"
echo "🌍 Test at: https://unibus.online/admin/attendance"
