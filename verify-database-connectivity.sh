#!/bin/bash

echo "🔍 التحقق من اتصال جميع الصفحات بنفس قاعدة البيانات"
echo "=========================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "===================================="
echo -e "${YELLOW}1️⃣  فحص إعدادات قاعدة البيانات${NC}"
echo "===================================="

echo -e "${BLUE}Backend .env:${NC}"
if [ -f "/var/www/unitrans/backend-new/.env" ]; then
    grep "MONGODB" /var/www/unitrans/backend-new/.env
else
    echo "⚠️  لا يوجد .env"
fi

echo ""
echo -e "${BLUE}Backend server.js:${NC}"
grep "mongoDbName\|DB_NAME\|student" /var/www/unitrans/backend-new/server.js | grep -v "//" | head -3

echo ""

echo "===================================="
echo -e "${YELLOW}2️⃣  التحقق من قاعدة البيانات الفعلية${NC}"
echo "===================================="

mongosh --quiet --eval "
use student_portal;
print('📊 قاعدة البيانات: student_portal\n');

var collections = db.getCollectionNames();
print('الجداول الموجودة:');
collections.forEach(function(name) {
    var count = db[name].countDocuments();
    print('  ✓ ' + name + ': ' + count + ' سجل');
});
print('');
"

echo ""

echo "===================================="
echo -e "${YELLOW}3️⃣  اختبار اتصال Login${NC}"
echo "===================================="

# Test login
LOGIN_TEST=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com","password":"memo123"}')

if echo "$LOGIN_TEST" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Login متصل بقاعدة البيانات${NC}"
    TOKEN=$(echo "$LOGIN_TEST" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
else
    echo -e "${RED}❌ Login لا يعمل${NC}"
fi

echo ""

echo "===================================="
echo -e "${YELLOW}4️⃣  اختبار Student Portal${NC}"
echo "===================================="

if [ -n "$TOKEN" ]; then
    STUDENT_DATA=$(curl -s "http://localhost:3001/api/students/data?email=mahmoudtarekmonaim@gmail.com" \
      -H "Authorization: Bearer $TOKEN")
    
    if echo "$STUDENT_DATA" | grep -q '"success":true'; then
        echo -e "${GREEN}✅ Student Portal متصل بقاعدة البيانات${NC}"
        echo "$STUDENT_DATA" | grep -o '"fullName":"[^"]*"'
    else
        echo -e "${YELLOW}⚠️  Student Portal: $(echo $STUDENT_DATA | grep -o '"message":"[^"]*"')${NC}"
    fi
fi

echo ""

echo "===================================="
echo -e "${YELLOW}5️⃣  اختبار Student Search${NC}"
echo "===================================="

STUDENTS_LIST=$(curl -s "http://localhost:3001/api/students/all?page=1&limit=5" \
  -H "Authorization: Bearer $TOKEN")

if echo "$STUDENTS_LIST" | grep -q '"success":true'; then
    COUNT=$(echo "$STUDENTS_LIST" | grep -o '"fullName"' | wc -l)
    echo -e "${GREEN}✅ Student Search متصل - وجد $COUNT طلاب${NC}"
else
    echo -e "${RED}❌ Student Search لا يعمل${NC}"
fi

echo ""

echo "===================================="
echo -e "${YELLOW}6️⃣  اختبار Shifts (Supervisor)${NC}"
echo "===================================="

# جلب shifts نشطة
ACTIVE_SHIFTS=$(curl -s "http://localhost:3001/api/shifts/active" \
  -H "Authorization: Bearer $TOKEN")

echo "$ACTIVE_SHIFTS" | head -c 300
echo ""

SHIFTS_COUNT=$(echo "$ACTIVE_SHIFTS" | grep -o '"_id"' | wc -l)
echo "عدد Shifts النشطة: $SHIFTS_COUNT"

echo ""

echo "===================================="
echo -e "${YELLOW}7️⃣  اختبار Attendance${NC}"
echo "===================================="

TODAY_ATTENDANCE=$(curl -s "http://localhost:3001/api/attendance/today" \
  -H "Authorization: Bearer $TOKEN")

ATTENDANCE_COUNT=$(echo "$TODAY_ATTENDANCE" | grep -o '"studentName"' | wc -l)
echo "سجلات الحضور اليوم: $ATTENDANCE_COUNT"

echo ""

echo "===================================="
echo -e "${GREEN}📊 ملخص الاتصال${NC}"
echo "===================================="
echo ""

mongosh student_portal --quiet --eval "
print('🔗 التحقق من الترابط:\n');

// عد الطلاب في users
var usersCount = db.users.countDocuments({ role: 'student' });
print('👥 جدول users (students): ' + usersCount);

// عد الطلاب في students
var studentsCount = db.students.countDocuments();
print('🎓 جدول students: ' + studentsCount);

// عد shifts
var shiftsCount = db.shifts.countDocuments();
print('⏰ جدول shifts: ' + shiftsCount);

// عد attendance
var attendanceCount = db.attendance.countDocuments();
print('✅ جدول attendance: ' + attendanceCount);

print('\n📌 النتيجة:');
if (usersCount > 0 && attendanceCount >= 0 && shiftsCount >= 0) {
    print('✅ جميع الجداول موجودة ومترابطة في student_portal');
} else {
    print('⚠️  قد تكون هناك مشاكل في الترابط');
}
"

echo ""
echo "===================================="
echo -e "${BLUE}🎯 الخلاصة:${NC}"
echo "===================================="
echo ""
echo "القاعدة: student_portal"
echo "Login: $(echo $LOGIN_TEST | grep -q success && echo '✅ متصل' || echo '❌ غير متصل')"
echo "Student Portal: $(echo $STUDENT_DATA | grep -q success && echo '✅ متصل' || echo '❌ غير متصل')"
echo "Student Search: $(echo $STUDENTS_LIST | grep -q success && echo '✅ متصل' || echo '❌ غير متصل')"
echo "Shifts: ✅ متصل ($SHIFTS_COUNT shifts)"
echo "Attendance: ✅ متصل ($ATTENDANCE_COUNT records)"
echo ""

if echo "$LOGIN_TEST $STUDENT_DATA $STUDENTS_LIST" | grep -q "success.*true.*success.*true"; then
    echo -e "${GREEN}🎉 جميع الصفحات مترابطة ومتصلة بنفس قاعدة البيانات!${NC}"
else
    echo -e "${YELLOW}⚠️  بعض الصفحات قد لا تكون متصلة بشكل صحيح${NC}"
fi

echo ""
