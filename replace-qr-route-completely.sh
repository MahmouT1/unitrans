#!/bin/bash

echo "🔄 استبدال كامل لـ generate-qr route"
echo "====================================="
echo ""

cd /var/www/unitrans/backend-new/routes

# Backup شامل
cp students.js students.js.full_backup_$(date +%Y%m%d_%H%M%S)

# حذف جميع generate-qr routes القديمة
# نحذف من أول router.post('/generate-qr' إلى نهايته
sed -i '/router\.post.*generate-qr/,/^});$/d' students.js

# الآن نضيف الـ route الجديد قبل Get all students
# نجد رقم السطر
LINE=$(grep -n "// Get all students for admin" students.js | head -1 | cut -d: -f1)

if [ -z "$LINE" ]; then
    echo "❌ لم أجد '// Get all students'"
    exit 1
fi

# نقسم الملف
head -n $((LINE - 1)) students.js > /tmp/students_part1.js

tail -n +$LINE students.js > /tmp/students_part2.js

# نكتب الـ route الجديد
cat > /tmp/new_generate_qr.js << 'NEWROUTE'
// Generate QR Code - Search in both students and users collections
router.post('/generate-qr', async (req, res) => {
  try {
    const { email, studentData } = req.body;
    
    console.log('🔗 QR request:', { email, hasStudentData: !!studentData });
    
    // Extract email
    let studentEmail = email;
    if (!studentEmail && studentData) {
      studentEmail = studentData.email;
    }
    
    if (!studentEmail) {
      console.log('❌ No email provided');
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
      console.log('🔍 Not in students, checking users...');
      const user = await db.collection('users').findOne({
        email: studentEmail.toLowerCase()
      });
      
      if (user) {
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
      console.log('❌ Student not found in any collection');
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
    
    console.log('✅ QR generated for:', student.email);
    
    return res.json({
      success: true,
      message: 'QR Code generated successfully',
      qrCode: qrCodeDataURL,
      qrCodeDataURL: qrCodeDataURL,
      student: {
        id: student._id.toString(),
        fullName: student.fullName,
        email: student.email
      }
    });
    
  } catch (error) {
    console.error('❌ QR error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error: ' + error.message
    });
  }
});

NEWROUTE

# دمج الملفات
cat /tmp/students_part1.js > students.js
cat /tmp/new_generate_qr.js >> students.js
cat /tmp/students_part2.js >> students.js

echo "✅ تم استبدال generate-qr route"
echo ""

# التحقق
echo "التحقق:"
grep -n "Search in both" students.js
echo "عدد الأسطر:"
wc -l students.js

echo ""

# إعادة تشغيل Backend
cd /var/www/unitrans
pm2 restart unitrans-backend
pm2 save

echo ""
echo "انتظار 3 ثوان..."
sleep 3

echo ""
echo "====================================="
echo "اختبار Backend:"
curl -X POST http://localhost:3001/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentData":{"email":"mahmoudtarekmonaim@gmail.com"}}'

echo ""
echo ""
echo "====================================="
echo "✅ تم!"
echo "====================================="

pm2 list
