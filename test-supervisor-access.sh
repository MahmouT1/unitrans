#!/bin/bash

# Test Supervisor Access Script
# Tests if supervisor pages are accessible and working

echo "🔍 Testing Supervisor Access..."

# Navigate to frontend directory
cd /var/www/unitrans/frontend-new
echo "📁 Current directory: $(pwd)"

echo "🔍 Testing supervisor page access..."

# Test 1: Check if supervisor dashboard page exists
echo "=========================================="
echo "Test 1: Checking supervisor dashboard page..."
if [ -f "app/admin/supervisor-dashboard/page.js" ]; then
    echo "❌ FOUND: supervisor-dashboard/page.js still exists!"
    ls -la app/admin/supervisor-dashboard/
else
    echo "✅ OK: supervisor-dashboard/page.js removed"
fi

# Test 2: Check if supervisor dashboard directory exists
echo "=========================================="
echo "Test 2: Checking supervisor dashboard directory..."
if [ -d "app/admin/supervisor-dashboard" ]; then
    echo "❌ FOUND: supervisor-dashboard directory still exists!"
    ls -la app/admin/supervisor-dashboard/
else
    echo "✅ OK: supervisor-dashboard directory removed"
fi

# Test 3: Check if supervisor API routes exist
echo "=========================================="
echo "Test 3: Checking supervisor API routes..."
if [ -d "app/api/supervisor" ]; then
    echo "❌ FOUND: supervisor API directory still exists!"
    ls -la app/api/supervisor/
else
    echo "✅ OK: supervisor API directory removed"
fi

if [ -d "app/api/shifts" ]; then
    echo "❌ FOUND: shifts API directory still exists!"
    ls -la app/api/shifts/
else
    echo "✅ OK: shifts API directory removed"
fi

# Test 4: Check supervisor references in navigation
echo "=========================================="
echo "Test 4: Checking supervisor references in navigation..."
if [ -f "app/admin/dashboard/layout.js" ]; then
    if grep -q "supervisor-dashboard" app/admin/dashboard/layout.js; then
        echo "❌ FOUND: supervisor-dashboard reference in admin layout!"
        grep -n "supervisor-dashboard" app/admin/dashboard/layout.js
    else
        echo "✅ OK: No supervisor-dashboard reference in admin layout"
    fi
else
    echo "⚠️  WARNING: admin layout file not found"
fi

# Test 5: Check auth page for supervisor redirects
echo "=========================================="
echo "Test 5: Checking supervisor redirects in auth page..."
if [ -f "app/auth/page.js" ]; then
    if grep -q "supervisor" app/auth/page.js; then
        echo "❌ FOUND: supervisor reference in auth page!"
        grep -n "supervisor" app/auth/page.js
    else
        echo "✅ OK: No supervisor reference in auth page"
    fi
else
    echo "⚠️  WARNING: auth page file not found"
fi

# Test 6: Test HTTP access to supervisor pages
echo "=========================================="
echo "Test 6: Testing HTTP access to supervisor pages..."

# Test supervisor dashboard access
echo "Testing supervisor dashboard access..."
SUPERVISOR_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/admin/supervisor-dashboard)
echo "Supervisor dashboard HTTP status: $SUPERVISOR_RESPONSE"

if [ "$SUPERVISOR_RESPONSE" = "404" ]; then
    echo "✅ OK: Supervisor dashboard returns 404 (not found)"
elif [ "$SUPERVISOR_RESPONSE" = "200" ]; then
    echo "❌ WARNING: Supervisor dashboard returns 200 (still accessible!)"
else
    echo "⚠️  INFO: Supervisor dashboard returns $SUPERVISOR_RESPONSE"
fi

# Test shifts API access
echo "Testing shifts API access..."
SHIFTS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/api/shifts)
echo "Shifts API HTTP status: $SHIFTS_RESPONSE"

if [ "$SHIFTS_RESPONSE" = "404" ]; then
    echo "✅ OK: Shifts API returns 404 (not found)"
elif [ "$SHIFTS_RESPONSE" = "200" ]; then
    echo "❌ WARNING: Shifts API returns 200 (still accessible!)"
else
    echo "⚠️  INFO: Shifts API returns $SHIFTS_RESPONSE"
fi

# Test 7: Check for any remaining supervisor files
echo "=========================================="
echo "Test 7: Final check for remaining supervisor files..."
REMAINING_FILES=$(find . -name "*supervisor*" 2>/dev/null | wc -l)
REMAINING_DIRS=$(find . -name "*supervisor*" -type d 2>/dev/null | wc -l)

echo "📊 Remaining supervisor files: $REMAINING_FILES"
echo "📊 Remaining supervisor directories: $REMAINING_DIRS"

if [ "$REMAINING_FILES" -eq 0 ] && [ "$REMAINING_DIRS" -eq 0 ]; then
    echo "✅ SUCCESS: No supervisor files or directories found!"
else
    echo "❌ WARNING: Found $REMAINING_FILES files and $REMAINING_DIRS directories"
    echo "Remaining files:"
    find . -name "*supervisor*" 2>/dev/null
fi

# Test 8: Check PM2 status
echo "=========================================="
echo "Test 8: Checking PM2 status..."
pm2 status

echo ""
echo "✅ Supervisor access testing completed!"
echo "🌐 Application URL: https://unibus.online"
