#!/bin/bash

echo "🔧 إصلاح studentId لـ mahmoud tarek"
echo "====================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "===================================="
echo -e "${YELLOW}1️⃣  فحص بيانات mahmoud${NC}"
echo "===================================="

mongosh student_portal --quiet --eval "
var user = db.users.findOne({email:'mahmoudtarekmonaim@gmail.com'});
print('في users:');
print('  _id: ' + user._id);
print('  fullName: ' + user.fullName);
print('  email: ' + user.email);
print('  studentId: ' + (user.studentId || 'Not assigned'));
print('');

var student = db.students.findOne({email:'mahmoudtarekmonaim@gmail.com'});
if (student) {
    print('في students:');
    print('  _id: ' + student._id);
    print('  studentId: ' + (student.studentId || 'Not assigned'));
} else {
    print('⚠️  غير موجود في students');
}
"

echo ""

echo "===================================="
echo -e "${YELLOW}2️⃣  إضافة/تحديث studentId${NC}"
echo "===================================="

mongosh student_portal --quiet --eval "
// إنشاء studentId فريد
var newStudentId = 'STU-' + Date.now();

// تحديث في users
var updateUsers = db.users.updateOne(
    {email:'mahmoudtarekmonaim@gmail.com'},
    {\$set: {studentId: newStudentId}}
);

print('✅ تحديث users: ' + (updateUsers.modifiedCount > 0 ? 'نجح' : 'لم يتغير'));

// تحديث أو إضافة في students
var student = db.students.findOne({email:'mahmoudtarekmonaim@gmail.com'});

if (student) {
    var updateStudents = db.students.updateOne(
        {email:'mahmoudtarekmonaim@gmail.com'},
        {\$set: {studentId: newStudentId}}
    );
    print('✅ تحديث students: ' + (updateStudents.modifiedCount > 0 ? 'نجح' : 'لم يتغير'));
} else {
    // إنشاء سجل جديد في students
    var user = db.users.findOne({email:'mahmoudtarekmonaim@gmail.com'});
    var newStudent = {
        userId: user._id,
        studentId: newStudentId,
        fullName: user.fullName || user.name,
        email: user.email,
        phoneNumber: user.phoneNumber || user.phone,
        college: user.college || 'bis',
        grade: user.grade || 'third-year',
        major: user.major || 'جلا',
        attendanceCount: 0,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
    };
    
    db.students.insertOne(newStudent);
    print('✅ تم إنشاء سجل في students');
}

print('');
print('Student ID الجديد: ' + newStudentId);
"

echo ""

echo "===================================="
echo -e "${YELLOW}3️⃣  إعادة إنشاء QR Code لـ mahmoud${NC}"
echo "===================================="

# استخدام Backend API لإنشاء QR جديد
TOKEN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com","password":"memo123"}' \
  | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')

if [ -n "$TOKEN" ]; then
    QR_RESPONSE=$(curl -s -X POST http://localhost:3001/api/students/generate-qr \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN" \
      -d '{"email":"mahmoudtarekmonaim@gmail.com"}')
    
    if echo "$QR_RESPONSE" | grep -q '"success":true'; then
        echo -e "${GREEN}✅ QR Code تم إنشاؤه من جديد${NC}"
    else
        echo -e "${YELLOW}⚠️  QR Code: $(echo $QR_RESPONSE | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')${NC}"
    fi
fi

echo ""

echo "===================================="
echo -e "${YELLOW}4️⃣  التحقق من البيانات المحدثة${NC}"
echo "===================================="

mongosh student_portal --quiet --eval "
var user = db.users.findOne({email:'mahmoudtarekmonaim@gmail.com'});
print('✅ studentId في users: ' + user.studentId);

var student = db.students.findOne({email:'mahmoudtarekmonaim@gmail.com'});
if (student) {
    print('✅ studentId في students: ' + student.studentId);
    print('✅ _id: ' + student._id);
}
"

echo ""

echo "===================================="
echo -e "${GREEN}✅ تم الإصلاح!${NC}"
echo "===================================="
echo ""
echo "الآن في المتصفح:"
echo "  1. سجل دخول بحساب mahmoud"
echo "  2. Student Portal"
echo "  3. Generate QR Code من جديد"
echo "  4. استخدم QR الجديد للمسح"
echo ""
echo "يجب أن يعمل الآن! ✅"
echo ""
