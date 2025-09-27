// routes/attendance.js
const express = require('express');
const Attendance = require('../models/Attendance');
const Student = require('../models/Student');
const authMiddleware = require('../middleware/auth');
const { body, validationResult } = require('express-validator');

const router = express.Router();

// Scan QR code and register attendance (Supervisor only)
router.post('/scan-qr', [
    authMiddleware,
    body('qrData').notEmpty(),
    body('appointmentSlot').isIn(['first', 'second']),
    body('stationName').notEmpty(),
    body('stationLocation').notEmpty(),
    body('coordinates').notEmpty()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: 'Validation errors',
                errors: errors.array()
            });
        }

        if (req.user.role !== 'supervisor' && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Supervisors and admins only.'
            });
        }

        const { qrData, appointmentSlot, stationName, stationLocation, coordinates } = req.body;

        let studentData;
        try {
            studentData = JSON.parse(qrData);
        } catch (error) {
            return res.status(400).json({
                success: false,
                message: 'Invalid QR code format'
            });
        }

        // Find student
        const student = await Student.findById(studentData.id);
        if (!student) {
            return res.status(404).json({
                success: false,
                message: 'Student not found'
            });
        }

        // Check if attendance already exists for today and this slot
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        const existingAttendance = await Attendance.findOne({
            studentId: student._id,
            date: { $gte: today, $lt: tomorrow },
            appointmentSlot
        });

        if (existingAttendance) {
            return res.status(400).json({
                success: false,
                message: `Attendance already recorded for ${appointmentSlot} appointment today`,
                attendance: existingAttendance
            });
        }

        // Determine status based on time
        const now = new Date();
        const currentTime = now.getHours() * 60 + now.getMinutes();
        let status = 'Present';

        if (appointmentSlot === 'first') {
            // First appointment at 8:00 AM (480 minutes)
            if (currentTime > 500) { // After 8:20 AM
                status = 'Late';
            }
        } else if (appointmentSlot === 'second') {
            // Second appointment at 2:00 PM (840 minutes)
            if (currentTime > 860) { // After 2:20 PM
                status = 'Late';
            }
        }

        // Create attendance record
        const attendance = new Attendance({
            studentId: student._id,
            status,
            checkInTime: now,
            appointmentSlot,
            station: {
                name: stationName,
                location: stationLocation,
                coordinates
            },
            qrScanned: true,
            supervisorId: req.user._id
        });

        await attendance.save();

        // Update student attendance stats
        student.attendanceStats.daysRegistered += 1;
        student.attendanceStats.remainingDays = Math.max(0, student.attendanceStats.remainingDays - 1);

        // Calculate attendance rate
        const totalAttendance = await Attendance.countDocuments({ studentId: student._id });
        const presentAttendance = await Attendance.countDocuments({
            studentId: student._id,
            status: { $in: ['Present', 'Late'] }
        });
        student.attendanceStats.attendanceRate = Math.round((presentAttendance / totalAttendance) * 100);

        // Update status based on remaining days
        if (student.attendanceStats.remainingDays <= 5) {
            student.status = 'Critical';
        } else if (student.attendanceStats.remainingDays <= 20) {
            student.status = 'Low Days';
        } else {
            student.status = 'Active';
        }

        await student.save();

        res.json({
            success: true,
            message: 'Attendance registered successfully',
            attendance,
            student: {
                id: student._id,
                name: student.fullName,
                studentId: student.studentId,
                status: student.status,
                attendanceStats: student.attendanceStats
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to register attendance',
            error: error.message
        });
    }
});

// Get all attendance records (Admin/Supervisor only)
router.get('/records', authMiddleware, async (req, res) => {
    try {
        if (req.user.role !== 'admin' && req.user.role !== 'supervisor') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admins and supervisors only.'
            });
        }

        const {
            page = 1,
            limit = 10,
            startDate,
            endDate,
            status,
            appointmentSlot,
            college,
            search
        } = req.query;

        // Build query
        const query = {};

        if (startDate || endDate) {
            query.date = {};
            if (startDate) query.date.$gte = new Date(startDate);
            if (endDate) query.date.$lte = new Date(endDate);
        }

        if (status) {
            query.status = status;
        }

        if (appointmentSlot) {
            query.appointmentSlot = appointmentSlot;
        }

        let attendanceQuery = Attendance.find(query)
            .populate({
                path: 'studentId',
                select: 'fullName studentId college academicYear status attendanceStats',
                match: college ? { college } : {}
            })
            .populate('supervisorId', 'email')
            .sort({ date: -1, checkInTime: -1 });

        // Apply search if provided
        if (search) {
            attendanceQuery = attendanceQuery.populate({
                path: 'studentId',
                match: {
                    $or: [
                        { fullName: { $regex: search, $options: 'i' } },
                        { studentId: { $regex: search, $options: 'i' } }
                    ]
                }
            });
        }

        const attendanceRecords = await attendanceQuery
            .limit(limit * 1)
            .skip((page - 1) * limit);

        // Filter out records where student population failed due to college filter
        const filteredRecords = attendanceRecords.filter(record => record.studentId);

        const total = await Attendance.countDocuments(query);

        res.json({
            success: true,
            attendance: filteredRecords,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / limit)
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to get attendance records',
            error: error.message
        });
    }
});

// Get today's attendance overview (Admin/Supervisor only)
router.get('/today', authMiddleware, async (req, res) => {
    try {
        if (req.user.role !== 'admin' && req.user.role !== 'supervisor') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admins and supervisors only.'
            });
        }

        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        // Get today's attendance
        const todayAttendance = await Attendance.find({
            date: { $gte: today, $lt: tomorrow }
        }).populate('studentId', 'fullName studentId college');

        // Calculate statistics
        const stats = {
            total: todayAttendance.length,
            present: todayAttendance.filter(a => a.status === 'Present').length,
            late: todayAttendance.filter(a => a.status === 'Late').length,
            absent: 0, // This would need to be calculated based on expected vs actual attendance
            firstAppointment: todayAttendance.filter(a => a.appointmentSlot === 'first').length,
            secondAppointment: todayAttendance.filter(a => a.appointmentSlot === 'second').length
        };

        // Get attendance by hour for chart data
        const attendanceByHour = await Attendance.aggregate([
            {
                $match: {
                    date: { $gte: today, $lt: tomorrow },
                    checkInTime: { $exists: true }
                }
            },
            {
                $group: {
                    _id: { $hour: '$checkInTime' },
                    count: { $sum: 1 }
                }
            },
            {
                $sort: { '_id': 1 }
            }
        ]);

        res.json({
            success: true,
            stats,
            attendanceByHour,
            records: todayAttendance
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to get today\'s attendance',
            error: error.message
        });
    }
});

// Mark student as absent (Admin/Supervisor only)
router.post('/mark-absent', [
    authMiddleware,
    body('studentId').notEmpty(),
    body('appointmentSlot').isIn(['first', 'second']),
    body('date').isISO8601()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: 'Validation errors',
                errors: errors.array()
            });
        }

        if (req.user.role !== 'admin' && req.user.role !== 'supervisor') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admins and supervisors only.'
            });
        }

        const { studentId, appointmentSlot, date } = req.body;

        // Check if attendance already exists
        const existingAttendance = await Attendance.findOne({
            studentId,
            date: new Date(date),
            appointmentSlot
        });

        if (existingAttendance) {
            return res.status(400).json({
                success: false,
                message: 'Attendance record already exists for this date and slot'
            });
        }

        // Create absent record
        const attendance = new Attendance({
            studentId,
            status: 'Absent',
            date: new Date(date),
            appointmentSlot,
            qrScanned: false,
            supervisorId: req.user._id
        });

        await attendance.save();

        res.json({
            success: true,
            message: 'Student marked as absent',
            attendance
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to mark student as absent',
            error: error.message
        });
    }
});

// Update attendance record (Admin only)
router.put('/update/:attendanceId', [
    authMiddleware,
    body('status').isIn(['Present', 'Late', 'Absent']),
    body('notes').optional().trim()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: 'Validation errors',
                errors: errors.array()
            });
        }

        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admins only.'
            });
        }

        const { attendanceId } = req.params;
        const { status, notes } = req.body;

        const attendance = await Attendance.findByIdAndUpdate(
            attendanceId,
            { status, notes },
            { new: true, runValidators: true }
        ).populate('studentId', 'fullName studentId');

        if (!attendance) {
            return res.status(404).json({
                success: false,
                message: 'Attendance record not found'
            });
        }

        res.json({
            success: true,
            message: 'Attendance record updated successfully',
            attendance
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to update attendance record',
            error: error.message
        });
    }
});

// Get attendance statistics (Admin only)
router.get('/stats', authMiddleware, async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admins only.'
            });
        }

        const { startDate, endDate, college } = req.query;

        const matchQuery = {};
        if (startDate || endDate) {
            matchQuery.date = {};
            if (startDate) matchQuery.date.$gte = new Date(startDate);
            if (endDate) matchQuery.date.$lte = new Date(endDate);
        }

        // Overall statistics
        const overallStats = await Attendance.aggregate([
            { $match: matchQuery },
            {
                $group: {
                    _id: '$status',
                    count: { $sum: 1 }
                }
            }
        ]);

        // Statistics by college
        const collegeStats = await Attendance.aggregate([
            { $match: matchQuery },
            {
                $lookup: {
                    from: 'students',
                    localField: 'studentId',
                    foreignField: '_id',
                    as: 'student'
                }
            },
            { $unwind: '$student' },
            ...(college ? [{ $match: { 'student.college': college } }] : []),
            {
                $group: {
                    _id: {
                        college: '$student.college',
                        status: '$status'
                    },
                    count: { $sum: 1 }
                }
            }
        ]);

        // Daily attendance trends
        const dailyTrends = await Attendance.aggregate([
            { $match: matchQuery },
            {
                $group: {
                    _id: {
                        year: { $year: '$date' },
                        month: { $month: '$date' },
                        day: { $dayOfMonth: '$date' }
                    },
                    total: { $sum: 1 },
                    present: {
                        $sum: {
                            $cond: [{ $eq: ['$status', 'Present'] }, 1, 0]
                        }
                    },
                    late: {
                        $sum: {
                            $cond: [{ $eq: ['$status', 'Late'] }, 1, 0]
                        }
                    },
                    absent: {
                        $sum: {
                            $cond: [{ $eq: ['$status', 'Absent'] }, 1, 0]
                        }
                    }
                }
            },
            { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } }
        ]);

        res.json({
            success: true,
            stats: {
                overall: overallStats,
                byCollege: collegeStats,
                dailyTrends
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to get attendance statistics',
            error: error.message
        });
    }
});

// Delete attendance record (Admin/Supervisor only)
router.delete('/delete/:attendanceId', authMiddleware, async (req, res) => {
    try {
        if (req.user.role !== 'admin' && req.user.role !== 'supervisor') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admins and supervisors only.'
            });
        }

        const { attendanceId } = req.params;

        const attendance = await Attendance.findByIdAndDelete(attendanceId)
            .populate('studentId', 'fullName studentId');

        if (!attendance) {
            return res.status(404).json({
                success: false,
                message: 'Attendance record not found'
            });
        }

        // Update student attendance stats after deletion
        const student = await Student.findById(attendance.studentId._id);
        if (student) {
            student.attendanceStats.daysRegistered = Math.max(0, student.attendanceStats.daysRegistered - 1);
            student.attendanceStats.remainingDays = Math.min(180, student.attendanceStats.remainingDays + 1);

            // Recalculate attendance rate
            const totalAttendance = await Attendance.countDocuments({ studentId: student._id });
            const presentAttendance = await Attendance.countDocuments({
                studentId: student._id,
                status: { $in: ['Present', 'Late'] }
            });
            student.attendanceStats.attendanceRate = totalAttendance > 0 ? 
                Math.round((presentAttendance / totalAttendance) * 100) : 0;

            // Update status based on remaining days
            if (student.attendanceStats.remainingDays <= 5) {
                student.status = 'Critical';
            } else if (student.attendanceStats.remainingDays <= 20) {
                student.status = 'Low Days';
            } else {
                student.status = 'Active';
            }

            await student.save();
        }

        res.json({
            success: true,
            message: 'Attendance record deleted successfully',
            deletedAttendance: attendance
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to delete attendance record',
            error: error.message
        });
    }
});

// Get student attendance count (Admin/Supervisor only)
router.get('/student/:studentId/count', authMiddleware, async (req, res) => {
    try {
        if (req.user.role !== 'admin' && req.user.role !== 'supervisor') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admins and supervisors only.'
            });
        }

        const { studentId } = req.params;
        const { startDate, endDate } = req.query;

        // Build date query
        const dateQuery = {};
        if (startDate || endDate) {
            dateQuery.date = {};
            if (startDate) dateQuery.date.$gte = new Date(startDate);
            if (endDate) dateQuery.date.$lte = new Date(endDate);
        }

        const attendanceCount = await Attendance.countDocuments({
            studentId,
            ...dateQuery
        });

        const presentCount = await Attendance.countDocuments({
            studentId,
            status: { $in: ['Present', 'Late'] },
            ...dateQuery
        });

        const lateCount = await Attendance.countDocuments({
            studentId,
            status: 'Late',
            ...dateQuery
        });

        const absentCount = await Attendance.countDocuments({
            studentId,
            status: 'Absent',
            ...dateQuery
        });

        res.json({
            success: true,
            counts: {
                total: attendanceCount,
                present: presentCount,
                late: lateCount,
                absent: absentCount,
                attendanceRate: attendanceCount > 0 ? Math.round((presentCount / attendanceCount) * 100) : 0
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to get student attendance count',
            error: error.message
        });
    }
});

// Get all attendance records with complete student data (for admin dashboard)
router.get('/all-records', async (req, res) => {
    try {
        const { 
            page = 1, 
            limit = 50, 
            search = '',
            sortBy = 'scanTime',
            sortOrder = 'desc' 
        } = req.query;

        const db = req.app.locals.db;
        if (!db) {
            return res.status(500).json({
                success: false,
                message: 'Database connection not available'
            });
        }

        // Build aggregation pipeline
        const pipeline = [];

        // Match stage (search functionality)
        const matchStage = {};
        if (search) {
            matchStage.$or = [
                { studentName: { $regex: search, $options: 'i' } },
                { studentEmail: { $regex: search, $options: 'i' } },
                { studentId: { $regex: search, $options: 'i' } },
                { college: { $regex: search, $options: 'i' } },
                { major: { $regex: search, $options: 'i' } }
            ];
        }

        if (Object.keys(matchStage).length > 0) {
            pipeline.push({ $match: matchStage });
        }

        // Sort stage
        const sortStage = {};
        sortStage[sortBy] = sortOrder === 'asc' ? 1 : -1;
        pipeline.push({ $sort: sortStage });

        // Get data from both collections
        const attendanceCollection = db.collection('attendance');
        const shiftsCollection = db.collection('shifts');

        // Get shift-based attendance records
        const shiftRecords = await shiftsCollection.aggregate([
            { $match: { status: { $in: ['open', 'closed'] } } },
            { $unwind: { path: '$attendanceRecords', preserveNullAndEmptyArrays: false } },
            { 
                $project: {
                    _id: '$attendanceRecords._id',
                    studentName: '$attendanceRecords.studentName',
                    studentId: '$attendanceRecords.studentId', 
                    studentEmail: '$attendanceRecords.studentEmail',
                    college: '$attendanceRecords.college',
                    major: '$attendanceRecords.major',
                    grade: '$attendanceRecords.grade',
                    phoneNumber: '$attendanceRecords.phoneNumber',
                    address: '$attendanceRecords.address',
                    scanTime: '$attendanceRecords.scanTime',
                    createdAt: '$attendanceRecords.createdAt',
                    status: '$attendanceRecords.status',
                    location: '$attendanceRecords.location',
                    shiftId: '$attendanceRecords.shiftId',
                    supervisorId: '$attendanceRecords.supervisorId',
                    source: 'shift'
                }
            },
            ...pipeline
        ]).toArray();

        // Get standalone attendance records
        const standaloneRecords = await attendanceCollection.aggregate([
            { 
                $project: {
                    studentName: 1,
                    studentId: 1,
                    studentEmail: 1,
                    studentCollege: { $ifNull: ['$studentCollege', '$college'] },
                    studentMajor: { $ifNull: ['$studentMajor', '$major'] },
                    studentGrade: { $ifNull: ['$studentGrade', '$grade'] },
                    studentPhone: { $ifNull: ['$studentPhone', '$phoneNumber'] },
                    studentAddress: { $ifNull: ['$studentAddress', '$address'] },
                    checkInTime: { $ifNull: ['$checkInTime', '$scanTime'] },
                    createdAt: 1,
                    status: 1,
                    location: { $ifNull: ['$station.location', '$location'] },
                    supervisorId: 1,
                    appointmentSlot: 1,
                    source: 'standalone'
                }
            },
            ...pipeline
        ]).toArray();

        // Combine and deduplicate records
        const allRecords = [...shiftRecords, ...standaloneRecords];
        
        // Remove duplicates based on student email and date
        const uniqueRecords = [];
        const seen = new Set();
        
        for (const record of allRecords) {
            const key = `${record.studentEmail}_${new Date(record.scanTime || record.checkInTime || record.createdAt).toDateString()}`;
            if (!seen.has(key)) {
                seen.add(key);
                uniqueRecords.push({
                    _id: record._id,
                    studentName: record.studentName || 'Unknown',
                    studentId: record.studentId || 'N/A',
                    studentEmail: record.studentEmail || 'N/A',
                    college: record.college || record.studentCollege || 'N/A',
                    major: record.major || record.studentMajor || 'N/A', 
                    grade: record.grade || record.studentGrade || 'N/A',
                    phoneNumber: record.phoneNumber || record.studentPhone || 'N/A',
                    address: record.address || record.studentAddress || 'N/A',
                    scanTime: record.scanTime || record.checkInTime || record.createdAt,
                    status: record.status || 'Present',
                    location: record.location || 'Unknown',
                    source: record.source
                });
            }
        }

        // Apply pagination
        const startIndex = (parseInt(page) - 1) * parseInt(limit);
        const endIndex = startIndex + parseInt(limit);
        const paginatedRecords = uniqueRecords.slice(startIndex, endIndex);

        res.json({
            success: true,
            attendance: paginatedRecords,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total: uniqueRecords.length,
                pages: Math.ceil(uniqueRecords.length / parseInt(limit))
            },
            summary: {
                totalRecords: uniqueRecords.length,
                shiftRecords: shiftRecords.length,
                standaloneRecords: standaloneRecords.length
            }
        });

    } catch (error) {
        console.error('Get all attendance records error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get attendance records',
            error: error.message
        });
    }
});

module.exports = router;