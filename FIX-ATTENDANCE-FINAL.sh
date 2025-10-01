#!/bin/bash

echo "🔧 الحل النهائي لـ Attendance"
echo "=============================="
echo ""

cd /var/www/unitrans/backend-new/routes

# Backup
cp attendance.js attendance.js.backup_final_$(date +%Y%m%d_%H%M%S)

# إنشاء route جديد مبسط
cat > /tmp/new_scan_qr.js << 'NEWROUTE'

// Simplified scan-qr route
router.post('/scan-qr', authMiddleware, async (req, res) => {
  try {
    console.log('🔍 Scan QR request:', req.body);
    
    const { qrData, shiftId, studentEmail, studentName, studentId } = req.body;
    
    // Parse qrData if it's a string
    let studentData;
    if (typeof qrData === 'string') {
      try {
        studentData = JSON.parse(qrData);
      } catch (e) {
        console.log('❌ QR parse error:', e.message);
        return res.status(400).json({ success: false, message: 'Invalid QR format' });
      }
    } else if (qrData && typeof qrData === 'object') {
      studentData = qrData;
    } else {
      // استخدام البيانات المرسلة مباشرة
      studentData = {
        studentId: studentId || req.body.studentId,
        email: studentEmail || req.body.email,
        fullName: studentName || req.body.fullName
      };
    }
    
    console.log('✅ Student data:', studentData);
    
    // الحصول على database
    const db = req.app.locals.db;
    if (!db) {
      return res.status(500).json({ success: false, message: 'Database not connected' });
    }
    
    // تسجيل الحضور
    const attendanceRecord = {
      studentId: studentData.studentId || studentData.id,
      studentEmail: studentData.email || studentEmail,
      studentName: studentData.fullName || studentName,
      shiftId: shiftId,
      supervisorId: req.user.id || req.user._id,
      scanTime: new Date(),
      college: studentData.college || req.body.college || 'N/A',
      grade: studentData.grade || req.body.grade || 'N/A',
      major: studentData.major || req.body.major || 'N/A',
      status: 'present',
      createdAt: new Date()
    };
    
    // حفظ في database
    const result = await db.collection('attendance').insertOne(attendanceRecord);
    
    console.log('✅ Attendance registered:', result.insertedId);
    
    // تحديث Shift - زيادة scannedCount
    if (shiftId) {
      await db.collection('shifts').updateOne(
        { _id: shiftId },
        { $inc: { scannedCount: 1 }, $push: { attendanceRecords: result.insertedId } }
      );
    }
    
    return res.json({
      success: true,
      message: 'Attendance registered successfully',
      attendance: {
        id: result.insertedId.toString(),
        ...attendanceRecord
      }
    });
    
  } catch (error) {
    console.error('❌ Scan QR error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error: ' + error.message
    });
  }
});

NEWROUTE

# استبدال route القديم
# نحذف من router.post('/scan-qr' لحد نهاية route
sed -i '/router\.post.*scan-qr/,/^});$/d' attendance.js

# نضيف route الجديد في البداية (بعد imports)
LINE=$(grep -n "const router = express.Router();" attendance.js | cut -d: -f1)
head -n $LINE attendance.js > /tmp/attendance_part1.js
cat /tmp/new_scan_qr.js >> /tmp/attendance_part1.js
tail -n +$((LINE + 1)) attendance.js >> /tmp/attendance_part1.js
mv /tmp/attendance_part1.js attendance.js

echo "✅ تم استبدال scan-qr route"
echo ""

# إعادة تشغيل Backend
cd /var/www/unitrans

pm2 restart unitrans-backend
pm2 save

echo "✅ Backend تم إعادة تشغيله"
echo ""

sleep 3

# اختبار
echo "===================================="
echo "اختبار Scan QR:"
echo "===================================="

# Login
TOKEN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')

# Scan
curl -s -X POST http://localhost:3001/api/attendance/scan-qr \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "studentEmail":"mahmoudtarekmonaim@gmail.com",
    "studentName":"mahmoud tarek",
    "studentId":"68d0886b0362753dc7fd1b36",
    "shiftId":"68dd4f4f1u4c286b08bec4e8",
    "college":"bis",
    "grade":"third-year"
  }'

echo ""
echo ""
echo "✅ تم!"
