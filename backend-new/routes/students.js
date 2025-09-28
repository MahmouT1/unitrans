const express = require('express');
const { MongoClient } = require('mongodb');
const bcrypt = require('bcryptjs');
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
        updatedAt: student.updatedAt
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
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
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
    
    // Generate new QR Code
    const qrData = {
      studentId: student._id.toString(),
      email: student.email,
      fullName: student.fullName,
      timestamp: new Date().toISOString()
    };
    
    const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData));
    
    // Update student with new QR code
    await db.collection('students').updateOne(
      { _id: student._id },
      { $set: { qrCode: qrCodeDataURL, qrData: qrData } }
    );
    
    return res.json({
      success: true,
      message: 'QR Code generated successfully',
      qrCode: qrCodeDataURL,
      qrData: qrData
    });
    
  } catch (error) {
    console.error('❌ Generate QR Code error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
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

module.exports = router;