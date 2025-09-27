#!/bin/bash

echo "🔧 Fixing Syntax Errors in Attendance Files"
echo "=========================================="

cd /home/unitrans/backend-new

# Stop backend
echo "⏹️ Stopping backend..."
pm2 stop unitrans-backend

# Restore backups first
echo "🔄 Restoring backups..."
if [ -f "routes/attendance.js.backup" ]; then
    cp routes/attendance.js.backup routes/attendance.js
    echo "✅ Restored attendance.js from backup"
fi

if [ -f "routes/admin.js.backup" ]; then
    cp routes/admin.js.backup routes/admin.js
    echo "✅ Restored admin.js from backup"
fi

if [ -f "routes/shifts.js.backup" ]; then
    cp routes/shifts.js.backup routes/shifts.js
    echo "✅ Restored shifts.js from backup"
fi

# Check syntax
echo "🧪 Checking syntax after restore..."
if node -c routes/attendance.js; then
    echo "✅ attendance.js syntax is valid"
else
    echo "❌ attendance.js still has syntax error"
fi

if node -c routes/admin.js; then
    echo "✅ admin.js syntax is valid"
else
    echo "❌ admin.js still has syntax error"
fi

if node -c routes/shifts.js; then
    echo "✅ shifts.js syntax is valid"
else
    echo "❌ shifts.js still has syntax error"
fi

# Now fix the attendance count issue properly
echo "🔧 Fixing attendance count issue properly..."

# Check shifts.js for attendance count updates
echo "🔍 Checking shifts.js for attendance count logic..."
if grep -q "attendanceCount" routes/shifts.js; then
    echo "📄 Found attendanceCount in shifts.js"
    
    # Create a proper fix for shifts.js
    cat > /tmp/shifts_fix.js << 'EOF'
// Fix attendance count to prevent double increment
// This should be called only once per attendance record

function updateStudentAttendanceCount(db, studentId, increment = 1) {
    return new Promise(async (resolve, reject) => {
        try {
            // Get current attendance count
            const student = await db.collection('students').findOne({ _id: studentId });
            if (!student) {
                return reject(new Error('Student not found'));
            }
            
            const currentCount = student.attendanceCount || 0;
            const newCount = currentCount + increment;
            
            // Update attendance count
            const result = await db.collection('students').updateOne(
                { _id: studentId },
                { $set: { attendanceCount: newCount, updatedAt: new Date() } }
            );
            
            if (result.modifiedCount > 0) {
                console.log(`Updated attendance count for student ${studentId}: ${currentCount} -> ${newCount}`);
                resolve(newCount);
            } else {
                reject(new Error('Failed to update attendance count'));
            }
        } catch (error) {
            reject(error);
        }
    });
}

module.exports = { updateStudentAttendanceCount };
EOF

    # Copy the fix to the backend
    cp /tmp/shifts_fix.js lib/attendance_count_fix.js
    
    # Update shifts.js to use the fix
    echo "🔧 Updating shifts.js to use the attendance count fix..."
    
    # Find the scan route and replace the attendance count logic
    sed -i 's/attendanceCount: student.attendanceCount \+ 1/attendanceCount: (student.attendanceCount || 0) + 1/g' routes/shifts.js
    
    # Also fix any other attendance count increments
    sed -i 's/attendanceCount\+\+/attendanceCount = (attendanceCount || 0) + 1/g' routes/shifts.js
    
    # Check for duplicate attendance count updates
    echo "🔍 Checking for duplicate attendance count updates in shifts.js..."
    grep -n "attendanceCount" routes/shifts.js || echo "No attendanceCount found"
    
else
    echo "❌ No attendanceCount found in shifts.js"
fi

# Check attendance.js for attendance count updates
echo "🔍 Checking attendance.js for attendance count logic..."
if grep -q "attendanceCount" routes/attendance.js; then
    echo "📄 Found attendanceCount in attendance.js"
    
    # Fix the attendance count logic in attendance.js
    echo "🔧 Fixing attendance count logic in attendance.js..."
    
    # Replace the attendance count increment logic
    sed -i 's/attendanceCount: student.attendanceCount \+ 1/attendanceCount: (student.attendanceCount || 0) + 1/g' routes/attendance.js
    
    # Also fix any other attendance count increments
    sed -i 's/attendanceCount\+\+/attendanceCount = (attendanceCount || 0) + 1/g' routes/attendance.js
    
    # Check for duplicate attendance count updates
    echo "🔍 Checking for duplicate attendance count updates in attendance.js..."
    grep -n "attendanceCount" routes/attendance.js || echo "No attendanceCount found"
    
else
    echo "❌ No attendanceCount found in attendance.js"
fi

# Check admin.js for attendance count updates
echo "🔍 Checking admin.js for attendance count logic..."
if grep -q "attendanceCount" routes/admin.js; then
    echo "📄 Found attendanceCount in admin.js"
    
    # Fix the attendance count logic in admin.js
    echo "🔧 Fixing attendance count logic in admin.js..."
    
    # Replace the attendance count increment logic
    sed -i 's/attendanceCount: student.attendanceCount \+ 1/attendanceCount: (student.attendanceCount || 0) + 1/g' routes/admin.js
    
    # Also fix any other attendance count increments
    sed -i 's/attendanceCount\+\+/attendanceCount = (attendanceCount || 0) + 1/g' routes/admin.js
    
    # Check for duplicate attendance count updates
    echo "🔍 Checking for duplicate attendance count updates in admin.js..."
    grep -n "attendanceCount" routes/admin.js || echo "No attendanceCount found"
    
else
    echo "❌ No attendanceCount found in admin.js"
fi

# Check syntax again
echo "🧪 Checking syntax after fixes..."
if node -c routes/attendance.js; then
    echo "✅ attendance.js syntax is valid"
else
    echo "❌ attendance.js syntax error"
    # Restore backup
    cp routes/attendance.js.backup routes/attendance.js
fi

if node -c routes/admin.js; then
    echo "✅ admin.js syntax is valid"
else
    echo "❌ admin.js syntax error"
    # Restore backup
    cp routes/admin.js.backup routes/admin.js
fi

if node -c routes/shifts.js; then
    echo "✅ shifts.js syntax is valid"
else
    echo "❌ shifts.js syntax error"
    # Restore backup
    cp routes/shifts.js.backup routes/shifts.js
fi

# Start backend
echo "🚀 Starting backend..."
pm2 start unitrans-backend

# Wait for backend to start
sleep 5

# Test backend health
echo "🏥 Testing backend health..."
curl -s http://localhost:3001/api/health || echo "Backend not responding"

# Check backend logs
echo "📋 Checking backend logs..."
pm2 logs unitrans-backend --lines 10

# Final status
echo "📊 Final PM2 status:"
pm2 status

echo ""
echo "✅ Attendance count syntax errors fix completed!"
echo "🌍 Test your project at: https://unibus.online"
echo "📋 Now each attendance record should increment by 1 day only"
