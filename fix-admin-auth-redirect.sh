#!/bin/bash

echo "🔧 Fix Admin Auth Redirect Issue"
echo "==============================="

cd /home/unitrans

# Stop frontend
echo "⏹️ Stopping frontend..."
pm2 stop unitrans-frontend

# Navigate to frontend directory
cd frontend-new

# Fix the student search page authentication
echo "🔧 Fixing student search page authentication..."

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
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [authLoading, setAuthLoading] = useState(true);
    const router = useRouter();

    // Check authentication with better logic
    useEffect(() => {
        const checkAuth = () => {
            try {
                const user = localStorage.getItem('user');
                const adminToken = localStorage.getItem('adminToken');
                const userRole = localStorage.getItem('userRole');
                
                console.log('Auth check:', { user: !!user, adminToken: !!adminToken, userRole });
                
                // Check if user exists and has admin role
                if (user && adminToken && (userRole === 'admin' || userRole === 'supervisor')) {
                    setIsAuthenticated(true);
                    setAuthLoading(false);
                    return;
                }
                
                // If no valid auth, redirect to login
                console.log('No valid auth, redirecting to login');
                router.push('/auth');
            } catch (error) {
                console.error('Auth check error:', error);
                router.push('/auth');
            }
        };

        // Check auth immediately
        checkAuth();
        
        // Also check on storage changes
        const handleStorageChange = () => {
            checkAuth();
        };
        
        window.addEventListener('storage', handleStorageChange);
        
        return () => {
            window.removeEventListener('storage', handleStorageChange);
        };
    }, [router]);

    // Safe array functions to prevent errors
    const safeArray = (arr) => Array.isArray(arr) ? arr : [];
    const safeLength = (arr) => Array.isArray(arr) ? arr.length : 0;
    const safeMap = (arr, fn) => Array.isArray(arr) ? arr.map(fn) : [];
    const safeFilter = (arr, fn) => Array.isArray(arr) ? arr.filter(fn) : [];

    // Get backend URL based on environment
    const getBackendUrl = () => {
        if (typeof window !== 'undefined') {
            // Client-side: use production domain
            return 'https://unibus.online/api';
        }
        // Server-side: use localhost
        return 'http://localhost:3001/api';
    };

    // Fetch students data
    const fetchStudents = async () => {
        if (!isAuthenticated) {
            console.log('Not authenticated, skipping fetch');
            return;
        }

        try {
            setLoading(true);
            setError(null);
            
            // Use production domain instead of localhost
            const backendUrl = getBackendUrl();
            const response = await fetch(`${backendUrl}/admin/students`, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (response.ok) {
                const data = await response.json();
                if (data && data.success && data.students) {
                    const studentsData = safeArray(data.students);
                    setStudents(studentsData);
                    
                    // Calculate stats safely
                    const totalStudents = safeLength(studentsData);
                    const activeStudents = safeLength(safeFilter(studentsData, student => 
                        student && student.status !== 'inactive'
                    ));
                    const totalAttendance = studentsData.reduce((sum, student) => {
                        return sum + (student && student.attendanceCount ? student.attendanceCount : 0);
                    }, 0);
                    
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
        if (isAuthenticated) {
            fetchStudents();
            const interval = setInterval(fetchStudents, 30000);
            return () => clearInterval(interval);
        }
    }, [isAuthenticated]);

    // Filter students based on search term
    const filteredStudents = safeFilter(students, student => {
        if (!searchTerm || !student) return true;
        const searchLower = searchTerm.toLowerCase();
        return (
            (student.fullName && student.fullName.toLowerCase().includes(searchLower)) ||
            (student.email && student.email.toLowerCase().includes(searchLower)) ||
            (student.studentId && student.studentId.toLowerCase().includes(searchLower)) ||
            (student.college && student.college.toLowerCase().includes(searchLower))
        );
    });

    // Show loading while checking auth
    if (authLoading) {
        return (
            <div className="admin-page">
                <div className="page-header">
                    <h1>Student Search</h1>
                </div>
                <div className="loading-container">
                    <div className="loading-spinner"></div>
                    <p>Checking authentication...</p>
                </div>
            </div>
        );
    }

    // Show not authenticated message
    if (!isAuthenticated) {
        return (
            <div className="admin-page">
                <div className="page-header">
                    <h1>Student Search</h1>
                </div>
                <div className="error-message">
                    <p>⚠️ You are not authenticated. Please log in as an admin.</p>
                    <button onClick={() => router.push('/auth')}>Go to Login</button>
                </div>
            </div>
        );
    }

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
                        {safeLength(filteredStudents) === 0 ? (
                            <tr>
                                <td colSpan="7" className="no-data">
                                    {searchTerm ? 'No students found matching your search.' : 'No students found.'}
                                </td>
                            </tr>
                        ) : (
                            safeMap(filteredStudents, (student) => (
                                <tr key={student._id || Math.random()}>
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

# Also fix the admin layout to handle authentication better
echo "🔧 Fixing admin layout authentication..."

cat > app/admin/layout.js << 'EOF'
'use client';

import { useState, useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';

export default function AdminLayout({ children }) {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const router = useRouter();
    const pathname = usePathname();

    useEffect(() => {
        const checkAuth = () => {
            try {
                const userData = localStorage.getItem('user');
                const adminToken = localStorage.getItem('adminToken');
                const userRole = localStorage.getItem('userRole');
                
                console.log('Admin layout auth check:', { 
                    user: !!userData, 
                    adminToken: !!adminToken, 
                    userRole,
                    pathname 
                });
                
                if (userData && adminToken && (userRole === 'admin' || userRole === 'supervisor')) {
                    setUser(JSON.parse(userData));
                    setLoading(false);
                } else {
                    console.log('No valid admin auth, redirecting to login');
                    router.push('/auth');
                }
            } catch (error) {
                console.error('Admin layout auth error:', error);
                router.push('/auth');
            }
        };

        checkAuth();
        
        // Listen for storage changes
        const handleStorageChange = () => {
            checkAuth();
        };
        
        window.addEventListener('storage', handleStorageChange);
        
        return () => {
            window.removeEventListener('storage', handleStorageChange);
        };
    }, [router, pathname]);

    const handleLogout = () => {
        localStorage.removeItem('user');
        localStorage.removeItem('adminToken');
        localStorage.removeItem('userRole');
        router.push('/auth');
    };

    if (loading) {
        return (
            <div style={{ 
                display: 'flex', 
                justifyContent: 'center', 
                alignItems: 'center', 
                height: '100vh',
                fontSize: '18px'
            }}>
                Checking authentication...
            </div>
        );
    }

    if (!user) {
        return (
            <div style={{ 
                display: 'flex', 
                justifyContent: 'center', 
                alignItems: 'center', 
                height: '100vh',
                fontSize: '18px'
            }}>
                Not authenticated. Redirecting to login...
            </div>
        );
    }

    return (
        <div className="admin-layout">
            <div className="admin-sidebar">
                <div className="sidebar-header">
                    <h2>Admin Panel</h2>
                    <p>Welcome, {user.fullName || user.email}</p>
                </div>
                
                <nav className="sidebar-nav">
                    <Link href="/admin/dashboard" className="nav-link">
                        📊 Dashboard
                    </Link>
                    <Link href="/admin/users" className="nav-link">
                        🔍 Students Search
                    </Link>
                    <Link href="/admin/attendance" className="nav-link">
                        📋 Attendance
                    </Link>
                    <Link href="/admin/supervisor-dashboard" className="nav-link">
                        👨‍💼 Supervisor Dashboard
                    </Link>
                    <Link href="/admin/subscriptions" className="nav-link">
                        💳 Subscriptions
                    </Link>
                    <Link href="/admin/reports" className="nav-link">
                        📈 Reports
                    </Link>
                    <Link href="/admin/transportation" className="nav-link">
                        🚌 Transportation
                    </Link>
                    <Link href="/admin/support" className="nav-link">
                        🎧 Support
                    </Link>
                </nav>
                
                <div className="sidebar-footer">
                    <button onClick={handleLogout} className="logout-btn">
                        🚪 Logout
                    </button>
                </div>
            </div>
            
            <main className="admin-main">
                {children}
            </main>
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

# Test frontend
echo "🏥 Testing frontend..."
curl -s http://localhost:3000 | head -20 || echo "Frontend not responding"

# Final status
echo "📊 Final PM2 status:"
pm2 status

echo ""
echo "✅ Admin auth redirect issue fix completed!"
echo "🌍 Test your project at: https://unibus.online/admin/users"
echo "📋 Student Search page should now work without redirecting to login"
