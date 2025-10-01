#!/bin/bash

echo "📦 نقل Shifts و Attendance إلى student_portal"
echo "================================================"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "===================================="
echo -e "${YELLOW}1️⃣  نسخ البيانات${NC}"
echo "===================================="

mongosh --quiet --eval "
// نسخ من unitrans إلى student_portal
var sourceDb = db.getSiblingDB('unitrans');
var targetDb = db.getSiblingDB('student_portal');

// نسخ shifts
print('نسخ shifts...');
var shifts = sourceDb.shifts.find().toArray();
if (shifts.length > 0) {
    targetDb.shifts.insertMany(shifts);
    print('✅ تم نسخ ' + shifts.length + ' shift');
} else {
    print('⚠️  لا توجد shifts للنسخ');
}

print('');

// نسخ attendance
print('نسخ attendance...');
var attendance = sourceDb.attendance.find().toArray();
if (attendance.length > 0) {
    targetDb.attendance.insertMany(attendance);
    print('✅ تم نسخ ' + attendance.length + ' attendance record');
} else {
    print('⚠️  لا توجد attendance للنسخ');
}

print('');
print('النتيجة:');
print('========');
print('student_portal → shifts: ' + targetDb.shifts.countDocuments());
print('student_portal → attendance: ' + targetDb.attendance.countDocuments());
"

echo ""
echo "===================================="
echo -e "${YELLOW}2️⃣  إعادة تشغيل Backend${NC}"
echo "===================================="

pm2 restart unitrans-backend
pm2 save

echo "✅ تم إعادة تشغيل Backend"
echo ""

sleep 3

echo "===================================="
echo -e "${YELLOW}3️⃣  اختبار${NC}"
echo "===================================="

# Test shifts
echo "اختبار Shifts API:"
curl -s "http://localhost:3001/api/shifts/active" | head -c 200

echo ""
echo ""

# Test attendance
echo "اختبار Attendance API:"
curl -s "http://localhost:3001/api/attendance/today" | head -c 200

echo ""
echo ""

echo "===================================="
echo -e "${GREEN}✅ تم النقل!${NC}"
echo "===================================="
echo ""
echo "الآن جميع البيانات في student_portal:"
echo "  ✅ users (students)"
echo "  ✅ students"
echo "  ✅ shifts"
echo "  ✅ attendance"
echo ""
echo "جرب في المتصفح الآن!"
echo ""
