#!/bin/bash

# Supervisor Removal Verification Script
# Verifies that ALL supervisor pages and functionality have been completely removed

echo "🔍 Starting Supervisor Removal Verification..."

# Navigate to frontend directory
cd /var/www/unitrans/frontend-new
echo "📁 Current directory: $(pwd)"

echo "🔍 Checking for supervisor directories..."
echo "=========================================="

# Check for supervisor directories
if [ -d "app/admin/supervisor-dashboard" ]; then
    echo "❌ FOUND: app/admin/supervisor-dashboard directory still exists!"
    ls -la app/admin/supervisor-dashboard
else
    echo "✅ OK: app/admin/supervisor-dashboard directory removed"
fi

if [ -d "app/admin/supervisor-mobile" ]; then
    echo "❌ FOUND: app/admin/supervisor-mobile directory still exists!"
    ls -la app/admin/supervisor-mobile
else
    echo "✅ OK: app/admin/supervisor-mobile directory removed"
fi

if [ -d "app/admin/supervisor-simple" ]; then
    echo "❌ FOUND: app/admin/supervisor-simple directory still exists!"
    ls -la app/admin/supervisor-simple
else
    echo "✅ OK: app/admin/supervisor-simple directory removed"
fi

if [ -d "app/admin/attendance/supervisor" ]; then
    echo "❌ FOUND: app/admin/attendance/supervisor directory still exists!"
    ls -la app/admin/attendance/supervisor
else
    echo "✅ OK: app/admin/attendance/supervisor directory removed"
fi

echo ""
echo "🔍 Checking for supervisor files..."
echo "=========================================="

# Check for supervisor files
SUPERVISOR_FILES=$(find . -name "*supervisor*" -type f 2>/dev/null)
if [ -n "$SUPERVISOR_FILES" ]; then
    echo "❌ FOUND supervisor files:"
    echo "$SUPERVISOR_FILES"
else
    echo "✅ OK: No supervisor files found"
fi

echo ""
echo "🔍 Checking for supervisor directories..."
echo "=========================================="

# Check for supervisor directories
SUPERVISOR_DIRS=$(find . -name "*supervisor*" -type d 2>/dev/null)
if [ -n "$SUPERVISOR_DIRS" ]; then
    echo "❌ FOUND supervisor directories:"
    echo "$SUPERVISOR_DIRS"
else
    echo "✅ OK: No supervisor directories found"
fi

echo ""
echo "🔍 Checking for supervisor API routes..."
echo "=========================================="

# Check for supervisor API routes
if [ -d "app/api/supervisor" ]; then
    echo "❌ FOUND: app/api/supervisor directory still exists!"
    ls -la app/api/supervisor
else
    echo "✅ OK: app/api/supervisor directory removed"
fi

if [ -d "app/api/shifts" ]; then
    echo "❌ FOUND: app/api/shifts directory still exists!"
    ls -la app/api/shifts
else
    echo "✅ OK: app/api/shifts directory removed"
fi

echo ""
echo "🔍 Checking for supervisor references in layout files..."
echo "=========================================="

# Check admin dashboard layout
if [ -f "app/admin/dashboard/layout.js" ]; then
    if grep -q "supervisor" app/admin/dashboard/layout.js; then
        echo "❌ FOUND: supervisor references in admin dashboard layout"
        grep -n "supervisor" app/admin/dashboard/layout.js
    else
        echo "✅ OK: No supervisor references in admin dashboard layout"
    fi
else
    echo "⚠️  WARNING: app/admin/dashboard/layout.js not found"
fi

# Check auth page
if [ -f "app/auth/page.js" ]; then
    if grep -q "supervisor" app/auth/page.js; then
        echo "❌ FOUND: supervisor references in auth page"
        grep -n "supervisor" app/auth/page.js
    else
        echo "✅ OK: No supervisor references in auth page"
    fi
else
    echo "⚠️  WARNING: app/auth/page.js not found"
fi

echo ""
echo "🔍 Checking for supervisor components..."
echo "=========================================="

# Check for supervisor components
if [ -d "components/supervisor" ]; then
    echo "❌ FOUND: components/supervisor directory still exists!"
    ls -la components/supervisor
else
    echo "✅ OK: components/supervisor directory removed"
fi

if [ -d "components/admin/Supervisor" ]; then
    echo "❌ FOUND: components/admin/Supervisor directory still exists!"
    ls -la components/admin/Supervisor
else
    echo "✅ OK: components/admin/Supervisor directory removed"
fi

echo ""
echo "🔍 Checking for supervisor in package.json..."
echo "=========================================="

if [ -f "package.json" ]; then
    if grep -q "supervisor" package.json; then
        echo "❌ FOUND: supervisor references in package.json"
        grep -n "supervisor" package.json
    else
        echo "✅ OK: No supervisor references in package.json"
    fi
else
    echo "⚠️  WARNING: package.json not found"
fi

echo ""
echo "🔍 Checking for supervisor in build artifacts..."
echo "=========================================="

# Check build artifacts
if [ -d ".next" ]; then
    if find .next -name "*supervisor*" 2>/dev/null | grep -q .; then
        echo "❌ FOUND: supervisor files in build artifacts"
        find .next -name "*supervisor*" 2>/dev/null
    else
        echo "✅ OK: No supervisor files in build artifacts"
    fi
else
    echo "⚠️  WARNING: .next directory not found"
fi

echo ""
echo "🔍 Final Summary..."
echo "=========================================="

# Count remaining supervisor files
REMAINING_FILES=$(find . -name "*supervisor*" 2>/dev/null | wc -l)
REMAINING_DIRS=$(find . -name "*supervisor*" -type d 2>/dev/null | wc -l)

echo "📊 Remaining supervisor files: $REMAINING_FILES"
echo "📊 Remaining supervisor directories: $REMAINING_DIRS"

if [ "$REMAINING_FILES" -eq 0 ] && [ "$REMAINING_DIRS" -eq 0 ]; then
    echo "✅ SUCCESS: All supervisor pages and functionality have been completely removed!"
    echo "🌐 Application is clean and ready at: https://unibus.online"
else
    echo "❌ WARNING: Some supervisor files/directories still exist!"
    echo "🔧 Consider running the removal script again"
fi

echo ""
echo "🔍 Checking PM2 status..."
echo "=========================================="
pm2 status

echo ""
echo "✅ Verification completed!"
