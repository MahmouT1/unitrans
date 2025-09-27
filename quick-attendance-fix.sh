#!/bin/bash

echo "🔧 Quick Attendance Page Fix"

cd /home/unitrans/frontend-new

# Add null checks to prevent length errors
echo "🔧 Adding null checks to attendance page..."

# Create a simple fixed version
cat > app/admin/attendance/page.js << 'EOF'
'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function AdminAttendancePage() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [attendanceRecords, setAttendanceRecords] = useState([]);
  const router = useRouter();

  useEffect(() => {
    const userData = localStorage.getItem('user');
    if (userData) {
      try {
        setUser(JSON.parse(userData));
      } catch (error) {
        router.push('/auth');
      }
    } else {
      router.push('/auth');
    }
    setLoading(false);
  }, [router]);

  useEffect(() => {
    if (user) {
      loadAttendanceRecords();
    }
  }, [user]);

  const loadAttendanceRecords = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/attendance/all-records', {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        if (data.success && Array.isArray(data.records)) {
          setAttendanceRecords(data.records);
        } else {
          setAttendanceRecords([]);
        }
      } else {
        setAttendanceRecords([]);
      }
    } catch (error) {
      console.error('Error loading attendance records:', error);
      setAttendanceRecords([]);
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
    <div style={{ padding: '20px', maxWidth: '1200px', margin: '0 auto' }}>
      <h1 style={{ marginBottom: '20px' }}>Attendance Records</h1>
      
      <div style={{ 
        background: 'white', 
        borderRadius: '8px', 
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
        overflow: 'hidden'
      }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ background: '#f8fafc' }}>
              <th style={{ padding: '12px', textAlign: 'left' }}>Student</th>
              <th style={{ padding: '12px', textAlign: 'left' }}>College</th>
              <th style={{ padding: '12px', textAlign: 'left' }}>Scan Time</th>
              <th style={{ padding: '12px', textAlign: 'left' }}>Status</th>
            </tr>
          </thead>
          <tbody>
            {Array.isArray(attendanceRecords) && attendanceRecords.length > 0 ? (
              attendanceRecords.map((record, index) => (
                <tr key={record._id || index} style={{ borderBottom: '1px solid #e5e7eb' }}>
                  <td style={{ padding: '12px' }}>
                    {record.studentName || 'N/A'}
                  </td>
                  <td style={{ padding: '12px' }}>
                    {record.college || 'N/A'}
                  </td>
                  <td style={{ padding: '12px' }}>
                    {record.scanTime ? new Date(record.scanTime).toLocaleString() : 'N/A'}
                  </td>
                  <td style={{ padding: '12px' }}>
                    <span style={{
                      padding: '4px 8px',
                      borderRadius: '4px',
                      background: record.status === 'Present' ? '#dcfce7' : '#fef3c7',
                      color: record.status === 'Present' ? '#166534' : '#92400e'
                    }}>
                      {record.status || 'Unknown'}
                    </span>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan="4" style={{ padding: '40px', textAlign: 'center' }}>
                  No attendance records found
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
EOF

# Rebuild and restart
npm run build
pm2 restart unitrans-frontend

echo "✅ Quick attendance fix complete!"
echo "🌍 Test at: https://unibus.online/admin/attendance"
