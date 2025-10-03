const express = require('express');
const { MongoClient } = require('mongodb');
const bcrypt = require('bcrypt');
const QRCode = require('qrcode');
const router = express.Router();

// Get database connection
const getDatabase = async () => {
  const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
  const dbName = process.env.MONGODB_DB_NAME || 'student_portal';
  const client = new MongoClient(mongoUri);
  await client.connect();
  return client.db(dbName);
};

// Register new student
router.post('/register', async (req, res) => {
  try {
    const { fullName, email, phoneNumber, college, grade, major, address } = req.body;
    
    console.log('📝 Student registration attempt:', { email, fullName });
    
    if (!fullName || !email || !phoneNumber || !college || !grade || !major) {
      return res.status(400).json({
        success: false,
        message: 'All required fields must be provided'
      });
    }

    const db = await getDatabase();
    
    // Check if student already exists
    const existingStudent = await db.collection('students').findOne({
      email: email.toLowerCase()
    });
    
    if (existingStudent) {
      return res.status(409).json({
        success: false,
        message: 'Student already exists with this email'
      });
    }
    
    // Create student data
    const studentData = {
      fullName,
      email: email.toLowerCase(),
      phoneNumber,
      college,
      grade,
      major,
      address: address || {},
      attendanceCount: 0,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    const result = await db.collection('students').insertOne(studentData);
    const studentId = result.insertedId.toString();
    
    // Generate QR Code
    const qrData = {
      studentId: studentId,
      email: email.toLowerCase(),
      fullName: fullName,
      timestamp: new Date().toISOString()
    };
    
    const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData));
    
    // Update student with QR code
    await db.collection('students').updateOne(
      { _id: result.insertedId },
      { $set: { qrCode: qrCodeDataURL, qrData: qrData } }
    );
    
    console.log('✅ Student registration successful:', email);
    
    return res.status(201).json({
      success: true,
      message: 'Student registered successfully',
      student: {
        id: studentId,
        ...studentData,
        qrCode: qrCodeDataURL
      }
    });
    
  } catch (error) {
    console.error('❌ Student registration error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get student data
router.get('/data', async (req, res) => {
  try {
    const { email } = req.query;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email parameter is required'
      });
    }

    const db = await getDatabase();
    const student = await db.collection('students').findOne({
      email: email.toLowerCase()
    });
    
    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found'
      });
    }
    
    return res.json({
      success: true,
      student: {
        id: student._id.toString(),
        fullName: student.fullName,
        email: student.email,
        phoneNumber: student.phoneNumber,
        college: student.college,
        grade: student.grade,
        major: student.major,
        address: student.address,
        attendanceCount: student.attendanceCount || 0,
        qrCode: student.qrCode,
        isActive: student.isActive,
        createdAt: student.createdAt,
        updatedAt: student.updatedAt,
        studentId: student.studentId  // Added studentId
      }
    });
    
  } catch (error) {
    console.error('❌ Get student data error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Update student data
router.put('/data', async (req, res) => {
  try {
    const { email, ...updateData } = req.body;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    const db = await getDatabase();
    
    // Update student data
    const result = await db.collection('students').updateOne(
      { email: email.toLowerCase() },
      { 
        $set: { 
          ...updateData, 
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
    
    // Get updated student data
    const updatedStudent = await db.collection('students').findOne({
      email: email.toLowerCase()
    });
    
    return res.json({
      success: true,
      message: 'Student data updated successfully',
      student: {
        id: updatedStudent._id.toString(),
        fullName: updatedStudent.fullName,
        email: updatedStudent.email,
        phoneNumber: updatedStudent.phoneNumber,
        college: updatedStudent.college,
        grade: updatedStudent.grade,
        major: updatedStudent.major,
        address: updatedStudent.address,
        attendanceCount: updatedStudent.attendanceCount || 0,
        qrCode: updatedStudent.qrCode,
        isActive: updatedStudent.isActive,
        createdAt: updatedStudent.createdAt,
        updatedAt: updatedStudent.updatedAt
      }
    });
    
  } catch (error) {
    console.error('❌ Update student data error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Generate QR Code for existing student
router.post('/generate-qr', async (req, res) => {
  try {
    const { email, studentData } = req.body;
    
    console.log('🔗 QR Generation request:', { email, studentData });
    
    // Extract email from different possible sources
    let studentEmail = null;
    if (email) {
      studentEmail = email;
    } else if (studentData) {
      studentEmail = studentData.email;
    }
    
    if (!studentEmail) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    const db = await getDatabase();
    const student = await db.collection('students').findOne({
      email: studentEmail.toLowerCase()
    });
    
    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found in database. Please complete registration first.'
      });
    }
    
    // Ensure student has a studentId
    if (!student.studentId) {
      // Generate studentId if missing
      const newStudentId = `STU-${Date.now()}`;
      await db.collection('students').updateOne(
        { _id: student._id },
        { $set: { studentId: newStudentId, updatedAt: new Date() } }
      );
      student.studentId = newStudentId;
    }
    
    // Generate new QR Code with comprehensive data
    const qrData = {
      studentId: student.studentId,  // Use STU-xxx format
      email: student.email,
      fullName: student.fullName,
      phoneNumber: student.phoneNumber || 'N/A',
      college: student.college || 'N/A',
      grade: student.grade || 'N/A',
      major: student.major || 'N/A',
      timestamp: new Date().toISOString()
    };
    
    const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData));
    
    // Update student with new QR code
    await db.collection('students').updateOne(
      { _id: student._id },
      { $set: { qrCode: qrCodeDataURL, qrData: qrData, updatedAt: new Date() } }
    );
    
    console.log('✅ QR code generated successfully for:', student.email);
    
    return res.json({
      success: true,
      message: 'QR Code generated successfully',
      qrCode: qrCodeDataURL,
      qrCodeDataURL: qrCodeDataURL,
      student: {
        id: student._id.toString(),
        fullName: student.fullName,
        email: student.email,
        phoneNumber: student.phoneNumber,
        college: student.college,
        studentId: student.studentId  // Added studentId
      }
    });
    
  } catch (error) {
    console.error('❌ Generate QR Code error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error: ' + error.message
    });
  }
});

// Get all students for admin
router.get('/all', async (req, res) => {
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
    
    const students = await db.collection('students')
      .find(query)
      .skip(skip)
      .limit(parseInt(limit))
      .toArray();
    
    const total = await db.collection('students').countDocuments(query);
    
    return res.json({
      success: true,
      students: students.map(student => ({
        id: student._id.toString(),
        fullName: student.fullName,
        email: student.email,
        phoneNumber: student.phoneNumber,
        college: student.college,
        grade: student.grade,
        major: student.major,
        attendanceCount: student.attendanceCount || 0,
        isActive: student.isActive,
        createdAt: student.createdAt
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
    
  } catch (error) {
    console.error('❌ Get all students error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// DELETE student by ID
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { getDatabase } = require('../lib/mongodb-simple-connection');
    const { ObjectId } = require('mongodb');
    
    const db = await getDatabase();
    
    // Get student first to get email
    const student = await db.collection('students').findOne({ _id: new ObjectId(id) });
    
    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found'
      });
    }
    
    // Delete student
    await db.collection('students').deleteOne({ _id: new ObjectId(id) });
    
    // Delete related data
    if (student.email) {
      await db.collection('users').deleteMany({ email: student.email });
      await db.collection('attendance').deleteMany({ studentEmail: student.email });
      await db.collection('subscriptions').deleteMany({ studentEmail: student.email });
    }
    
    return res.json({
      success: true,
      message: 'Student and related data deleted successfully'
    });
    
  } catch (error) {
    console.error('Error deleting student:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to delete student',
      error: error.message
    });
  }
});

module.exports = router;