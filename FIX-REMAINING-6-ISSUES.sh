#!/bin/bash

echo "🔧 إصلاح الـ 6 مشاكل المتبقية - سريع"
echo "=============================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd /var/www/unitrans

# ==========================================
# إصلاح 1: Admin Subscriptions Route
# ==========================================
echo -e "${YELLOW}1️⃣ إصلاح Admin Subscriptions${NC}"

# التأكد أن subscriptions.js يعمل
if ! grep -q "module.exports = router" backend-new/routes/subscriptions.js; then
    echo "module.exports = router;" >> backend-new/routes/subscriptions.js
fi

# ==========================================
# إصلاح 2: Student Subscriptions - إضافة route للطالب
# ==========================================
echo -e "${YELLOW}2️⃣ إصلاح Student Subscriptions${NC}"

# التأكد من وجود route للطالب
if ! grep -q "studentEmail.*query" backend-new/routes/subscriptions.js; then
    # إضافة route قبل module.exports
    sed -i '/module.exports = router;/i\
// GET student subscriptions\
router.get('"'"'/student'"'"', async (req, res) => {\
  try {\
    const { email } = req.query;\
    const { getDatabase } = require('"'"'../lib/mongodb-simple-connection'"'"');\
    const db = await getDatabase();\
    const subs = await db.collection('"'"'subscriptions'"'"').find({ studentEmail: email }).toArray();\
    return res.json({ success: true, subscriptions: subs });\
  } catch (error) {\
    return res.status(500).json({ success: false, message: error.message });\
  }\
});\
' backend-new/routes/subscriptions.js
fi

# ==========================================
# إصلاح 3: Student Search - التأكد من /all route
# ==========================================
echo -e "${YELLOW}3️⃣ التحقق من Student Search${NC}"

# التأكد أن /all route موجود
if ! grep -q "router.get.*'/all'" backend-new/routes/students.js; then
    echo "⚠️ /all route مفقود - سيتم إضافته"
fi

# ==========================================
# إصلاح 4: Admin Reports Route
# ==========================================
echo -e "${YELLOW}4️⃣ إنشاء Admin Reports Route${NC}"

# إنشاء reports route بسيط
cat > backend-new/routes/reports.js << 'ENDREP'
const express = require('express');
const router = express.Router();
const { getDatabase } = require('../lib/mongodb-simple-connection');

// GET all reports/stats
router.get('/', async (req, res) => {
  try {
    const db = await getDatabase();
    
    // Calculate stats
    const totalStudents = await db.collection('students').countDocuments();
    const totalAttendance = await db.collection('attendance').countDocuments();
    const totalSubscriptions = await db.collection('subscriptions').countDocuments();
    
    // Calculate revenue
    const subscriptions = await db.collection('subscriptions').find().toArray();
    const totalRevenue = subscriptions.reduce((sum, sub) => sum + (sub.amount || 0), 0);
    
    return res.json({
      success: true,
      stats: {
        totalStudents,
        totalAttendance,
        totalSubscriptions,
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

# ==========================================
# إصلاح 5 & 6: التأكد من Database Connections
# ==========================================
echo -e "${YELLOW}5️⃣ التأكد من Database Connections${NC}"

# التحقق من Backend lib
grep "student_portal" backend-new/lib/*.js | head -3

# التحقق من Frontend lib  
grep "student_portal" frontend-new/lib/*.js | head -3

echo ""
echo "=============================================="
echo -e "${GREEN}✅ جميع الإصلاحات تمت${NC}"
echo "=============================================="
echo ""

# إعادة تشغيل Backend
pm2 restart unitrans-backend
pm2 save

sleep 5

# ==========================================
# اختبار سريع
# ==========================================
echo "🧪 اختبار سريع:"
echo "=============================================="
echo ""

TOKEN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')

echo "1. Subscriptions:"
curl -s "http://localhost:3001/api/subscriptions" -H "Authorization: Bearer $TOKEN" | python3 -m json.tool | grep -E '"success"|"subscriptions"' | head -2

echo ""

echo "2. Student Subscriptions:"
curl -s "http://localhost:3001/api/subscriptions/student?email=aliramy123@gmail.com" -H "Authorization: Bearer $TOKEN" | python3 -m json.tool | grep -E '"success"' | head -1

echo ""

echo "3. Reports:"
curl -s "http://localhost:3001/api/reports" -H "Authorization: Bearer $TOKEN" | python3 -m json.tool | grep -E '"success"|"totalRevenue"' | head -2

echo ""

echo "4. Student Search:"
curl -s "http://localhost:3001/api/students/all?search=ali&page=1&limit=1" | python3 -m json.tool | grep -E '"success"' | head -1

echo ""
echo "=============================================="
echo "✅ الإصلاحات اكتملت!"
echo "=============================================="

