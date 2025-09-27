#!/bin/bash

# Check Supervisor Files Script
# This script will show all remaining supervisor files and paths

echo "🔍 Checking Supervisor Files and Paths..."

# Navigate to frontend directory
cd /var/www/unitrans/frontend-new
echo "📁 Current directory: $(pwd)"

# 1. Check for supervisor files
echo "📊 Checking for supervisor files..."
echo "=========================================="
find . -name "*supervisor*" -type f 2>/dev/null | head -20
echo "=========================================="

# 2. Check for supervisor directories
echo "📊 Checking for supervisor directories..."
echo "=========================================="
find . -name "*supervisor*" -type d 2>/dev/null | head -20
echo "=========================================="

# 3. Check for shifts files
echo "📊 Checking for shifts files..."
echo "=========================================="
find . -name "*shifts*" -type f 2>/dev/null | head -20
echo "=========================================="

# 4. Check for shifts directories
echo "📊 Checking for shifts directories..."
echo "=========================================="
find . -name "*shifts*" -type d 2>/dev/null | head -20
echo "=========================================="

# 5. Check .next directory for supervisor files
echo "📊 Checking .next directory for supervisor files..."
echo "=========================================="
find .next -name "*supervisor*" 2>/dev/null | head -20
echo "=========================================="

# 6. Check .next directory for shifts files
echo "📊 Checking .next directory for shifts files..."
echo "=========================================="
find .next -name "*shifts*" 2>/dev/null | head -20
echo "=========================================="

# 7. Check supervisor references in files
echo "📊 Checking supervisor references in files..."
echo "=========================================="
grep -r "supervisor" . --include="*.js" --include="*.jsx" --include="*.ts" --include="*.tsx" 2>/dev/null | head -10
echo "=========================================="

# 8. Check shifts references in files
echo "📊 Checking shifts references in files..."
echo "=========================================="
grep -r "shifts" . --include="*.js" --include="*.jsx" --include="*.ts" --include="*.tsx" 2>/dev/null | head -10
echo "=========================================="

# 9. Count remaining files
echo "📊 Counting remaining files..."
SUPERVISOR_FILES=$(find . -name "*supervisor*" 2>/dev/null | wc -l)
SHIFTS_FILES=$(find . -name "*shifts*" 2>/dev/null | wc -l)
echo "Supervisor files: $SUPERVISOR_FILES"
echo "Shifts files: $SHIFTS_FILES"

# 10. Test HTTP access
echo "🌐 Testing HTTP access..."
echo "=========================================="
echo "Testing supervisor dashboard..."
SUPERVISOR_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/admin/supervisor-dashboard)
echo "Supervisor dashboard HTTP status: $SUPERVISOR_RESPONSE"

echo "Testing shifts API..."
SHIFTS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/api/shifts)
echo "Shifts API HTTP status: $SHIFTS_RESPONSE"
echo "=========================================="

echo "✅ Check completed!"
