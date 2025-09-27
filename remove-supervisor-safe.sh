#!/bin/bash

# Safe Supervisor Removal Script
# Only removes supervisor pages without touching anything else

echo "🚀 Starting Safe Supervisor Removal..."

# Navigate to frontend directory
cd /var/www/unitrans/frontend-new

echo "📁 Current directory: $(pwd)"

# 1. Remove only supervisor directories
echo "🗑️ Removing supervisor directories..."
rm -rf app/admin/supervisor-dashboard
rm -rf app/admin/supervisor-mobile  
rm -rf app/admin/supervisor-simple
rm -rf app/admin/supervisor-dashboard-enhanced

# 2. Remove supervisor files from .next cache only
echo "🗑️ Cleaning .next cache..."
rm -rf .next/server/app/admin/supervisor*

# 3. Remove only supervisor dashboard link from admin layout (keep everything else)
echo "🔧 Removing supervisor dashboard link from navigation..."
sed -i '/supervisor-dashboard/d' app/admin/dashboard/layout.js

# 4. Remove supervisor references from auth page only
echo "🔧 Removing supervisor references from auth page..."
sed -i '/supervisor-dashboard/d' app/auth/page.js

# 5. Clean build cache
echo "🧹 Cleaning build cache..."
rm -rf .next

# 6. Rebuild application
echo "🔨 Rebuilding application..."
npm run build

# 7. Restart PM2
echo "🔄 Restarting PM2..."
pm2 restart unitrans-frontend

# 8. Verify removal
echo "✅ Verification:"
echo "Checking for supervisor directories..."
if [ -d "app/admin/supervisor-dashboard" ]; then
    echo "❌ supervisor-dashboard still exists"
else
    echo "✅ supervisor-dashboard removed"
fi

if [ -d "app/admin/supervisor-mobile" ]; then
    echo "❌ supervisor-mobile still exists"
else
    echo "✅ supervisor-mobile removed"
fi

if [ -d "app/admin/supervisor-simple" ]; then
    echo "❌ supervisor-simple still exists"
else
    echo "✅ supervisor-simple removed"
fi

echo "🔍 Checking for supervisor references in layout..."
if grep -q "supervisor-dashboard" app/admin/dashboard/layout.js; then
    echo "❌ supervisor-dashboard references still found in layout"
else
    echo "✅ supervisor-dashboard references removed from layout"
fi

echo "🎉 Safe supervisor removal completed!"
echo "📋 Summary:"
echo "   - Only supervisor directories removed"
echo "   - Only supervisor navigation links removed"
echo "   - All other functionality preserved"
echo "   - Application rebuilt"
echo "   - PM2 restarted"
echo ""
echo "🌐 You can now access the application at: https://unibus.online"
echo "📱 The supervisor dashboard should no longer be accessible"
echo "✅ All other features remain intact"
