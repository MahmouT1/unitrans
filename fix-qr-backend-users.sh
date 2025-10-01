#!/bin/bash

echo "🔧 إصلاح Backend ليبحث في users أيضاً"
echo "=========================================="
echo ""

cd /var/www/unitrans/backend-new/routes

# Backup
cp students.js students.js.backup_qr_$(date +%Y%m%d_%H%M%S)

# تعديل generate-qr route ليبحث في users أيضاً
cat > /tmp/new_qr_route.js << 'ENDROUTE'

// Generate QR Code - Search in both students and users collections
router.post('/generate-qr', async (req, res) => {
  try {
    const { email, studentData } = req.body;
    
    console.log('🔗 QR Generation request:', { email, studentData });
    
    // Extract email
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
    
    // البحث في students أولاً
    let student = await db.collection('students').findOne({
      email: studentEmail.toLowerCase()
    });
    
    // إذا لم يوجد، ابحث في users
    if (!student) {
      const user = await db.collection('users').findOne({
        email: studentEmail.toLowerCase()
      });
      
      if (user) {
        // استخدم بيانات user لإنشاء QR
        student = {
          _id: user._id,
          fullName: user.fullName || user.name,
          email: user.email,
          phoneNumber: user.phoneNumber || user.phone || 'N/A',
          college: user.college || 'N/A',
          grade: user.grade || user.academicYear || 'N/A',
          major: user.major || 'N/A'
        };
        
        console.log('✅ Found in users collection');
      }
    } else {
      console.log('✅ Found in students collection');
    }
    
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
      phoneNumber: student.phoneNumber || 'N/A',
      college: student.college || 'N/A',
      grade: student.grade || 'N/A',
      major: student.major || 'N/A',
      timestamp: new Date().toISOString()
    };
    
    const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData));
    
    // حفظ QR في students collection (إذا لم يكن موجود)
    const studentInStudents = await db.collection('students').findOne({ email: studentEmail.toLowerCase() });
    if (!studentInStudents) {
      // إنشاء سجل في students
      await db.collection('students').insertOne({
        ...student,
        qrCode: qrCodeDataURL,
        qrData: qrData,
        createdAt: new Date(),
        updatedAt: new Date()
      });
    } else {
      // تحديث QR
      await db.collection('students').updateOne(
        { _id: student._id },
        { $set: { qrCode: qrCodeDataURL, qrData: qrData, updatedAt: new Date() } }
      );
    }
    
    console.log('✅ QR code generated for:', student.email);
    
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
        college: student.college
      }
    });
    
  } catch (error) {
    console.error('❌ Generate QR error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error: ' + error.message
    });
  }
});

ENDROUTE

# استبدال الـ route القديم
# نحذف من // Generate QR Code لحد نهاية الـ route
sed -i '/\/\/ Generate QR Code for existing student/,/^});/d' students.js

# نضيف الـ route الجديد قبل // Get all students
LINE=$(grep -n "// Get all students for admin" students.js | cut -d: -f1)
head -n $((LINE - 1)) students.js > students.js.tmp
cat /tmp/new_qr_route.js >> students.js.tmp
tail -n +$LINE students.js >> students.js.tmp
mv students.js.tmp students.js

echo "✅ تم تحديث generate-qr route"
echo ""

# إعادة تشغيل Backend
cd /var/www/unitrans
pm2 restart unitrans-backend
pm2 save

echo ""
echo "انتظار 3 ثوان..."
sleep 3

echo ""
echo "=========================================="
echo "اختبار Backend:"
curl -X POST http://localhost:3001/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com"}'

echo ""
echo ""
echo "=========================================="
echo "✅ تم! جرب في المتصفح الآن"
echo "=========================================="

pm2 list
