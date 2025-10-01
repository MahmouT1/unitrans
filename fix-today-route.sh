#!/bin/bash

echo "🔧 إصلاح route /today ليستخدم MongoDB"
echo "========================================"
echo ""

cd /var/www/unitrans/backend-new/routes

# Backup
cp attendance.js attendance.js.backup_today_$(date +%Y%m%d_%H%M%S)

# إنشاء route جديد
cat > /tmp/new_today_route.js << 'NEWROUTE'

// Get today's attendance - using MongoDB directly
router.get('/today', authMiddleware, async (req, res) => {
  try {
    const db = req.app.locals.db;
    if (!db) {
      return res.status(500).json({ success: false, message: 'Database not connected' });
    }
    
    // Get today's date range
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    console.log('📅 Fetching attendance for:', today.toISOString(), 'to', tomorrow.toISOString());
    
    // Get today's attendance from MongoDB
    const todayAttendance = await db.collection('attendance').find({
      createdAt: { $gte: today, $lt: tomorrow }
    }).toArray();
    
    console.log('✅ Found', todayAttendance.length, 'records');
    
    // Calculate statistics
    const stats = {
      total: todayAttendance.length,
      present: todayAttendance.filter(a => a.status === 'present').length,
      late: todayAttendance.filter(a => a.status === 'late').length,
      absent: 0
    };
    
    return res.json({
      success: true,
      attendance: todayAttendance.map(a => ({
        id: a._id.toString(),
        studentId: a.studentId,
        studentEmail: a.studentEmail,
        studentName: a.studentName,
        shiftId: a.shiftId,
        college: a.college,
        grade: a.grade,
        status: a.status || 'present',
        scanTime: a.scanTime || a.createdAt,
        createdAt: a.createdAt
      })),
      stats
    });
    
  } catch (error) {
    console.error('❌ Today attendance error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

NEWROUTE

# حذف route القديم
sed -i '/router\.get.*\/today/,/^});$/d' attendance.js

# إضافة route الجديد بعد scan-qr
LINE=$(grep -n "router.post.*scan-qr" attendance.js | tail -1 | cut -d: -f1)
if [ -n "$LINE" ]; then
    # نجد نهاية route (});)
    END=$(awk -v start=$LINE 'NR > start && /^});$/ {print NR; exit}' attendance.js)
    
    # نضيف route الجديد بعده
    head -n $END attendance.js > /tmp/att_part1.js
    cat /tmp/new_today_route.js >> /tmp/att_part1.js
    tail -n +$((END + 1)) attendance.js >> /tmp/att_part1.js
    mv /tmp/att_part1.js attendance.js
    
    echo "✅ تم إضافة route /today الجديد"
else
    echo "❌ لم أجد scan-qr route"
    exit 1
fi

echo ""

# إعادة تشغيل
cd /var/www/unitrans
pm2 restart unitrans-backend
pm2 save

echo "✅ Backend تم إعادة تشغيله"
echo ""

sleep 3

# اختبار
echo "===================================="
echo "اختبار /today:"
echo "===================================="

TOKEN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')

curl -s "http://localhost:3001/api/attendance/today" \
  -H "Authorization: Bearer $TOKEN"

echo ""
echo ""
echo "✅ تم!"
