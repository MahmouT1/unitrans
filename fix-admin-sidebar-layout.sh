#!/bin/bash

echo "🔧 Fix Admin Sidebar Layout"
echo "=========================="

cd /home/unitrans

# Stop frontend
echo "⏹️ Stopping frontend..."
pm2 stop unitrans-frontend

# Navigate to frontend directory
cd frontend-new

# Fix the admin layout to hide the outer sidebar and keep the inner one
echo "🔧 Fixing admin layout..."

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
            {/* Hide the outer sidebar completely */}
            <div className="admin-sidebar" style={{ display: 'none' }}>
                {/* This sidebar is now hidden */}
            </div>
            
            <main className="admin-main" style={{ marginLeft: '0', width: '100%' }}>
                {children}
            </main>
        </div>
    );
}
EOF

# Also update the admin layout CSS to ensure proper styling
echo "🔧 Updating admin layout CSS..."

cat > app/admin/admin-layout.css << 'EOF'
/* Admin Layout Styles */
.admin-layout {
    display: flex;
    min-height: 100vh;
    background-color: #f5f5f5;
}

/* Hide the outer sidebar completely */
.admin-sidebar {
    display: none !important;
}

/* Main content area */
.admin-main {
    flex: 1;
    margin-left: 0 !important;
    width: 100% !important;
    padding: 0;
    background-color: #f5f5f5;
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
    .admin-main {
        margin-left: 0 !important;
        width: 100% !important;
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
echo "✅ Admin sidebar layout fix completed!"
echo "🌍 Test your project at: https://unibus.online/admin/users"
echo "📋 Outer sidebar is now hidden, inner navigation remains functional"
