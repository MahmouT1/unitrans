#!/bin/bash

echo "🔧 Fix Confirmation Dialog"
echo "========================="

cd /home/unitrans

# Stop frontend
echo "⏹️ Stopping frontend..."
pm2 stop unitrans-frontend

# Navigate to frontend directory
cd frontend-new

# Update the supervisor dashboard page with fixed confirmation dialog
echo "🔧 Updating supervisor dashboard..."

cat > app/admin/supervisor-dashboard/page.js << 'EOF'
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function SupervisorDashboard() {
    const [currentShift, setCurrentShift] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const router = useRouter();

    // Function to fetch current shift
    const fetchCurrentShift = async () => {
        try {
            const response = await fetch('/api/shifts/active');
            const data = await response.json();
            
            if (data.success && data.shifts && data.shifts.length > 0) {
                setCurrentShift(data.shifts[0]);
            } else {
                setCurrentShift(null);
            }
            setError(null);
        } catch (err) {
            console.error('Error fetching shift:', err);
            setError('Failed to fetch shift status');
        } finally {
            setLoading(false);
        }
    };

    // Fetch current shift on mount
    useEffect(() => {
        fetchCurrentShift();
        // Refresh every 30 seconds
        const interval = setInterval(fetchCurrentShift, 30000);
        return () => clearInterval(interval);
    }, []);

    // Function to open new shift
    const openShift = async () => {
        try {
            setLoading(true);
            const user = JSON.parse(localStorage.getItem('user'));
            
            const response = await fetch('/api/shifts', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    supervisorId: user?._id || 'default-supervisor',
                    supervisorName: user?.fullName || 'Transportation Supervisor',
                    supervisorEmail: user?.email || 'supervisor@unibus.com',
                    location: 'Main Station'
                }),
            });

            const data = await response.json();
            
            if (data.success) {
                await fetchCurrentShift();
            } else {
                setError('Failed to open shift: ' + data.message);
            }
        } catch (err) {
            console.error('Error opening shift:', err);
            setError('Failed to open shift');
        } finally {
            setLoading(false);
        }
    };

    // Function to close current shift
    const closeShift = async () => {
        if (!currentShift?.id) {
            setError('No active shift to close');
            return;
        }

        try {
            setLoading(true);
            
            // Use the /:id/close endpoint
            const response = await fetch(`/api/shifts/${currentShift.id}/close`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            const data = await response.json();
            
            if (data.success) {
                await fetchCurrentShift();
            } else {
                setError('Failed to close shift: ' + data.message);
            }
        } catch (err) {
            console.error('Error closing shift:', err);
            setError('Failed to close shift');
        } finally {
            setLoading(false);
        }
    };

    // Function to handle close shift confirmation
    const handleCloseShift = () => {
        const message = 'Are you sure you want to close this shift?\n\n' +
                       'Shift ID: ' + currentShift.id + '\n' +
                       'Started: ' + new Date(currentShift.startTime).toLocaleString() + '\n\n' +
                       'This action cannot be undone.';
                       
        if (confirm(message)) {
            closeShift();
        }
    };

    if (loading) {
        return (
            <div className="loading-container">
                <div className="loading-spinner"></div>
                <p>Loading shift status...</p>
            </div>
        );
    }

    return (
        <div className="supervisor-dashboard">
            {error && (
                <div className="error-message">
                    <span className="error-icon">❌</span>
                    <span>{error}</span>
                    <button className="close-btn" onClick={() => setError(null)}>×</button>
                </div>
            )}

            <div className="shift-status-card">
                {currentShift ? (
                    <>
                        <div className="status-header">
                            <span className="status-indicator active"></span>
                            <h2>Shift Status: OPEN</h2>
                        </div>
                        
                        <div className="shift-details">
                            <p>
                                <span className="detail-icon">🕒</span>
                                <strong>Started:</strong> {new Date(currentShift.startTime).toLocaleString()}
                            </p>
                            <p>
                                <span className="detail-icon">📊</span>
                                <strong>Total Scans:</strong> {currentShift.totalScans || 0}
                            </p>
                            <p>
                                <span className="detail-icon">🆔</span>
                                <strong>Shift ID:</strong> {currentShift.id}
                            </p>
                            <p>
                                <span className="detail-icon">👨‍💼</span>
                                <strong>Supervisor:</strong> {currentShift.supervisorName}
                            </p>
                        </div>

                        <div className="warning-message">
                            ⚠️ This shift will remain OPEN until manually closed by the supervisor
                        </div>

                        <button className="close-shift-btn" onClick={handleCloseShift}>
                            🔴 CLOSE SHIFT
                        </button>
                    </>
                ) : (
                    <>
                        <div className="status-header">
                            <span className="status-indicator inactive"></span>
                            <h2>Shift Status: CLOSED</h2>
                        </div>
                        
                        <p className="no-shift-message">
                            No active shift. Click "Open Shift" to start working.
                        </p>
                        
                        <p className="shift-info">
                            Shifts stay open until manually closed by the supervisor.
                        </p>

                        <button className="open-shift-btn" onClick={openShift}>
                            Open Shift
                        </button>
                    </>
                )}
            </div>

            <style jsx>{`
                .supervisor-dashboard {
                    padding: 20px;
                    max-width: 800px;
                    margin: 0 auto;
                }

                .error-message {
                    background: #ff4444;
                    color: white;
                    padding: 15px;
                    border-radius: 8px;
                    margin-bottom: 20px;
                    display: flex;
                    align-items: center;
                    gap: 10px;
                }

                .error-icon {
                    font-size: 20px;
                }

                .close-btn {
                    margin-left: auto;
                    background: none;
                    border: none;
                    color: white;
                    font-size: 20px;
                    cursor: pointer;
                }

                .shift-status-card {
                    background: white;
                    border-radius: 12px;
                    padding: 25px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                }

                .status-header {
                    display: flex;
                    align-items: center;
                    gap: 15px;
                    margin-bottom: 20px;
                }

                .status-indicator {
                    width: 20px;
                    height: 20px;
                    border-radius: 50%;
                }

                .status-indicator.active {
                    background: #00c853;
                    box-shadow: 0 0 10px rgba(0,200,83,0.3);
                }

                .status-indicator.inactive {
                    background: #ff4444;
                    box-shadow: 0 0 10px rgba(255,68,68,0.3);
                }

                .shift-details {
                    background: #f8f9fa;
                    border-radius: 8px;
                    padding: 20px;
                    margin-bottom: 20px;
                }

                .detail-icon {
                    margin-right: 10px;
                }

                .warning-message {
                    background: #4caf50;
                    color: white;
                    padding: 15px;
                    border-radius: 8px;
                    margin: 20px 0;
                    text-align: center;
                }

                .no-shift-message {
                    font-size: 18px;
                    color: #666;
                    text-align: center;
                    margin: 30px 0;
                }

                .shift-info {
                    color: #666;
                    text-align: center;
                    margin-bottom: 30px;
                }

                .open-shift-btn, .close-shift-btn {
                    width: 100%;
                    padding: 15px;
                    border: none;
                    border-radius: 8px;
                    font-size: 16px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: all 0.3s ease;
                }

                .open-shift-btn {
                    background: #00c853;
                    color: white;
                }

                .open-shift-btn:hover {
                    background: #00a844;
                    transform: translateY(-1px);
                }

                .close-shift-btn {
                    background: #ff4444;
                    color: white;
                }

                .close-shift-btn:hover {
                    background: #ff1111;
                    transform: translateY(-1px);
                }

                .loading-container {
                    text-align: center;
                    padding: 50px;
                }

                .loading-spinner {
                    border: 4px solid #f3f3f3;
                    border-top: 4px solid #3498db;
                    border-radius: 50%;
                    width: 40px;
                    height: 40px;
                    animation: spin 1s linear infinite;
                    margin: 0 auto 20px;
                }

                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }
            `}</style>
        </div>
    );
}
EOF

# Build frontend
echo "🔧 Building frontend..."
npm run build

# Start frontend
echo "🚀 Starting frontend..."
pm2 start unitrans-frontend

# Wait for frontend to start
sleep 5

# Final status
echo "📊 Final PM2 status:"
pm2 status

echo ""
echo "✅ Confirmation dialog fix completed!"
echo "🌍 Test your project at: https://unibus.online/admin/supervisor-dashboard"
echo "📋 The confirmation dialog should now work correctly"
