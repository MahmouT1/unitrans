#!/bin/bash

# Fix Build Errors Script
# This script fixes common build errors in production

set -e

echo "🔧 Fixing Build Errors..."

# Navigate to project directory
cd /home/unitrans

# Remove problematic files
echo "🗑️ Removing problematic files..."
rm -f frontend-new/app/admin/supervisor-dashboard-enhanced/page.js
rm -f frontend-new/components/WorkingQRScannerFixed.js
rm -f frontend-new/lib/Student.js
rm -f frontend-new/lib/User.js
rm -f frontend-new/lib/StudentSimple.js
rm -f frontend-new/lib/Subscription.js
rm -f frontend-new/lib/SubscriptionSimple.js
rm -f frontend-new/lib/SupportTicket.js
rm -f frontend-new/lib/Transportation.js
rm -f frontend-new/lib/UserSimple.js
rm -f frontend-new/lib/Shift.js

# Remove problematic API routes
echo "🗑️ Removing problematic API routes..."
rm -f frontend-new/app/api/attendance/register-simple/route.js
rm -f frontend-new/app/api/attendance/scan-qr/route.js
rm -f frontend-new/app/api/students/profile/route.js
rm -f frontend-new/app/api/support/tickets/route.js
rm -f frontend-new/app/api/test-db/route.js
rm -f frontend-new/app/api/test-student-simple/route.js
rm -f frontend-new/app/api/test-student/route.js
rm -f frontend-new/app/api/test-user-simple/route.js
rm -f frontend-new/app/api/test-user/route.js

# Install missing dependencies
echo "📦 Installing missing dependencies..."
cd frontend-new
npm install axios qrcode jsqr zxing

# Clean build cache
echo "🧹 Cleaning build cache..."
rm -rf .next
rm -rf node_modules/.cache

# Try building again
echo "🔨 Building frontend..."
npm run build

echo "✅ Build errors fixed!"
echo "🚀 Restarting services..."
cd /home/unitrans

# Restart PM2 processes
pm2 restart unitrans-frontend
pm2 restart unitrans-backend

echo "✅ Services restarted successfully!"
echo "🌍 Test your site at: https://unibus.online"
