#!/bin/bash

echo "=================================================="
echo "🔍 البحث عن بيانات الطلاب في قاعدة البيانات"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="/var/www/unitrans"
cd $PROJECT_DIR || exit 1

echo -e "${BLUE}📂 المسار: $(pwd)${NC}"
echo ""

# ==========================================
# 1. البحث عن جميع الـ collections
# ==========================================
echo "=================================================="
echo -e "${YELLOW}1️⃣  جميع الجداول في قاعدة البيانات${NC}"
echo "=================================================="

mongosh student_portal --quiet --eval "
print('قاعدة البيانات: student_portal\n');
print('الجداول الموجودة:');
print('==================\n');
db.getCollectionNames().forEach(function(name) {
    var count = db[name].countDocuments();
    print('  📁 ' + name + ' → ' + count + ' سجل');
});
print('\n');
"

# ==========================================
# 2. عرض تفاصيل جدول students
# ==========================================
echo "=================================================="
echo -e "${YELLOW}2️⃣  تفاصيل جدول students${NC}"
echo "=================================================="

mongosh student_portal --quiet --eval "
var count = db.students.countDocuments();
print('إجمالي الطلاب: ' + count + '\n');

if (count > 0) {
    print('📝 بنية البيانات (طالب واحد كنموذج):');
    print('=========================================\n');
    var sample = db.students.findOne();
    printjson(sample);
    print('\n');
    
    print('🔑 جميع الحقول الموجودة في جدول students:');
    print('=========================================\n');
    var keys = Object.keys(sample);
    keys.forEach(function(key) {
        var value = sample[key];
        var type = typeof value;
        if (value === null) type = 'null';
        if (Array.isArray(value)) type = 'array';
        print('  ✓ ' + key.padEnd(20) + ' : ' + type);
    });
    print('\n');
    
    print('👥 عينة من 5 طلاب (بيانات مختصرة):');
    print('=========================================\n');
    db.students.find().limit(5).forEach(function(student) {
        print('📌 ID: ' + student._id);
        print('   الاسم: ' + (student.fullName || student.name || 'غير محدد'));
        print('   البريد: ' + (student.email || 'غير محدد'));
        print('   الهاتف: ' + (student.phoneNumber || student.phone || 'غير محدد'));
        print('   الكلية: ' + (student.college || 'غير محدد'));
        print('   التخصص: ' + (student.major || 'غير محدد'));
        print('   الصف/السنة: ' + (student.grade || student.academicYear || 'غير محدد'));
        if (student.attendanceCount !== undefined) {
            print('   الحضور: ' + student.attendanceCount);
        }
        if (student.isActive !== undefined) {
            print('   نشط: ' + student.isActive);
        }
        if (student.status !== undefined) {
            print('   الحالة: ' + student.status);
        }
        print('   ---');
    });
    print('\n');
    
    print('📊 إحصائيات إضافية:');
    print('=========================================\n');
    
    // Count active students
    var activeCount = db.students.countDocuments({ isActive: true });
    print('  ✓ الطلاب النشطون: ' + activeCount);
    
    // Check if there's a status field
    var statusCount = db.students.countDocuments({ status: { $exists: true } });
    if (statusCount > 0) {
        print('  ✓ الطلاب مع حقل status: ' + statusCount);
    }
    
    // Count students with QR codes
    var qrCount = db.students.countDocuments({ qrCode: { $exists: true, $ne: null } });
    print('  ✓ الطلاب مع QR Code: ' + qrCount);
    
    print('\n');
} else {
    print('⚠️  لا يوجد طلاب في جدول students!\n');
    print('هل البيانات في جدول آخر؟\n');
}
"

# ==========================================
# 3. فحص جدول users (قد يحتوي على طلاب)
# ==========================================
echo "=================================================="
echo -e "${YELLOW}3️⃣  فحص جدول users (البحث عن طلاب)${NC}"
echo "=================================================="

mongosh student_portal --quiet --eval "
var usersCount = db.users.countDocuments();
print('إجمالي المستخدمين: ' + usersCount + '\n');

if (usersCount > 0) {
    // Count students in users collection
    var studentUsers = db.users.countDocuments({ role: 'student' });
    print('👥 المستخدمين بدور student: ' + studentUsers + '\n');
    
    if (studentUsers > 0) {
        print('📝 نماذج من المستخدمين الطلاب:');
        print('=========================================\n');
        db.users.find({ role: 'student' }).limit(3).forEach(function(user) {
            print('📌 ID: ' + user._id);
            print('   الاسم: ' + (user.fullName || user.name || 'غير محدد'));
            print('   البريد: ' + (user.email || 'غير محدد'));
            print('   الدور: ' + user.role);
            print('   ---');
        });
        print('\n');
        
        print('🔑 حقول جدول users (نموذج):');
        print('=========================================\n');
        var sampleUser = db.users.findOne({ role: 'student' });
        if (sampleUser) {
            Object.keys(sampleUser).forEach(function(key) {
                var type = typeof sampleUser[key];
                print('  ✓ ' + key.padEnd(20) + ' : ' + type);
            });
        }
        print('\n');
    }
    
    // Show role distribution
    print('📊 توزيع الأدوار في جدول users:');
    print('=========================================\n');
    db.users.aggregate([
        { \$group: { _id: '\$role', count: { \$sum: 1 } } }
    ]).forEach(function(doc) {
        print('  ➜ ' + (doc._id || 'بدون دور') + ': ' + doc.count);
    });
    print('\n');
}
"

# ==========================================
# 4. ملخص البيانات
# ==========================================
echo "=================================================="
echo -e "${YELLOW}4️⃣  الملخص${NC}"
echo "=================================================="

mongosh student_portal --quiet --eval "
var studentsInStudents = db.students.countDocuments();
var studentsInUsers = db.users.countDocuments({ role: 'student' });
var totalAttendance = db.attendance.countDocuments();

print('📊 ملخص البيانات:');
print('==================\n');
print('  • جدول students: ' + studentsInStudents + ' طالب');
print('  • جدول users (role=student): ' + studentsInUsers + ' طالب');
print('  • سجلات الحضور: ' + totalAttendance);
print('\n');

if (studentsInStudents > 0) {
    print('✅ البيانات موجودة في جدول: students');
} else if (studentsInUsers > 0) {
    print('✅ البيانات موجودة في جدول: users');
} else {
    print('⚠️  لا توجد بيانات طلاب!');
}
print('\n');
"

echo "=================================================="
echo -e "${GREEN}✅ انتهى البحث!${NC}"
echo "=================================================="
echo ""
echo "📤 أرسل كامل النتيجة أعلاه"
echo ""
