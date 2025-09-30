const express = require('express');
const router = express.Router();
const { getDatabase } = require('../lib/mongodb-simple-connection');

// Get shifts
router.get('/', async (req, res) => {
  try {
    const { supervisorId, status, date, limit } = req.query;
    
    console.log('🔍 Getting shifts:', { supervisorId, status, date, limit });
    
    const db = await getDatabase();
    const shiftsCollection = db.collection('shifts');
    
    // Build query
    let query = {};
    
    if (supervisorId) {
      query.supervisorId = supervisorId;
    }
    
    // Filter by status
    if (status) {
      if (status === 'open') {
        // Only return shifts that are truly open (no shiftEnd)
        query.shiftEnd = null;
        query.status = { $ne: 'closed' };
      } else {
        query.status = status;
      }
    }
    
    if (date) {
      const targetDate = new Date(date);
      const startOfDay = new Date(targetDate);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(targetDate);
      endOfDay.setHours(23, 59, 59, 999);
      
      const dateQuery = {
        $or: [
          { shiftStart: { $gte: startOfDay, $lte: endOfDay } },
          { date: { $gte: startOfDay, $lte: endOfDay } }
        ]
      };
      
      if (query.$and) {
        query.$and.push(dateQuery);
      } else {
        query = { ...query, ...dateQuery };
      }
    }
    
    console.log('Final Query:', JSON.stringify(query, null, 2));
    
    // Get shifts from database
    const shifts = await shiftsCollection.find(query)
      .sort({ shiftStart: -1 })
      .limit(parseInt(limit) || 50)
      .toArray();
    
    console.log(`Found ${shifts.length} shifts`);
    
    res.json({
      success: true,
      shifts: shifts
    });
    
  } catch (error) {
    console.error('❌ Get shifts error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get shifts'
    });
  }
});

// Get active shifts
router.get('/active', async (req, res) => {
  try {
    const db = await getDatabase();
    const shiftsCollection = db.collection('shifts');
    
    // Find all active/open shifts
    const activeShifts = await shiftsCollection.find({ 
      status: { $in: ['active', 'open'] }
    }).sort({ shiftStart: -1 }).toArray();
    
    console.log(`Found ${activeShifts.length} active shifts`);
    
    res.json({
      success: true,
      shifts: activeShifts
    });
    
  } catch (error) {
    console.error('❌ Get active shifts error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get active shifts'
    });
  }
});

// Get shift attendance records
router.get('/:shiftId/attendance', async (req, res) => {
  try {
    const { shiftId } = req.params;
    
    console.log('📋 Getting attendance for shift:', shiftId);
    
    const db = await getDatabase();
    const attendanceCollection = db.collection('attendance');
    const shiftsCollection = db.collection('shifts');
    
    // Get shift details
    const shift = await shiftsCollection.findOne({ id: shiftId });
    if (!shift) {
      return res.status(404).json({
        success: false,
        message: 'Shift not found'
      });
    }
    
    // Get attendance records for this shift
    const attendanceRecords = await attendanceCollection.find({ 
      shiftId: shiftId 
    }).sort({ scanTime: -1 }).toArray();
    
    console.log(`Found ${attendanceRecords.length} attendance records for shift ${shiftId}`);
    
    res.json({
      success: true,
      shift: shift,
      attendance: attendanceRecords,
      count: attendanceRecords.length
    });
    
  } catch (error) {
    console.error('❌ Get shift attendance error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get shift attendance'
    });
  }
});

// Create new shift
router.post('/', async (req, res) => {
  try {
    const { supervisorId, supervisorName, supervisorEmail } = req.body;
    
    console.log('🔄 Creating new shift:', { supervisorId, supervisorName, supervisorEmail });
    
    const db = await getDatabase();
    const shiftsCollection = db.collection('shifts');
    
    const newShift = {
      id: Date.now().toString(),
      supervisorId,
      supervisorName: supervisorName || null,
      supervisorEmail: supervisorEmail || null,
      shiftStart: new Date(),
      startTime: new Date(), // Added for consistency
      status: 'open',
      createdAt: new Date(),
      totalScans: 0,
      attendanceRecords: [] // Initialize with empty array
    };
    
    // Save to database
    const result = await shiftsCollection.insertOne(newShift);
    console.log('✅ Shift created and saved to database:', result.insertedId);
    
    res.json({
      success: true,
      message: 'Shift opened successfully',
      shift: newShift
    });
    
  } catch (error) {
    console.error('❌ Create shift error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create shift'
    });
  }
});

// Close shift (PUT method)
router.put('/:shiftId/close', async (req, res) => {
  try {
    const { shiftId } = req.params;
    const { endTime, status } = req.body;
    
    console.log('🔄 Closing shift:', { shiftId, endTime, status });
    
    const db = await getDatabase();
    const shiftsCollection = db.collection('shifts');
    
    // Find the shift first
    const shift = await shiftsCollection.findOne({ id: shiftId });
    if (!shift) {
      return res.status(404).json({
        success: false,
        message: 'No open shift found with this ID'
      });
    }
    
    // Update shift status to closed
    const result = await shiftsCollection.updateOne(
      { id: shiftId },
      { 
        $set: { 
          status: status || 'closed',
          shiftEnd: new Date(endTime) || new Date(),
          endTime: new Date(endTime) || new Date(),
          updatedAt: new Date()
        }
      }
    );
    
    if (result.matchedCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Failed to update shift'
      });
    }
    
    console.log('✅ Shift closed successfully');
    
    res.json({
      success: true,
      message: 'Shift closed successfully',
      shift: {
        ...shift,
        status: status || 'closed',
        endTime: new Date(endTime) || new Date()
      }
    });
    
  } catch (error) {
    console.error('❌ Close shift error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to close shift',
      error: error.message
    });
  }
});

// Close shift (POST method for backward compatibility)
router.post('/close', async (req, res) => {
  try {
    const { shiftId, supervisorId } = req.body;
    
    console.log('🔄 Closing shift:', { shiftId, supervisorId });
    
    const db = await getDatabase();
    const shiftsCollection = db.collection('shifts');
    
    // Update shift status to closed
    const result = await shiftsCollection.updateOne(
      { id: shiftId },
      { 
        $set: { 
          status: 'closed',
          shiftEnd: new Date(),
          endTime: new Date()
        }
      }
    );
    
    if (result.matchedCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Shift not found'
      });
    }
    
    console.log('✅ Shift closed successfully');
    
    res.json({
      success: true,
      message: 'Shift closed successfully'
    });
    
  } catch (error) {
    console.error('❌ Close shift error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to close shift'
    });
  }
});

// Scan QR code
router.post('/scan', async (req, res) => {
  try {
    console.log('📱 QR Scan request body:', JSON.stringify(req.body, null, 2));
    
    const { qrCodeData, qrData, supervisorId, shiftId, location, notes } = req.body;
    const payload = qrCodeData || qrData;
    
    console.log('📱 QR Scan request:', { 
      hasPayload: !!payload, 
      payloadType: typeof payload,
      supervisorId, 
      shiftId,
      payload: payload
    });

    if (!payload || !shiftId) {
      return res.status(400).json({ success: false, message: 'Missing qrCodeData or shiftId' });
    }

    const db = await getDatabase();
    const shiftsCollection = db.collection('shifts');
    const attendanceCollection = db.collection('attendance');
    const studentsCollection = db.collection('students');
    const usersCollection = db.collection('users');

    const activeShift = await shiftsCollection.findOne({ id: shiftId, status: 'open' });
    if (!activeShift) {
      return res.status(400).json({ success: false, message: 'No active shift found with this ID.' });
    }

    // Parse QR data - handle both string and object formats
    let data = null;
    
    if (typeof payload === 'object') {
      // If payload is already an object, use it directly
      data = payload;
    } else if (typeof payload === 'string') {
      try {
        // Try to parse as JSON first
        data = JSON.parse(payload);
      } catch (parseError) {
        console.log('JSON parse failed, trying alternative parsing:', parseError.message);
        
        // If JSON parsing fails, try to extract data from string patterns
        if (payload.includes('email') && payload.includes('studentId')) {
          // Try to extract email and studentId from string
          const emailMatch = payload.match(/email[:\s]*([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/i);
          const studentIdMatch = payload.match(/studentId[:\s]*([A-Z0-9]+)/i);
          
          if (emailMatch || studentIdMatch) {
            data = {};
            if (emailMatch) data.email = emailMatch[1];
            if (studentIdMatch) data.studentId = studentIdMatch[1];
          }
        } else if (/^STU-\d+$/.test(payload) || /^\d+$/.test(payload)) {
          data = { studentId: payload };
        } else {
          // Try to clean and parse the string
          const cleanedPayload = payload.replace(/\\/g, '').replace(/"/g, '"');
          try {
            data = JSON.parse(cleanedPayload);
          } catch (e) {
            console.log('All parsing attempts failed');
          }
        }
      }
    }
    
    console.log('📱 Parsed QR data:', data);
    
    if (!data || (!data.email && !data.studentId)) {
      return res.status(400).json({ success: false, message: 'Invalid QR code data format. Missing email or studentId.' });
    }

    // Locate student by email or studentId
    let student = null;
    if (data.email) student = await studentsCollection.findOne({ email: data.email.toLowerCase() });
    if (!student && data.studentId) student = await studentsCollection.findOne({ studentId: data.studentId });
    if (!student && data.email) student = await usersCollection.findOne({ email: data.email.toLowerCase(), role: 'student' });

    if (!student) {
      return res.status(404).json({ success: false, message: 'Student not found in the system.' });
    }

    // Prevent duplicates within current shift
    const duplicate = await attendanceCollection.findOne({
      shiftId: activeShift.id,
      studentEmail: (student.email || data.email || '').toLowerCase(),
      scanTime: { $gte: new Date(activeShift.shiftStart) }
    });
    if (duplicate) {
      return res.status(409).json({ success: false, message: 'Student already scanned for this shift.' });
    }

    const attendanceRecord = {
      shiftId: activeShift.id,
      supervisorId: supervisorId || activeShift.supervisorId,
      studentId: student.studentId || (student._id ? student._id.toString() : ''),
      studentName: student.fullName || student.name || data.fullName || data.name || 'Student',
      studentEmail: (student.email || data.email || '').toLowerCase(),
      // Add complete student data from QR code or database
      college: student.college || data.college || 'N/A',
      major: student.major || data.major || 'N/A', 
      grade: student.grade || data.grade || 'N/A',
      phoneNumber: student.phoneNumber || data.phoneNumber || 'N/A',
      address: student.address || data.address || 'N/A',
      academicYear: student.academicYear || data.academicYear || 'N/A',
      scanTime: new Date(),
      location: location || 'Unknown',
      notes: notes || 'QR Scan',
      status: 'Present',
      qrData: data, // Store original QR data
      createdAt: new Date()
    };

    await attendanceCollection.insertOne(attendanceRecord);
    await shiftsCollection.updateOne(
      { id: activeShift.id },
      { $inc: { totalScans: 1 }, $push: { attendanceRecords: attendanceRecord } }
    );
    
    // تحديث عدد أيام الحضور للطالب
    await studentsCollection.updateOne(
      { email: attendanceRecord.studentEmail },
      { $inc: { attendanceCount: 1 } }
    );

    console.log('✅ Attendance registered successfully for:', attendanceRecord.studentName);
    
    return res.json({ 
      success: true, 
      message: 'Attendance registered successfully', 
      attendance: attendanceRecord, 
      studentData: {
        id: student._id ? student._id.toString() : undefined,
        fullName: attendanceRecord.studentName,
        studentId: attendanceRecord.studentId,
        email: attendanceRecord.studentEmail,
        college: attendanceRecord.college,
        major: attendanceRecord.major,
        grade: attendanceRecord.grade,
        phoneNumber: attendanceRecord.phoneNumber,
        address: attendanceRecord.address,
        academicYear: attendanceRecord.academicYear
      }
    });
  } catch (error) {
    console.error('❌ QR Scan error:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to process QR scan', 
      error: error.message,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

module.exports = router;
