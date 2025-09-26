#!/bin/bash

echo "🔧 Fixing Attendance Page - Keep Original Design"

cd /home/unitrans/frontend-new

# Backup original file
cp app/admin/attendance/page.js app/admin/attendance/page.js.backup

# Fix the original file by adding null checks without changing design
echo "🔧 Adding null checks to original attendance page..."

# Create a sed script to fix the common issues
cat > fix_attendance.sed << 'EOF'
# Fix calculateSummaryStats function
s/const calculateSummaryStats = (studentsList) => {/const calculateSummaryStats = (studentsList = []) => {/
s/return {/if (!Array.isArray(studentsList)) return {\n    totalStudents: 0,\n    activeStudents: 0,\n    inactiveStudents: 0,\n    criticalStatus: 0\n  };\n  return {/

# Fix array access issues
s/studentsList\.length/studentsList ? studentsList.length : 0/g
s/studentsList\.filter/studentsList ? studentsList.filter/g

# Fix data.records access
s/data\.records\.map/Array.isArray(data.records) ? data.records.map/g
s/data\.records\.filter/Array.isArray(data.records) ? data.records.filter/g

# Fix shiftPages access
s/shiftPages\.map/Array.isArray(shiftPages) ? shiftPages.map/g
s/shiftPages\.length/Array.isArray(shiftPages) ? shiftPages.length : 0/g

# Fix activeShifts access
s/activeShifts\.length/Array.isArray(activeShifts) ? activeShifts.length : 0/g
s/activeShifts\.map/Array.isArray(activeShifts) ? activeShifts.map/g

# Fix supervisors access
s/supervisors\.map/Array.isArray(supervisors) ? supervisors.map/g
s/supervisors\.length/Array.isArray(supervisors) ? supervisors.length : 0/g

# Fix attendanceRecords access
s/attendanceRecords\.map/Array.isArray(attendanceRecords) ? attendanceRecords.map/g
s/attendanceRecords\.length/Array.isArray(attendanceRecords) ? attendanceRecords.length : 0/g
EOF

# Apply the fixes
sed -i -f fix_attendance.sed app/admin/attendance/page.js

# Add additional safety checks
echo "🔧 Adding additional safety checks..."

# Add null checks for data loading
cat >> app/admin/attendance/page.js << 'EOF'

// Additional safety checks
const safeArray = (arr) => Array.isArray(arr) ? arr : [];
const safeLength = (arr) => Array.isArray(arr) ? arr.length : 0;
EOF

# Fix specific problematic lines
sed -i 's/data\.records\.map(record => record\.studentEmail)/safeArray(data.records).map(record => record.studentEmail)/g' app/admin/attendance/page.js
sed -i 's/data\.records\.map(record => record\.shiftId)/safeArray(data.records).map(record => record.shiftId)/g' app/admin/attendance/page.js
sed -i 's/data\.records\.filter(record =>/safeArray(data.records).filter(record =>/g' app/admin/attendance/page.js

# Fix shiftPages access
sed -i 's/shiftPages\.map((page, index) =>/safeArray(shiftPages).map((page, index) =>/g' app/admin/attendance/page.js
sed -i 's/shiftPages\.length/safeLength(shiftPages)/g' app/admin/attendance/page.js

# Fix activeShifts access
sed -i 's/activeShifts\.length/safeLength(activeShifts)/g' app/admin/attendance/page.js
sed -i 's/activeShifts\.map/safeArray(activeShifts).map/g' app/admin/attendance/page.js

# Fix supervisors access
sed -i 's/supervisors\.map/safeArray(supervisors).map/g' app/admin/attendance/page.js
sed -i 's/supervisors\.length/safeLength(supervisors)/g' app/admin/attendance/page.js

# Fix attendanceRecords access
sed -i 's/attendanceRecords\.map/safeArray(attendanceRecords).map/g' app/admin/attendance/page.js
sed -i 's/attendanceRecords\.length/safeLength(attendanceRecords)/g' app/admin/attendance/page.js

# Add error handling to loadAttendanceRecords
sed -i '/if (response.ok) {/a\
        if (data.success && Array.isArray(data.records)) {' app/admin/attendance/page.js

# Add error handling to loadSupervisors
sed -i '/if (data.success) {/a\
          if (Array.isArray(data.shifts)) {' app/admin/attendance/page.js

# Add error handling to loadActiveShifts
sed -i '/if (data.success) {/a\
          if (Array.isArray(data.shifts)) {' app/admin/attendance/page.js

# Clean up
rm fix_attendance.sed

# Rebuild frontend
echo "🏗️ Rebuilding frontend..."
npm run build

# Restart frontend
echo "🔄 Restarting frontend..."
pm2 stop unitrans-frontend
pm2 start "npm run start" --name "unitrans-frontend"

echo "✅ Attendance page fix complete - Original design preserved!"
echo "🌍 Test at: https://unibus.online/admin/attendance"
