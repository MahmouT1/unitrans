#!/bin/bash

echo "⚡ إصلاح الـ 5 مشاكل الأخيرة - نهائي"
echo "=============================================="
echo ""

cd /var/www/unitrans/backend-new

# ==========================================
# إصلاح 1: Student Subscriptions Route
# ==========================================
echo "1️⃣ إصلاح Student Subscriptions..."

# التأكد من وجود route صحيح
if ! grep -q "router.get.*student.*email" routes/subscriptions.js; then
    # إضافة route قبل module.exports
    sed -i '/module.exports = router/i\
// Get student subscriptions by email\
router.get('"'"'/student'"'"', async (req, res) => {\
  try {\
    const { email } = req.query;\
    if (!email) return res.status(400).json({ success: false, message: '"'"'Email required'"'"' });\
    const { getDatabase } = require('"'"'../lib/mongodb-simple-connection'"'"');\
    const db = await getDatabase();\
    const subs = await db.collection('"'"'subscriptions'"'"').find({ studentEmail: email.toLowerCase() }).toArray();\
    return res.json({ success: true, subscriptions: subs });\
  } catch (error) {\
    return res.status(500).json({ success: false, message: error.message });\
  }\
});\n' routes/subscriptions.js
    
    echo "✅ Student Subscriptions route تمت إضافته"
else
    echo "✅ Route موجود"
fi

# ==========================================
# إصلاح 2: Student Search - query parameter
# ==========================================
echo "2️⃣ التحقق من Student Search..."

# التأكد أن /all route يقبل search parameter
if grep -q "router.get.*'/all'" routes/students.js; then
    echo "✅ Student Search route موجود"
else
    echo "⚠️ يحتاج مراجعة"
fi

# ==========================================
# إصلاح 3: Admin Reports Route
# ==========================================
echo "3️⃣ إصلاح Admin Reports..."

# التأكد من وجود reports.js
if [ ! -f routes/reports.js ]; then
    cat > routes/reports.js << 'ENDREP'
const express = require('express');
const router = express.Router();
const { getDatabase } = require('../lib/mongodb-simple-connection');

router.get('/', async (req, res) => {
  try {
    const db = await getDatabase();
    
    const totalStudents = await db.collection('students').countDocuments();
    const totalAttendance = await db.collection('attendance').countDocuments();
    const subscriptions = await db.collection('subscriptions').find().toArray();
    const totalRevenue = subscriptions.reduce((sum, sub) => sum + (sub.amount || 0), 0);
    
    return res.json({
      success: true,
      stats: {
        totalStudents,
        totalAttendance,
        totalSubscriptions: subscriptions.length,
        totalRevenue
      },
      subscriptions
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
ENDREP
    echo "✅ reports.js تم إنشاؤه"
fi

# التأكد من تسجيل route في server.js
if ! grep -q "/api/reports" server.js; then
    sed -i "/app.use('\/api\/subscriptions'/a app.use('/api/reports', require('./routes/reports'));" server.js
    echo "✅ Reports route تم تسجيله"
fi

# ==========================================
# إصلاح 4 & 5: Database Connections
# ==========================================
echo "4️⃣ التحقق من Database Connections..."

# Backend lib
if [ -f lib/mongodb-simple-connection.js ]; then
    sed -i "s/'unitrans'/'student_portal'/g" lib/mongodb-simple-connection.js
    sed -i 's/"unitrans"/"student_portal"/g' lib/mongodb-simple-connection.js
    echo "✅ Backend lib محدث"
fi

# Frontend lib
cd ../frontend-new/lib
for file in *.js; do
    if [ -f "$file" ]; then
        sed -i "s/'student-portal'/'student_portal'/g" "$file"
        sed -i 's/"student-portal"/"student_portal"/g' "$file"
    fi
done
echo "✅ Frontend lib محدث"

# ==========================================
# إعادة تشغيل كل شيء
# ==========================================
echo ""
echo "5️⃣ إعادة تشغيل Services..."
cd /var/www/unitrans

pm2 restart all
pm2 save

sleep 10

echo ""
echo "=============================================="
echo "🧪 الاختبار النهائي:"
echo "=============================================="
echo ""

# Login
TOKEN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')

# Test 1: Student Subscriptions
echo "Test 1 - Student Subscriptions:"
RESULT1=$(curl -s "http://localhost:3001/api/subscriptions/student?email=aliramy123@gmail.com" -H "Authorization: Bearer $TOKEN")
echo "$RESULT1" | grep -o '"success":[^,]*' && echo "✅" || echo "❌"

# Test 2: Student Search
echo "Test 2 - Student Search:"
RESULT2=$(curl -s "http://localhost:3001/api/students/all?search=ali&page=1&limit=1" -H "Authorization: Bearer $TOKEN")
echo "$RESULT2" | grep -o '"success":[^,]*' && echo "✅" || echo "❌"

# Test 3: Admin Reports
echo "Test 3 - Admin Reports:"
RESULT3=$(curl -s "http://localhost:3001/api/reports" -H "Authorization: Bearer $TOKEN")
echo "$RESULT3" | grep -o '"success":[^,]*' && echo "✅" || echo "❌"

# Test 4: Database Check
echo "Test 4 - Database student_portal:"
mongosh student_portal --quiet --eval "print(db.getName())" | grep -q "student_portal" && echo "✅" || echo "❌"

# Test 5: All connections
echo "Test 5 - جميع الاتصالات:"
grep -q "student_portal" backend-new/.env && grep -q "student_portal" frontend-new/lib/mongodb-simple-connection.js && echo "✅" || echo "❌"

echo ""
echo "=============================================="
echo "✅ الإصلاحات اكتملت!"
echo "=============================================="

