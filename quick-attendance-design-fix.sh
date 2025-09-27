#!/bin/bash

echo "🔧 Quick Attendance Fix - Keep Original Design"

cd /home/unitrans/frontend-new

# Create helper functions for safe array access
cat > app/admin/attendance/safe-helpers.js << 'EOF'
// Safe array helpers to prevent undefined errors
export const safeArray = (arr) => Array.isArray(arr) ? arr : [];
export const safeLength = (arr) => Array.isArray(arr) ? arr.length : 0;
export const safeMap = (arr, callback) => Array.isArray(arr) ? arr.map(callback) : [];
export const safeFilter = (arr, callback) => Array.isArray(arr) ? arr.filter(callback) : [];
EOF

# Add import to the main file
sed -i '1a\
import { safeArray, safeLength, safeMap, safeFilter } from "./safe-helpers";' app/admin/attendance/page.js

# Fix the most common issues
echo "🔧 Fixing common array access issues..."

# Fix calculateSummaryStats
sed -i 's/const calculateSummaryStats = (studentsList) => {/const calculateSummaryStats = (studentsList = []) => {/' app/admin/attendance/page.js

# Fix data.records access
sed -i 's/data\.records\.map/safeMap(data.records, /g' app/admin/attendance/page.js
sed -i 's/data\.records\.filter/safeFilter(data.records, /g' app/admin/attendance/page.js

# Fix shiftPages access
sed -i 's/shiftPages\.map/safeMap(shiftPages, /g' app/admin/attendance/page.js
sed -i 's/shiftPages\.length/safeLength(shiftPages)/g' app/admin/attendance/page.js

# Fix activeShifts access
sed -i 's/activeShifts\.length/safeLength(activeShifts)/g' app/admin/attendance/page.js
sed -i 's/activeShifts\.map/safeMap(activeShifts, /g' app/admin/attendance/page.js

# Fix supervisors access
sed -i 's/supervisors\.map/safeMap(supervisors, /g' app/admin/attendance/page.js
sed -i 's/supervisors\.length/safeLength(supervisors)/g' app/admin/attendance/page.js

# Fix attendanceRecords access
sed -i 's/attendanceRecords\.map/safeMap(attendanceRecords, /g' app/admin/attendance/page.js
sed -i 's/attendanceRecords\.length/safeLength(attendanceRecords)/g' app/admin/attendance/page.js

# Add null checks to data loading
sed -i '/if (data.success) {/a\
        if (Array.isArray(data.records)) {' app/admin/attendance/page.js

# Rebuild and restart
npm run build
pm2 restart unitrans-frontend

echo "✅ Quick attendance fix complete - Original design preserved!"
echo "🌍 Test at: https://unibus.online/admin/attendance"
