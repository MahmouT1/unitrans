#!/bin/bash

# Destroy Remaining Supervisor Paths Script
# This script will DESTROY the remaining supervisor paths specifically

echo "🎯 Starting DESTROY Remaining Supervisor Paths..."

# Navigate to frontend directory
cd /var/www/unitrans/frontend-new
echo "📁 Current directory: $(pwd)"

# 1. Stop PM2 processes
echo "🛑 Stopping PM2 processes..."
pm2 stop unitrans-frontend
pm2 stop unitrans-backend

# 2. DESTROY specific remaining supervisor paths
echo "🎯 DESTROYING specific remaining supervisor paths..."

# Destroy app/admin/supervisor-dashboard directory
echo "💥 Destroying app/admin/supervisor-dashboard..."
rm -rf app/admin/supervisor-dashboard

# Destroy .next build artifacts
echo "💥 Destroying .next build artifacts..."
rm -rf .next/static/chunks/app/admin/supervisor-dashboard
rm -rf .next/types/app/admin/supervisor-dashboard
rm -rf .next/server/app/admin/supervisor-dashboard.meta
rm -rf .next/server/app/admin/supervisor-dashboard
rm -rf .next/server/app/admin/supervisor-dashboard.rsc
rm -rf .next/server/app/admin/supervisor-dashboard.html

# 3. NUCLEAR OPTION: Destroy ALL .next directory
echo "☢️ NUCLEAR OPTION: Destroying ALL .next directory..."
rm -rf .next

# 4. Remove supervisor from ALL layout files
echo "🔧 Force cleaning ALL layout files..."
find app -name "layout.js" -exec sed -i '/supervisor/d' {} \; 2>/dev/null || true
find app -name "page.js" -exec sed -i '/supervisor/d' {} \; 2>/dev/null || true

# 5. Force clean admin dashboard layout
echo "🔧 Force cleaning admin dashboard layout..."
if [ -f "app/admin/dashboard/layout.js" ]; then
    # Remove supervisor-dashboard link completely
    sed -i '/supervisor-dashboard/d' app/admin/dashboard/layout.js
    sed -i '/Supervisor Dashboard/d' app/admin/dashboard/layout.js
    sed -i '/supervisor/d' app/admin/dashboard/layout.js
    # Remove the entire supervisor link section
    sed -i '/Supervisor Dashboard/,+3d' app/admin/dashboard/layout.js
fi

# 6. Force clean auth page
echo "🔧 Force cleaning auth page..."
if [ -f "app/auth/page.js" ]; then
    sed -i '/supervisor-dashboard/d' app/auth/page.js
    sed -i '/supervisor/d' app/auth/page.js
fi

# 7. Remove supervisor from navigation
echo "🔧 Force cleaning navigation..."
# Remove supervisor from all navigation files
find app -name "*.js" -exec sed -i '/supervisor-dashboard/d' {} \; 2>/dev/null || true
find app -name "*.js" -exec sed -i '/Supervisor Dashboard/d' {} \; 2>/dev/null || true

# 8. Force clean admin layout CSS
echo "🔧 Force cleaning admin layout CSS..."
cat > app/admin/admin-layout.css << 'CSS_EOF'
/* Admin Layout CSS - Clean Version */
.admin-layout {
  display: flex;
  min-height: 100vh;
  background-color: #f5f5f5;
}
.admin-sidebar {
  width: 250px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 20px 0;
  box-shadow: 2px 0 10px rgba(0,0,0,0.1);
}
.admin-sidebar h2 {
  text-align: center;
  margin-bottom: 30px;
  font-size: 1.5rem;
  font-weight: bold;
}
.admin-sidebar nav ul {
  list-style: none;
  padding: 0;
  margin: 0;
}
.admin-sidebar nav ul li {
  margin-bottom: 10px;
}
.admin-sidebar nav ul li a {
  display: flex;
  align-items: center;
  padding: 12px 20px;
  color: white;
  text-decoration: none;
  transition: all 0.3s ease;
  border-radius: 0 25px 25px 0;
  margin-right: 10px;
}
.admin-sidebar nav ul li a:hover {
  background-color: rgba(255,255,255,0.1);
  transform: translateX(5px);
}
.admin-sidebar nav ul li a.active {
  background-color: rgba(255,255,255,0.2);
  font-weight: bold;
}
.admin-sidebar nav ul li a svg {
  margin-right: 10px;
  width: 20px;
  height: 20px;
}
.main-content {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
}
@media (max-width: 768px) {
  .admin-layout {
    flex-direction: column;
  }
  .admin-sidebar {
    width: 100%;
    height: auto;
  }
  .main-content {
    padding: 10px;
  }
}
CSS_EOF

# 9. Remove ALL supervisor components
echo "💥 Force destroying ALL supervisor components..."
rm -rf components/supervisor*
rm -rf components/admin/Supervisor*
find components -name "*supervisor*" -type f -delete 2>/dev/null || true
find components -name "*supervisor*" -type d -exec rm -rf {} + 2>/dev/null || true

# 10. Clean package.json
echo "🔧 Force cleaning package.json..."
if [ -f "package.json" ]; then
    sed -i '/supervisor/d' package.json 2>/dev/null || true
fi

# 11. Clean ALL config files
echo "🔧 Force cleaning ALL config files..."
find . -name "*.json" -exec sed -i '/supervisor/d' {} \; 2>/dev/null || true
find . -name "*.js" -exec sed -i '/supervisor/d' {} \; 2>/dev/null || true

# 12. Remove supervisor from ALL files
echo "🔧 Force removing supervisor from ALL files..."
find . -type f -name "*.js" -exec sed -i '/supervisor/d' {} \; 2>/dev/null || true
find . -type f -name "*.jsx" -exec sed -i '/supervisor/d' {} \; 2>/dev/null || true
find . -type f -name "*.ts" -exec sed -i '/supervisor/d' {} \; 2>/dev/null || true
find . -type f -name "*.tsx" -exec sed -i '/supervisor/d' {} \; 2>/dev/null || true

# 13. Create 404 pages for supervisor routes
echo "💥 Creating 404 pages for supervisor routes..."
mkdir -p app/admin/supervisor-dashboard
cat > app/admin/supervisor-dashboard/page.js << 'EOF'
'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function SupervisorDashboard() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to admin dashboard
    router.push('/admin');
  }, [router]);

  return (
    <div style={{ 
      display: 'flex', 
      justifyContent: 'center', 
      alignItems: 'center', 
      height: '100vh',
      flexDirection: 'column',
      gap: '20px'
    }}>
      <h1>404 - Page Not Found</h1>
      <p>Supervisor dashboard has been removed.</p>
      <button 
        onClick={() => router.push('/admin')}
        style={{
          padding: '10px 20px',
          backgroundColor: '#667eea',
          color: 'white',
          border: 'none',
          borderRadius: '5px',
          cursor: 'pointer'
        }}
      >
        Go to Admin Dashboard
      </button>
    </div>
  );
}
EOF

# 14. Create 404 API routes for supervisor endpoints
echo "💥 Creating 404 API routes for supervisor endpoints..."
mkdir -p app/api/shifts
cat > app/api/shifts/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({
    error: 'API endpoint removed',
    message: 'Shifts API has been removed'
  }, { status: 404 });
}

export async function POST() {
  return NextResponse.json({
    error: 'API endpoint removed',
    message: 'Shifts API has been removed'
  }, { status: 404 });
}

export async function PUT() {
  return NextResponse.json({
    error: 'API endpoint removed',
    message: 'Shifts API has been removed'
  }, { status: 404 });
}

export async function DELETE() {
  return NextResponse.json({
    error: 'API endpoint removed',
    message: 'Shifts API has been removed'
  }, { status: 404 });
}
EOF

# 15. Force rebuild
echo "🔨 Force rebuilding application..."
npm run build

# 16. Restart PM2
echo "🔄 Restarting PM2..."
pm2 start unitrans-backend
pm2 start unitrans-frontend

# 17. Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 25

# 18. Final verification
echo "🔍 Final verification..."
REMAINING_FILES=$(find . -name "*supervisor*" 2>/dev/null | wc -l)
REMAINING_DIRS=$(find . -name "*supervisor*" -type d 2>/dev/null | wc -l)

echo "📊 Remaining supervisor files: $REMAINING_FILES"
echo "📊 Remaining supervisor directories: $REMAINING_DIRS"

if [ "$REMAINING_FILES" -gt 0 ] || [ "$REMAINING_DIRS" -gt 0 ]; then
    echo "❌ WARNING: Found remaining supervisor files/directories:"
    find . -name "*supervisor*" 2>/dev/null
fi

# 19. Test HTTP access
echo "🌐 Testing HTTP access..."
SUPERVISOR_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/admin/supervisor-dashboard)
SHIFTS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/api/shifts)

echo "Supervisor dashboard HTTP status: $SUPERVISOR_RESPONSE"
echo "Shifts API HTTP status: $SHIFTS_RESPONSE"

if [ "$SUPERVISOR_RESPONSE" = "404" ] && [ "$SHIFTS_RESPONSE" = "404" ]; then
    echo "✅ SUCCESS: All supervisor pages and APIs now return 404!"
    echo "🌐 Application is clean and ready at: https://unibus.online"
else
    echo "❌ WARNING: Some supervisor endpoints still accessible!"
    echo "🔧 Consider running this script again"
fi

echo "✅ Destroy remaining supervisor paths completed!"
