#!/bin/bash

echo "➕ إضافة route /all إلى students.js"
echo "======================================"
echo ""

cd /var/www/unitrans/backend-new/routes

# Backup
cp students.js students.js.backup_$(date +%Y%m%d_%H%M%S)
echo "✅ تم حفظ نسخة احتياطية"
echo ""

# إنشاء الـ route المطلوب في ملف مؤقت
cat > /tmp/new_route.txt << 'ENDROUTE'

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
    
    console.log(`✅ /all route - Found ${students.length} students (total: ${total})`);
    
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
        isActive: student.isActive !== undefined ? student.isActive : true,
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

ENDROUTE

# إضافة الـ route قبل السطر الأخير (module.exports)
# نحذف السطر الأخير، نضيف الـ route، ثم نضيف module.exports
head -n -1 students.js > students.js.tmp
cat /tmp/new_route.txt >> students.js.tmp
echo "module.exports = router;" >> students.js.tmp
mv students.js.tmp students.js

echo "✅ تم إضافة route /all"
echo ""

# التحقق
echo "التحقق:"
grep -n "router.get('/all'" students.js

echo ""
echo "عدد الأسطر:"
wc -l students.js

echo ""
echo "======================================"
echo "إعادة تشغيل Backend..."
echo "======================================"

cd /var/www/unitrans
pm2 restart unitrans-backend
pm2 save

echo ""
echo "انتظار 5 ثوان..."
sleep 5

echo ""
echo "======================================"
echo "اختبار Backend API:"
echo "======================================"

RESULT=$(curl -s http://localhost:3001/api/students/all?page=1&limit=3)
echo "$RESULT"

echo ""
echo ""

if echo "$RESULT" | grep -q '"success":true'; then
    echo "🎉 نجح! Backend يعمل!"
else
    echo "⚠️  لا يزال هناك مشكلة"
fi

echo ""
pm2 list
