#!/bin/bash

echo "🔧 Fix Student Search Page"
echo "========================="

cd /home/unitrans

# Stop frontend
echo "⏹️ Stopping frontend..."
pm2 stop unitrans-frontend

# Navigate to frontend directory
cd frontend-new

# Create a clean admin users page
echo "🔧 Creating clean admin users page..."

cat > app/admin/users/page.js << 'EOF'
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function AdminUsersPage() {
    const [students, setStudents] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [searchTerm, setSearchTerm] = useState('');
    const [stats, setStats] = useState({
        totalStudents: 0,
        activeStudents: 0,
        totalAttendance: 0
    });
    const router = useRouter();

    // Check authentication
    useEffect(() => {
        const user = localStorage.getItem('user');
        const adminToken = localStorage.getItem('adminToken');
        
        if (!user || !adminToken) {
            router.push('/auth');
            return;
        }
    }, [router]);

    // Fetch students data
    const fetchStudents = async () => {
        try {
            setLoading(true);
            setError(null);
            
            // Try backend first
            const response = await fetch('http://localhost:3001/api/admin/students', {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (response.ok) {
                const data = await response.json();
                if (data.success && data.students) {
                    setStudents(data.students);
                    
                    // Calculate stats
                    const totalStudents = data.students.length;
                    const activeStudents = data.students.filter(student => student.status !== 'inactive').length;
                    const totalAttendance = data.students.reduce((sum, student) => sum + (student.attendanceCount || 0), 0);
                    
                    setStats({
                        totalStudents,
                        activeStudents,
                        totalAttendance
                    });
                } else {
                    throw new Error('Invalid response format');
                }
            } else {
                throw new Error(`Backend error: ${response.status}`);
            }
        } catch (error) {
            console.error('Error fetching students:', error);
            setError('Failed to fetch students data');
            
            // Fallback to empty data
            setStudents([]);
            setStats({
                totalStudents: 0,
                activeStudents: 0,
                totalAttendance: 0
            });
        } finally {
            setLoading(false);
        }
    };

    // Auto-refresh every 30 seconds
    useEffect(() => {
        fetchStudents();
        const interval = setInterval(fetchStudents, 30000);
        return () => clearInterval(interval);
    }, []);

    // Filter students based on search term
    const filteredStudents = students.filter(student => {
        if (!searchTerm) return true;
        const searchLower = searchTerm.toLowerCase();
        return (
            student.fullName?.toLowerCase().includes(searchLower) ||
            student.email?.toLowerCase().includes(searchLower) ||
            student.studentId?.toLowerCase().includes(searchLower) ||
            student.college?.toLowerCase().includes(searchLower)
        );
    });

    if (loading) {
        return (
            <div className="admin-page">
                <div className="page-header">
                    <h1>Student Search</h1>
                </div>
                <div className="loading-container">
                    <div className="loading-spinner"></div>
                    <p>Loading students...</p>
                </div>
            </div>
        );
    }

    return (
        <div className="admin-page">
            <div className="page-header">
                <h1>Student Search</h1>
                <button 
                    onClick={fetchStudents}
                    className="refresh-btn"
                    disabled={loading}
                >
                    🔄 Refresh
                </button>
            </div>

            {error && (
                <div className="error-message">
                    <p>⚠️ {error}</p>
                    <button onClick={fetchStudents}>Try Again</button>
                </div>
            )}

            {/* Stats Cards */}
            <div className="stats-grid">
                <div className="stat-card">
                    <h3>Total Students</h3>
                    <p className="stat-number">{stats.totalStudents}</p>
                </div>
                <div className="stat-card">
                    <h3>Active Students</h3>
                    <p className="stat-number">{stats.activeStudents}</p>
                </div>
                <div className="stat-card">
                    <h3>Total Attendance</h3>
                    <p className="stat-number">{stats.totalAttendance}</p>
                </div>
            </div>

            {/* Search Bar */}
            <div className="search-container">
                <input
                    type="text"
                    placeholder="Search students by name, email, ID, or college..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="search-input"
                />
            </div>

            {/* Students Table */}
            <div className="table-container">
                <table className="students-table">
                    <thead>
                        <tr>
                            <th>Student ID</th>
                            <th>Name</th>
                            <th>Email</th>
                            <th>College</th>
                            <th>Grade</th>
                            <th>Attendance Days</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredStudents.length === 0 ? (
                            <tr>
                                <td colSpan="7" className="no-data">
                                    {searchTerm ? 'No students found matching your search.' : 'No students found.'}
                                </td>
                            </tr>
                        ) : (
                            filteredStudents.map((student) => (
                                <tr key={student._id}>
                                    <td>{student.studentId || 'N/A'}</td>
                                    <td>{student.fullName || 'N/A'}</td>
                                    <td>{student.email || 'N/A'}</td>
                                    <td>{student.college || 'N/A'}</td>
                                    <td>{student.grade || 'N/A'}</td>
                                    <td className="attendance-count">
                                        {student.attendanceCount || 0}
                                    </td>
                                    <td>
                                        <span className={`status-badge ${student.status || 'active'}`}>
                                            {student.status || 'Active'}
                                        </span>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            <style jsx>{`
                .admin-page {
                    padding: 20px;
                    max-width: 1200px;
                    margin: 0 auto;
                }

                .page-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    margin-bottom: 30px;
                }

                .page-header h1 {
                    color: #333;
                    margin: 0;
                }

                .refresh-btn {
                    background: #007bff;
                    color: white;
                    border: none;
                    padding: 10px 20px;
                    border-radius: 5px;
                    cursor: pointer;
                    font-size: 14px;
                }

                .refresh-btn:hover {
                    background: #0056b3;
                }

                .refresh-btn:disabled {
                    background: #ccc;
                    cursor: not-allowed;
                }

                .loading-container {
                    text-align: center;
                    padding: 50px;
                }

                .loading-spinner {
                    border: 4px solid #f3f3f3;
                    border-top: 4px solid #007bff;
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

                .error-message {
                    background: #f8d7da;
                    color: #721c24;
                    padding: 15px;
                    border-radius: 5px;
                    margin-bottom: 20px;
                    text-align: center;
                }

                .error-message button {
                    background: #dc3545;
                    color: white;
                    border: none;
                    padding: 8px 16px;
                    border-radius: 4px;
                    cursor: pointer;
                    margin-top: 10px;
                }

                .stats-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 20px;
                    margin-bottom: 30px;
                }

                .stat-card {
                    background: white;
                    padding: 20px;
                    border-radius: 8px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                    text-align: center;
                }

                .stat-card h3 {
                    margin: 0 0 10px 0;
                    color: #666;
                    font-size: 14px;
                }

                .stat-number {
                    font-size: 24px;
                    font-weight: bold;
                    color: #007bff;
                    margin: 0;
                }

                .search-container {
                    margin-bottom: 20px;
                }

                .search-input {
                    width: 100%;
                    padding: 12px;
                    border: 1px solid #ddd;
                    border-radius: 5px;
                    font-size: 16px;
                }

                .table-container {
                    background: white;
                    border-radius: 8px;
                    overflow: hidden;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                }

                .students-table {
                    width: 100%;
                    border-collapse: collapse;
                }

                .students-table th {
                    background: #f8f9fa;
                    padding: 15px;
                    text-align: left;
                    font-weight: 600;
                    color: #333;
                    border-bottom: 2px solid #dee2e6;
                }

                .students-table td {
                    padding: 15px;
                    border-bottom: 1px solid #dee2e6;
                }

                .students-table tr:hover {
                    background: #f8f9fa;
                }

                .no-data {
                    text-align: center;
                    color: #666;
                    font-style: italic;
                }

                .attendance-count {
                    font-weight: bold;
                    color: #28a745;
                }

                .status-badge {
                    padding: 4px 8px;
                    border-radius: 4px;
                    font-size: 12px;
                    font-weight: 500;
                }

                .status-badge.active {
                    background: #d4edda;
                    color: #155724;
                }

                .status-badge.inactive {
                    background: #f8d7da;
                    color: #721c24;
                }
            `}</style>
        </div>
    );
}
EOF

# Create CSS file for the page
echo "🔧 Creating CSS file..."

cat > app/admin/users/users.css << 'EOF'
/* Student Search Page Styles */
.admin-page {
    padding: 20px;
    max-width: 1200px;
    margin: 0 auto;
    background: #f8f9fa;
    min-height: 100vh;
}

.page-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 30px;
    background: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.page-header h1 {
    color: #333;
    margin: 0;
    font-size: 28px;
}

.refresh-btn {
    background: #007bff;
    color: white;
    border: none;
    padding: 12px 24px;
    border-radius: 6px;
    cursor: pointer;
    font-size: 14px;
    font-weight: 500;
    transition: background-color 0.3s;
}

.refresh-btn:hover {
    background: #0056b3;
}

.refresh-btn:disabled {
    background: #ccc;
    cursor: not-allowed;
}

.loading-container {
    text-align: center;
    padding: 50px;
    background: white;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.loading-spinner {
    border: 4px solid #f3f3f3;
    border-top: 4px solid #007bff;
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

.error-message {
    background: #f8d7da;
    color: #721c24;
    padding: 15px;
    border-radius: 5px;
    margin-bottom: 20px;
    text-align: center;
    border: 1px solid #f5c6cb;
}

.error-message button {
    background: #dc3545;
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 4px;
    cursor: pointer;
    margin-top: 10px;
    transition: background-color 0.3s;
}

.error-message button:hover {
    background: #c82333;
}

.stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 20px;
    margin-bottom: 30px;
}

.stat-card {
    background: white;
    padding: 25px;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    text-align: center;
    transition: transform 0.3s;
}

.stat-card:hover {
    transform: translateY(-2px);
}

.stat-card h3 {
    margin: 0 0 10px 0;
    color: #666;
    font-size: 14px;
    font-weight: 500;
}

.stat-number {
    font-size: 32px;
    font-weight: bold;
    color: #007bff;
    margin: 0;
}

.search-container {
    margin-bottom: 20px;
    background: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.search-input {
    width: 100%;
    padding: 12px 16px;
    border: 1px solid #ddd;
    border-radius: 6px;
    font-size: 16px;
    transition: border-color 0.3s;
}

.search-input:focus {
    outline: none;
    border-color: #007bff;
    box-shadow: 0 0 0 3px rgba(0,123,255,0.1);
}

.table-container {
    background: white;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.students-table {
    width: 100%;
    border-collapse: collapse;
}

.students-table th {
    background: #f8f9fa;
    padding: 15px;
    text-align: left;
    font-weight: 600;
    color: #333;
    border-bottom: 2px solid #dee2e6;
}

.students-table td {
    padding: 15px;
    border-bottom: 1px solid #dee2e6;
}

.students-table tr:hover {
    background: #f8f9fa;
}

.no-data {
    text-align: center;
    color: #666;
    font-style: italic;
    padding: 40px;
}

.attendance-count {
    font-weight: bold;
    color: #28a745;
    font-size: 16px;
}

.status-badge {
    padding: 6px 12px;
    border-radius: 4px;
    font-size: 12px;
    font-weight: 500;
    text-transform: uppercase;
}

.status-badge.active {
    background: #d4edda;
    color: #155724;
}

.status-badge.inactive {
    background: #f8d7da;
    color: #721c24;
}

/* Responsive Design */
@media (max-width: 768px) {
    .admin-page {
        padding: 10px;
    }
    
    .page-header {
        flex-direction: column;
        gap: 15px;
        text-align: center;
    }
    
    .stats-grid {
        grid-template-columns: 1fr;
    }
    
    .students-table {
        font-size: 14px;
    }
    
    .students-table th,
    .students-table td {
        padding: 10px 8px;
    }
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

# Test frontend
echo "🏥 Testing frontend..."
curl -s http://localhost:3000 | head -20 || echo "Frontend not responding"

# Final status
echo "📊 Final PM2 status:"
pm2 status

echo ""
echo "✅ Student Search page fix completed!"
echo "🌍 Test your project at: https://unibus.online/admin/users"
echo "📋 Student Search page should now work properly"
