#!/bin/bash

# Manual Supervisor Destroy Script
# This script will MANUALLY DESTROY ALL supervisor files and paths

echo "💀 Starting MANUAL Supervisor Destroy..."

# Navigate to frontend directory
cd /var/www/unitrans/frontend-new
echo "📁 Current directory: $(pwd)"

# 1. Stop PM2 processes
echo "🛑 Stopping PM2 processes..."
pm2 stop all

# 2. MANUAL DESTRUCTION: Destroy specific files and directories
echo "💀 MANUAL DESTRUCTION: Destroying specific files and directories..."

# Remove supervisor dashboard directory
echo "🗑️ Removing supervisor dashboard directory..."
rm -rf app/admin/supervisor-dashboard

# Remove .next supervisor files
echo "🗑️ Removing .next supervisor files..."
rm -rf .next/static/chunks/app/admin/supervisor-dashboard
rm -rf .next/types/app/admin/supervisor-dashboard
rm -rf .next/server/app/admin/supervisor-dashboard.meta
rm -rf .next/server/app/admin/supervisor-dashboard
rm -rf .next/server/app/admin/supervisor-dashboard.rsc
rm -rf .next/server/app/admin/supervisor-dashboard.html

# Remove shifts API directory
echo "🗑️ Removing shifts API directory..."
rm -rf app/api/shifts

# Remove .next shifts files
echo "🗑️ Removing .next shifts files..."
rm -rf .next/types/app/api/shifts
rm -rf .next/server/app/api/shifts

# 3. Force clean ALL files
echo "🔧 Force cleaning ALL files..."
find . -name "*.js" -exec sed -i '/supervisor/d' {} \; 2>/dev/null || true
find . -name "*.jsx" -exec sed -i '/supervisor/d' {} \; 2>/dev/null || true

# 4. Create 404 pages
echo "💀 Creating 404 pages..."
mkdir -p app/admin/supervisor-dashboard
cat > app/admin/supervisor-dashboard/page.js << 'EOF'
'use client';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
export default function SupervisorDashboard() {
  const router = useRouter();
  useEffect(() => { router.push('/admin'); }, [router]);
  return <div>404 - Page Not Found</div>;
}
EOF

# 5. Create 404 API routes
echo "💀 Creating 404 API routes..."
mkdir -p app/api/shifts
cat > app/api/shifts/route.js << 'EOF'
import { NextResponse } from 'next/server';
export async function GET() { return NextResponse.json({error: 'API removed'}, {status: 404}); }
export async function POST() { return NextResponse.json({error: 'API removed'}, {status: 404}); }
EOF

# 6. Force rebuild
echo "🔨 Force rebuilding application..."
npm run build

# 7. Restart PM2
echo "🔄 Restarting PM2..."
pm2 start unitrans-backend
pm2 start unitrans-frontend

# 8. Wait for services
echo "⏳ Waiting for services..."
sleep 30

# 9. Final verification
echo "🔍 Final verification..."
REMAINING_FILES=$(find . -name "*supervisor*" 2>/dev/null | wc -l)
echo "📊 Remaining supervisor files: $REMAINING_FILES"

# 10. Test HTTP access
echo "🌐 Testing HTTP access..."
SUPERVISOR_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/admin/supervisor-dashboard)
SHIFTS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/api/shifts)

echo "Supervisor dashboard HTTP status: $SUPERVISOR_RESPONSE"
echo "Shifts API HTTP status: $SHIFTS_RESPONSE"

if [ "$SUPERVISOR_RESPONSE" = "404" ] && [ "$SHIFTS_RESPONSE" = "404" ]; then
    echo "✅ SUCCESS: All supervisor pages now return 404!"
else
    echo "❌ WARNING: Some supervisor endpoints still accessible!"
fi

echo "✅ Manual supervisor destroy completed!"
