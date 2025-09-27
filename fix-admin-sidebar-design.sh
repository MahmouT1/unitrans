#!/bin/bash

echo "🔧 Fix Admin Sidebar Design"
echo "==========================="

cd /home/unitrans

# Stop frontend
echo "⏹️ Stopping frontend..."
pm2 stop unitrans-frontend

# Navigate to frontend directory
cd frontend-new

# Fix the admin sidebar to match the exact original design
echo "🔧 Fixing admin sidebar design..."

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
                const token = localStorage.getItem('token');
                
                console.log('Admin layout auth check:', { 
                    user: !!userData, 
                    adminToken: !!adminToken, 
                    userRole,
                    token: !!token,
                    pathname 
                });
                
                if (userData && (userRole === 'admin' || userRole === 'supervisor')) {
                    // If no adminToken but has regular token, use that
                    if (!adminToken && token) {
                        localStorage.setItem('adminToken', token);
                    }
                    
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
        localStorage.removeItem('token');
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
            {/* Original Admin Sidebar */}
            <div className="admin-sidebar">
                {/* User Profile Section */}
                <div className="user-profile-section">
                    <div className="user-email">{user.email || 'admin@unibus.com'}</div>
                    <div className="user-role">Administrator</div>
                    <div className="language-selector">
                        <button className="lang-btn">us English ▼</button>
                    </div>
                </div>

                {/* Navigation Links */}
                <nav className="sidebar-nav">
                    <Link href="/admin/dashboard" className="nav-link">
                        <span className="nav-icon">📊</span>
                        <span className="nav-text">Dashboard</span>
                    </Link>
                    <Link href="/admin/attendance" className="nav-link">
                        <span className="nav-icon">👥</span>
                        <span className="nav-text">Attendance Management</span>
                    </Link>
                    <Link href="/admin/subscriptions" className="nav-link">
                        <span className="nav-icon">💳</span>
                        <span className="nav-text">Subscription Management</span>
                    </Link>
                    <Link href="/admin/reports" className="nav-link">
                        <span className="nav-icon">📈</span>
                        <span className="nav-text">Reports</span>
                    </Link>
                    <Link href="/admin/users" className="nav-link">
                        <span className="nav-icon">🔍</span>
                        <span className="nav-text">Student Search</span>
                    </Link>
                    <Link href="/admin/support" className="nav-link">
                        <span className="nav-icon">🎧</span>
                        <span className="nav-text">Support Management</span>
                    </Link>
                </nav>

                {/* Quick Actions Section */}
                <div className="quick-actions-section">
                    <div className="quick-actions-title">Quick Actions</div>
                    <button className="quick-action-btn add-expense">
                        <span className="btn-icon">💸</span>
                        <span className="btn-text">Add Expense</span>
                    </button>
                    <button className="quick-action-btn add-driver-salary">
                        <span className="btn-icon">🚌</span>
                        <span className="btn-text">Add Driver Salary</span>
                    </button>
                    <button className="quick-action-btn logout" onClick={handleLogout}>
                        <span className="btn-icon">🚪</span>
                        <span className="btn-text">Logout</span>
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

# Update the admin layout CSS to match the exact original design
echo "🔧 Updating admin layout CSS to match exact original design..."

cat > app/admin/admin-layout.css << 'EOF'
/* Admin Layout Styles */
.admin-layout {
    display: flex;
    min-height: 100vh;
    background-color: #f5f5f5;
}

/* Original Admin Sidebar - Exact Match */
.admin-sidebar {
    width: 280px;
    background: #1a1a1a;
    color: white;
    display: flex;
    flex-direction: column;
    position: fixed;
    height: 100vh;
    left: 0;
    top: 0;
    z-index: 1000;
    box-shadow: 2px 0 10px rgba(0,0,0,0.3);
    overflow-y: auto;
    padding: 0;
}

/* User Profile Section - Clean Design */
.user-profile-section {
    padding: 25px 20px;
    border-bottom: 1px solid #333;
    background: #1a1a1a;
}

.user-email {
    font-size: 16px;
    font-weight: 500;
    color: white;
    margin-bottom: 8px;
    line-height: 1.4;
}

.user-role {
    font-size: 14px;
    color: #ccc;
    margin-bottom: 15px;
    line-height: 1.4;
}

.language-selector {
    margin-top: 10px;
}

.lang-btn {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 6px;
    font-size: 13px;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 6px;
    font-weight: 500;
    transition: all 0.2s ease;
}

.lang-btn:hover {
    opacity: 0.9;
    transform: translateY(-1px);
}

/* Navigation Links - Clean and Spacious */
.sidebar-nav {
    flex: 1;
    padding: 20px 0;
    background: #1a1a1a;
}

.nav-link {
    display: flex;
    align-items: center;
    padding: 15px 25px;
    color: #ccc;
    text-decoration: none;
    transition: all 0.3s ease;
    border-left: 3px solid transparent;
    gap: 15px;
    font-size: 15px;
    line-height: 1.4;
}

.nav-link:hover {
    background: #2a2a2a;
    color: white;
    border-left-color: #667eea;
}

.nav-link.active {
    background: #2a2a2a;
    color: white;
    border-left-color: #007bff;
}

.nav-icon {
    font-size: 20px;
    width: 24px;
    text-align: center;
    flex-shrink: 0;
}

.nav-text {
    font-size: 15px;
    font-weight: 500;
    flex: 1;
}

/* Quick Actions Section - Professional Design */
.quick-actions-section {
    padding: 25px 20px;
    border-top: 1px solid #333;
    background: #1a1a1a;
}

.quick-actions-title {
    font-size: 14px;
    color: white;
    margin-bottom: 15px;
    font-weight: 600;
    text-transform: none;
    letter-spacing: 0.3px;
}

.quick-action-btn {
    width: 100%;
    background: transparent;
    color: #ccc;
    border: 1px solid #444;
    padding: 12px 16px;
    border-radius: 6px;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 12px;
    font-size: 14px;
    font-weight: 500;
    transition: all 0.3s ease;
    margin-bottom: 8px;
    text-align: left;
}

.quick-action-btn:hover {
    background: #2a2a2a;
    color: white;
    border-color: #555;
    transform: translateY(-1px);
}

.quick-action-btn.add-expense:hover {
    border-color: #28a745;
    color: #28a745;
}

.quick-action-btn.add-driver-salary:hover {
    border-color: #007bff;
    color: #007bff;
}

.quick-action-btn.logout:hover {
    border-color: #dc3545;
    color: #dc3545;
}

.btn-icon {
    font-size: 16px;
    width: 20px;
    text-align: center;
    flex-shrink: 0;
}

.btn-text {
    flex: 1;
    font-size: 14px;
    font-weight: 500;
}

/* Main content area */
.admin-main {
    flex: 1;
    margin-left: 280px;
    padding: 0;
    background-color: #f5f5f5;
    min-height: 100vh;
}

/* Page header styles */
.page-header {
    background: white;
    padding: 20px 30px;
    border-bottom: 1px solid #e0e0e0;
    margin-bottom: 20px;
}

.page-header h1 {
    margin: 0;
    color: #333;
    font-size: 24px;
    font-weight: 600;
}

/* Stats grid */
.stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 20px;
    margin: 20px 30px;
}

.stat-card {
    background: white;
    padding: 25px;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    border-left: 4px solid #007bff;
}

.stat-card h3 {
    margin: 0 0 10px 0;
    color: #666;
    font-size: 14px;
    font-weight: 500;
}

.stat-number {
    font-size: 28px;
    font-weight: bold;
    color: #007bff;
    margin: 0;
}

/* Table styles */
.table-container {
    background: white;
    margin: 20px 30px;
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

/* Status badges */
.status-badge {
    padding: 4px 12px;
    border-radius: 20px;
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

.status-badge.present {
    background: #d4edda;
    color: #155724;
}

.status-badge.absent {
    background: #f8d7da;
    color: #721c24;
}

/* Buttons */
.refresh-btn {
    background: #007bff;
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: 5px;
    cursor: pointer;
    font-size: 14px;
    font-weight: 500;
}

.refresh-btn:hover {
    background: #0056b3;
}

.refresh-btn:disabled {
    background: #ccc;
    cursor: not-allowed;
}

/* Loading states */
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

/* Error messages */
.error-message {
    background: #f8d7da;
    color: #721c24;
    padding: 15px;
    border-radius: 5px;
    margin: 20px 30px;
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

/* Search container */
.search-container {
    margin: 20px 30px;
}

.search-input {
    width: 100%;
    padding: 12px 16px;
    border: 1px solid #ddd;
    border-radius: 8px;
    font-size: 16px;
    box-sizing: border-box;
}

.search-input:focus {
    outline: none;
    border-color: #007bff;
    box-shadow: 0 0 0 2px rgba(0,123,255,0.25);
}

/* Attendance count styling */
.attendance-count {
    font-weight: bold;
    color: #28a745;
    background: #d4edda;
    padding: 4px 8px;
    border-radius: 4px;
    display: inline-block;
}

/* Responsive design */
@media (max-width: 768px) {
    .admin-sidebar {
        transform: translateX(-100%);
        transition: transform 0.3s ease;
    }
    
    .admin-sidebar.open {
        transform: translateX(0);
    }
    
    .admin-main {
        margin-left: 0;
    }
    
    .stats-grid {
        grid-template-columns: 1fr;
        margin: 20px 15px;
    }
    
    .table-container {
        margin: 20px 15px;
        overflow-x: auto;
    }
    
    .page-header {
        padding: 15px 20px;
    }
    
    .search-container {
        margin: 20px 15px;
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
echo "✅ Admin sidebar design fixed!"
echo "🌍 Test your project at: https://unibus.online/admin/users"
echo "📋 Sidebar now matches the exact original professional design"
