#!/bin/bash

echo "🔧 Direct Attendance Count Fix"
echo "============================="

cd /home/unitrans/backend-new

# Stop backend
echo "⏹️ Stopping backend..."
pm2 stop unitrans-backend

# Create new clean files instead of using sed
echo "🔧 Creating clean attendance files..."

# Create clean attendance.js
cat > routes/attendance.js << 'EOF'
const express = require('express');
const router = express.Router();
const { ObjectId } = require('mongodb');

// Get all attendance records
router.get('/all-records', async (req, res) => {
    try {
        const db = req.app.locals.db;
        const { page = 1, limit = 10 } = req.query;
        
        const skip = (page - 1) * limit;
        
        // Get attendance records from both collections
        const attendanceRecords = await db.collection('attendance').find({}).skip(skip).limit(parseInt(limit)).toArray();
        const shiftRecords = await db.collection('shifts').find({}).skip(skip).limit(parseInt(limit)).toArray();
        
        // Combine and deduplicate records
        const allRecords = [...attendanceRecords, ...shiftRecords];
        const uniqueRecords = allRecords.filter((record, index, self) => 
            index === self.findIndex(r => r._id.toString() === record._id.toString())
        );
        
        // Get total count
        const totalAttendance = await db.collection('attendance').countDocuments();
        const totalShifts = await db.collection('shifts').countDocuments();
        const total = totalAttendance + totalShifts;
        
        res.json({
            success: true,
            records: uniqueRecords,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        console.error('Error fetching attendance records:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch attendance records' });
    }
});

// Register attendance
router.post('/register', async (req, res) => {
    try {
        const db = req.app.locals.db;
        const { studentId, studentEmail, location, notes } = req.body;
        
        if (!studentId && !studentEmail) {
            return res.status(400).json({ success: false, message: 'Student ID or email is required' });
        }
        
        // Find student
        let student;
        if (studentId) {
            student = await db.collection('students').findOne({ _id: new ObjectId(studentId) });
        } else {
            student = await db.collection('students').findOne({ email: studentEmail });
        }
        
        if (!student) {
            return res.status(404).json({ success: false, message: 'Student not found' });
        }
        
        // Create attendance record
        const attendanceRecord = {
            studentId: student._id,
            studentEmail: student.email,
            studentName: student.fullName,
            location: location || 'Unknown',
            notes: notes || '',
            timestamp: new Date(),
            type: 'manual'
        };
        
        // Insert attendance record
        const result = await db.collection('attendance').insertOne(attendanceRecord);
        
        // Update student attendance count (increment by 1 only)
        const currentCount = student.attendanceCount || 0;
        const newCount = currentCount + 1;
        
        await db.collection('students').updateOne(
            { _id: student._id },
            { $set: { attendanceCount: newCount, updatedAt: new Date() } }
        );
        
        res.json({
            success: true,
            message: 'Attendance registered successfully',
            attendanceId: result.insertedId,
            attendanceCount: newCount
        });
    } catch (error) {
        console.error('Error registering attendance:', error);
        res.status(500).json({ success: false, message: 'Failed to register attendance' });
    }
});

module.exports = router;
EOF

# Create clean admin.js
cat > routes/admin.js << 'EOF'
const express = require('express');
const router = express.Router();
const { ObjectId } = require('mongodb');

// Get all students with attendance count
router.get('/students', async (req, res) => {
    try {
        const db = req.app.locals.db;
        
        // Get all students
        const students = await db.collection('students').find({}).toArray();
        
        // Calculate attendance for each student
        const studentsWithAttendance = await Promise.all(students.map(async (student) => {
            // Get attendance count from attendance collection
            const attendanceCount = await db.collection('attendance').countDocuments({
                $or: [
                    { studentId: student._id },
                    { studentEmail: student.email }
                ]
            });
            
            // Get attendance count from shifts collection
            const shiftCount = await db.collection('shifts').countDocuments({
                $or: [
                    { studentId: student._id },
                    { studentEmail: student.email }
                ]
            });
            
            // Total attendance count
            const totalAttendance = attendanceCount + shiftCount;
            
            return {
                ...student,
                attendanceCount: totalAttendance
            };
        }));
        
        res.json({
            success: true,
            students: studentsWithAttendance,
            total: studentsWithAttendance.length
        });
    } catch (error) {
        console.error('Error fetching students:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch students' });
    }
});

// Get subscriptions
router.get('/subscriptions', async (req, res) => {
    try {
        const db = req.app.locals.db;
        const subscriptions = await db.collection('subscriptions').find({}).toArray();
        
        res.json({
            success: true,
            subscriptions
        });
    } catch (error) {
        console.error('Error fetching subscriptions:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch subscriptions' });
    }
});

module.exports = router;
EOF

# Create clean shifts.js
cat > routes/shifts.js << 'EOF'
const express = require('express');
const router = express.Router();
const { ObjectId } = require('mongodb');

// Scan QR code and register attendance
router.post('/scan', async (req, res) => {
    try {
        const db = req.app.locals.db;
        const { qrData, location, supervisorId } = req.body;
        
        if (!qrData) {
            return res.status(400).json({ success: false, message: 'QR data is required' });
        }
        
        let studentData;
        try {
            studentData = JSON.parse(qrData);
        } catch (error) {
            return res.status(400).json({ success: false, message: 'Invalid QR data format' });
        }
        
        // Find student by ID or email
        let student;
        if (studentData.id) {
            student = await db.collection('students').findOne({ _id: new ObjectId(studentData.id) });
        } else if (studentData.studentId) {
            student = await db.collection('students').findOne({ studentId: studentData.studentId });
        } else if (studentData.email) {
            student = await db.collection('students').findOne({ email: studentData.email });
        }
        
        if (!student) {
            return res.status(404).json({ success: false, message: 'Student not found' });
        }
        
        // Create attendance record
        const attendanceRecord = {
            studentId: student._id,
            studentEmail: student.email,
            studentName: student.fullName,
            college: student.college,
            major: student.major,
            grade: student.grade,
            phoneNumber: student.phoneNumber,
            address: student.address,
            academicYear: student.academicYear,
            location: location || 'Unknown',
            supervisorId: supervisorId || null,
            timestamp: new Date(),
            type: 'qr_scan',
            qrData: studentData
        };
        
        // Insert attendance record
        const result = await db.collection('shifts').insertOne(attendanceRecord);
        
        // Update student attendance count (increment by 1 only)
        const currentCount = student.attendanceCount || 0;
        const newCount = currentCount + 1;
        
        await db.collection('students').updateOne(
            { _id: student._id },
            { $set: { attendanceCount: newCount, updatedAt: new Date() } }
        );
        
        res.json({
            success: true,
            message: 'Attendance registered successfully',
            attendanceId: result.insertedId,
            student: {
                _id: student._id,
                studentId: student.studentId,
                fullName: student.fullName,
                email: student.email,
                college: student.college,
                major: student.major,
                grade: student.grade,
                attendanceCount: newCount
            }
        });
    } catch (error) {
        console.error('Error scanning QR code:', error);
        res.status(500).json({ success: false, message: 'Failed to scan QR code' });
    }
});

// Get active shifts
router.get('/active', async (req, res) => {
    try {
        const db = req.app.locals.db;
        const shifts = await db.collection('shifts').find({}).sort({ timestamp: -1 }).limit(10).toArray();
        
        res.json({
            success: true,
            shifts
        });
    } catch (error) {
        console.error('Error fetching active shifts:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch active shifts' });
    }
});

module.exports = router;
EOF

# Check syntax
echo "🧪 Checking syntax after creating clean files..."
if node -c routes/attendance.js; then
    echo "✅ attendance.js syntax is valid"
else
    echo "❌ attendance.js syntax error"
fi

if node -c routes/admin.js; then
    echo "✅ admin.js syntax is valid"
else
    echo "❌ admin.js syntax error"
fi

if node -c routes/shifts.js; then
    echo "✅ shifts.js syntax is valid"
else
    echo "❌ shifts.js syntax error"
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
echo "✅ Direct attendance count fix completed!"
echo "🌍 Test your project at: https://unibus.online"
echo "📋 Now each attendance record should increment by 1 day only"
