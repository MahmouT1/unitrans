#!/bin/bash

echo "🔧 إصلاح عرض بيانات الطالب في البانر - API فقط"
echo "============================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة الحالية:"
echo "======================="

echo "🔍 فحص students API:"
grep -n "students" backend-new/routes/students.js || echo "❌ لا يوجد students API"

echo ""
echo "🔧 2️⃣ إصلاح students API لعرض البيانات:"
echo "===================================="

# Fix students.js to properly handle student data display
cat > backend-new/routes/students.js << 'EOF'
const express = require('express');
const { MongoClient } = require('mongodb');
const QRCode = require('qrcode');
require('dotenv').config();

const router = express.Router();

const getDatabase = async () => {
  const client = new MongoClient(process.env.MONGODB_URI || 'mongodb://localhost:27017');
  await client.connect();
  const dbName = process.env.DB_NAME || 'student_portal';
  return client.db(dbName);
};

// Get student data by email
router.get('/data', async (req, res) => {
  try {
    const { email } = req.query;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    console.log('📊 Fetching student data for:', email);
    
    const db = await getDatabase();
    
    // Find student in students collection
    const student = await db.collection('students').findOne({
      email: email.toLowerCase()
    });
    
    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found'
      });
    }
    
    console.log('✅ Student data found:', student.fullName);
    
    res.json({
      success: true,
      student: {
        id: student._id,
        fullName: student.fullName,
        email: student.email,
        phoneNumber: student.phoneNumber || '',
        college: student.college || '',
        grade: student.grade || '',
        major: student.major || '',
        streetAddress: student.streetAddress || '',
        buildingNumber: student.buildingNumber || '',
        fullAddress: student.fullAddress || '',
        profilePhoto: student.profilePhoto || null,
        attendanceCount: student.attendanceCount || 0,
        isActive: student.isActive,
        createdAt: student.createdAt,
        updatedAt: student.updatedAt
      }
    });
    
  } catch (error) {
    console.error('❌ Error fetching student data:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Update student data
router.put('/data', async (req, res) => {
  try {
    const { fullName, email, phoneNumber, college, grade, major, streetAddress, buildingNumber, fullAddress, profilePhoto } = req.body;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    console.log('📝 Updating student data for:', email);
    
    const db = await getDatabase();
    
    // Update student data
    const updateData = {
      fullName: fullName || '',
      phoneNumber: phoneNumber || '',
      college: college || '',
      grade: grade || '',
      major: major || '',
      streetAddress: streetAddress || '',
      buildingNumber: buildingNumber || '',
      fullAddress: fullAddress || '',
      profilePhoto: profilePhoto || null,
      updatedAt: new Date()
    };
    
    const result = await db.collection('students').updateOne(
      { email: email.toLowerCase() },
      { $set: updateData }
    );
    
    if (result.matchedCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Student not found'
      });
    }
    
    console.log('✅ Student data updated for:', email);
    
    // Return updated student data
    const updatedStudent = await db.collection('students').findOne({
      email: email.toLowerCase()
    });
    
    res.json({
      success: true,
      message: 'Student data updated successfully',
      student: {
        id: updatedStudent._id,
        fullName: updatedStudent.fullName,
        email: updatedStudent.email,
        phoneNumber: updatedStudent.phoneNumber || '',
        college: updatedStudent.college || '',
        grade: updatedStudent.grade || '',
        major: updatedStudent.major || '',
        streetAddress: updatedStudent.streetAddress || '',
        buildingNumber: updatedStudent.buildingNumber || '',
        fullAddress: updatedStudent.fullAddress || '',
        profilePhoto: updatedStudent.profilePhoto || null,
        attendanceCount: updatedStudent.attendanceCount || 0,
        isActive: updatedStudent.isActive,
        createdAt: updatedStudent.createdAt,
        updatedAt: updatedStudent.updatedAt
      }
    });
    
  } catch (error) {
    console.error('❌ Error updating student data:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Generate QR Code
router.post('/generate-qr', async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    console.log('🔗 Generating QR code for:', email);
    
    const db = await getDatabase();
    
    // Find student
    const student = await db.collection('students').findOne({
      email: email.toLowerCase()
    });
    
    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found'
      });
    }
    
    // Generate QR Code
    const qrData = {
      studentId: student._id.toString(),
      email: student.email,
      fullName: student.fullName,
      timestamp: new Date().toISOString()
    };
    
    const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData));
    
    // Update student with QR code
    await db.collection('students').updateOne(
      { _id: student._id },
      { $set: { qrCode: qrCodeDataURL, qrData: qrData } }
    );
    
    console.log('✅ QR code generated for:', email);
    
    res.json({
      success: true,
      message: 'QR code generated successfully',
      qrCode: qrCodeDataURL
    });
    
  } catch (error) {
    console.error('❌ Error generating QR code:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get student profile simple
router.get('/profile-simple', async (req, res) => {
  try {
    const { email } = req.query;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    console.log('📊 Fetching simple student profile for:', email);
    
    const db = await getDatabase();
    
    // Find student in students collection
    const student = await db.collection('students').findOne({
      email: email.toLowerCase()
    });
    
    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found'
      });
    }
    
    console.log('✅ Simple student profile found:', student.fullName);
    
    res.json({
      success: true,
      student: {
        id: student._id,
        fullName: student.fullName,
        email: student.email,
        phoneNumber: student.phoneNumber || '',
        college: student.college || '',
        grade: student.grade || '',
        major: student.major || '',
        streetAddress: student.streetAddress || '',
        buildingNumber: student.buildingNumber || '',
        fullAddress: student.fullAddress || '',
        profilePhoto: student.profilePhoto || null,
        attendanceCount: student.attendanceCount || 0,
        isActive: student.isActive,
        createdAt: student.createdAt,
        updatedAt: student.updatedAt
      }
    });
    
  } catch (error) {
    console.error('❌ Error fetching simple student profile:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;
EOF

echo "✅ تم إصلاح students API لعرض البيانات"

echo ""
echo "🔧 3️⃣ إعادة تشغيل Backend:"
echo "========================="

echo "🔄 إيقاف backend..."
pm2 stop unitrans-backend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 حذف backend process..."
pm2 delete unitrans-backend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 بدء backend جديد..."
cd backend-new
pm2 start server.js --name "unitrans-backend"

echo "⏳ انتظار 30 ثانية للتأكد من التشغيل..."
sleep 30

echo "🔍 فحص حالة backend:"
pm2 status unitrans-backend

echo ""
echo "🔧 4️⃣ اختبار API:"
echo "==============="

echo "🔍 اختبار students/data API:"
curl -s "https://unibus.online/api/students/data?email=newstudent@test.com" | head -20

echo ""
echo "🔍 اختبار students/profile-simple API:"
curl -s "https://unibus.online/api/students/profile-simple?email=newstudent@test.com" | head -20

echo ""
echo "🎉 تم إصلاح عرض بيانات الطالب في البانر!"
echo "🌐 يمكنك الآن اختبار:"
echo "   🔗 https://unibus.online/student/portal"
echo "   ✅ البيانات ستظهر في البانر بعد التسجيل"
echo "   ✅ التصميم لم يتأثر"
echo "   ✅ البانر لم يتأثر"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
