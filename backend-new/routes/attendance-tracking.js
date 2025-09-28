const express = require('express');
const { MongoClient } = require('mongodb');
const router = express.Router();

// Get database connection
const getDatabase = async () => {
  const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
  const dbName = process.env.MONGODB_DB_NAME || 'student_portal';
  const client = new MongoClient(mongoUri);
  await client.connect();
  return client.db(dbName);
};

// Get student attendance count
router.get('/student-count/:email', async (req, res) => {
  try {
    const { email } = req.params;
    
    const db = await getDatabase();
    
    // Get student data
    const student = await db.collection('students').findOne({
      email: email.toLowerCase()
    });
    
    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found'
      });
    }
    
    // Count attendance records from shifts
    const attendanceCount = await db.collection('shifts').aggregate([
      { $match: { status: 'closed' } },
      { $unwind: '$attendanceRecords' },
      { $match: { 'attendanceRecords.studentEmail': email.toLowerCase() } },
      { $count: 'total' }
    ]).toArray();
    
    const count = attendanceCount.length > 0 ? attendanceCount[0].total : 0;
    
    return res.json({
      success: true,
      attendanceCount: count,
      student: {
        id: student._id.toString(),
        fullName: student.fullName,
        email: student.email,
        college: student.college
      }
    });
    
  } catch (error) {
    console.error('❌ Get student attendance count error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Update student attendance count
router.put('/update-count/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const { count } = req.body;
    
    if (typeof count !== 'number' || count < 0) {
      return res.status(400).json({
        success: false,
        message: 'Valid count number is required'
      });
    }
    
    const db = await getDatabase();
    
    // Update student attendance count
    const result = await db.collection('students').updateOne(
      { email: email.toLowerCase() },
      { 
        $set: { 
          attendanceCount: count,
          updatedAt: new Date()
        } 
      }
    );
    
    if (result.matchedCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Student not found'
      });
    }
    
    return res.json({
      success: true,
      message: 'Attendance count updated successfully',
      attendanceCount: count
    });
    
  } catch (error) {
    console.error('❌ Update attendance count error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get all students with attendance data for admin
router.get('/admin/students-with-attendance', async (req, res) => {
  try {
    const { page = 1, limit = 20, search = '' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    const db = await getDatabase();
    
    // Build search query
    let query = {};
    if (search) {
      query = {
        $or: [
          { fullName: { $regex: search, $options: 'i' } },
          { email: { $regex: search, $options: 'i' } },
          { college: { $regex: search, $options: 'i' } },
          { major: { $regex: search, $options: 'i' } }
        ]
      };
    }
    
    // Get students with attendance count
    const students = await db.collection('students')
      .find(query)
      .skip(skip)
      .limit(parseInt(limit))
      .toArray();
    
    // Get attendance counts for each student
    const studentsWithAttendance = await Promise.all(
      students.map(async (student) => {
        const attendanceCount = await db.collection('shifts').aggregate([
          { $match: { status: 'closed' } },
          { $unwind: '$attendanceRecords' },
          { $match: { 'attendanceRecords.studentEmail': student.email } },
          { $count: 'total' }
        ]).toArray();
        
        return {
          id: student._id.toString(),
          fullName: student.fullName,
          email: student.email,
          phoneNumber: student.phoneNumber,
          college: student.college,
          grade: student.grade,
          major: student.major,
          attendanceCount: attendanceCount.length > 0 ? attendanceCount[0].total : 0,
          isActive: student.isActive,
          createdAt: student.createdAt
        };
      })
    );
    
    const total = await db.collection('students').countDocuments(query);
    
    return res.json({
      success: true,
      students: studentsWithAttendance,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
    
  } catch (error) {
    console.error('❌ Get students with attendance error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get student attendance history
router.get('/student-history/:email', async (req, res) => {
  try {
    const { email } = req.params;
    
    const db = await getDatabase();
    
    // Get all attendance records for student from closed shifts
    const attendanceRecords = await db.collection('shifts').aggregate([
      { $match: { status: 'closed' } },
      { $unwind: '$attendanceRecords' },
      { $match: { 'attendanceRecords.studentEmail': email.toLowerCase() } },
      { 
        $project: {
          studentName: '$attendanceRecords.studentName',
          studentEmail: '$attendanceRecords.studentEmail',
          college: '$attendanceRecords.college',
          scanTime: '$attendanceRecords.scanTime',
          status: '$attendanceRecords.status',
          supervisorName: '$supervisorName',
          shiftStart: '$shiftStart',
          shiftEnd: '$shiftEnd'
        }
      },
      { $sort: { scanTime: -1 } }
    ]).toArray();
    
    return res.json({
      success: true,
      attendanceRecords,
      totalCount: attendanceRecords.length
    });
    
  } catch (error) {
    console.error('❌ Get student attendance history error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;
