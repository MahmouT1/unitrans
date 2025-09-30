#!/bin/bash

echo "=================================================="
echo "🔍 البحث عن الطلاب الحقيقيين في جميع الأماكن"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="/var/www/unitrans"
cd $PROJECT_DIR || exit 1

# ==========================================
# 1. البحث في جميع قواعد البيانات
# ==========================================
echo "=================================================="
echo -e "${YELLOW}1️⃣  جميع قواعد البيانات الموجودة${NC}"
echo "=================================================="

mongosh --quiet --eval "
print('📊 قواعد البيانات الموجودة:\n');
db.adminCommand('listDatabases').databases.forEach(function(database) {
    if (database.name !== 'admin' && database.name !== 'config' && database.name !== 'local') {
        print('  🗄️  ' + database.name + ' (' + (database.sizeOnDisk / 1024 / 1024).toFixed(2) + ' MB)');
    }
});
print('\n');
"

# ==========================================
# 2. فحص كل قاعدة بيانات بحثاً عن طلاب
# ==========================================
echo "=================================================="
echo -e "${YELLOW}2️⃣  البحث في كل قاعدة بيانات${NC}"
echo "=================================================="

mongosh --quiet --eval "
var databases = db.adminCommand('listDatabases').databases;

databases.forEach(function(database) {
    if (database.name !== 'admin' && database.name !== 'config' && database.name !== 'local') {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📂 قاعدة البيانات: ' + database.name);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        
        var currentDb = db.getSiblingDB(database.name);
        var collections = currentDb.getCollectionNames();
        
        print('الجداول الموجودة:');
        collections.forEach(function(collName) {
            var count = currentDb[collName].countDocuments();
            print('  📁 ' + collName + ': ' + count + ' سجل');
        });
        print('\n');
        
        // البحث عن students في collections
        collections.forEach(function(collName) {
            var count = currentDb[collName].countDocuments();
            if (count > 0 && count < 1000) { // تجنب الجداول الكبيرة جداً
                var sample = currentDb[collName].findOne();
                
                // تحقق إذا كان الجدول يحتوي على بيانات طلاب
                if (sample && (
                    sample.role === 'student' || 
                    sample.studentId || 
                    sample.college || 
                    sample.major ||
                    collName.toLowerCase().includes('student')
                )) {
                    print('  ✨ ' + collName + ' يبدو أنه يحتوي على بيانات طلاب!');
                    print('     عدد السجلات: ' + count);
                    
                    // عرض أول 3 سجلات
                    print('     نماذج من البيانات:');
                    currentDb[collName].find().limit(3).forEach(function(doc) {
                        print('     ───────────────────');
                        print('       📌 ID: ' + doc._id);
                        if (doc.fullName) print('       الاسم: ' + doc.fullName);
                        if (doc.name) print('       الاسم: ' + doc.name);
                        if (doc.email) print('       البريد: ' + doc.email);
                        if (doc.role) print('       الدور: ' + doc.role);
                        if (doc.college) print('       الكلية: ' + doc.college);
                        if (doc.major) print('       التخصص: ' + doc.major);
                        if (doc.studentId) print('       رقم الطالب: ' + doc.studentId);
                    });
                    print('\n');
                }
            }
        });
        print('\n');
    }
});
"

# ==========================================
# 3. فحص students في student_portal بتفصيل أكبر
# ==========================================
echo "=================================================="
echo -e "${YELLOW}3️⃣  فحص تفصيلي لـ student_portal${NC}"
echo "=================================================="

mongosh student_portal --quiet --eval "
print('🔍 فحص تفصيلي لجدول students:\n');

var studentsCount = db.students.countDocuments();
print('إجمالي السجلات: ' + studentsCount + '\n');

if (studentsCount > 0) {
    print('📅 آخر 10 طلاب تم إضافتهم (حسب تاريخ الإنشاء):');
    print('═══════════════════════════════════════════════\n');
    
    db.students.find().sort({ createdAt: -1 }).limit(10).forEach(function(student) {
        print('📌 ' + (student.fullName || student.name || 'بدون اسم'));
        print('   البريد: ' + (student.email || 'N/A'));
        print('   الكلية: ' + (student.college || 'N/A'));
        print('   تاريخ الإنشاء: ' + (student.createdAt || 'N/A'));
        print('   ---');
    });
    print('\n');
}

print('🔍 فحص تفصيلي لجدول users (الطلاب):');
print('═══════════════════════════════════════════════\n');

var usersStudentsCount = db.users.countDocuments({ role: 'student' });
print('طلاب في جدول users: ' + usersStudentsCount + '\n');

if (usersStudentsCount > 0) {
    print('📅 آخر 10 طلاب في users (حسب تاريخ الإنشاء):');
    print('═══════════════════════════════════════════════\n');
    
    db.users.find({ role: 'student' }).sort({ createdAt: -1 }).limit(10).forEach(function(user) {
        print('📌 ' + (user.fullName || user.name || 'بدون اسم'));
        print('   البريد: ' + (user.email || 'N/A'));
        print('   تاريخ الإنشاء: ' + (user.createdAt || 'N/A'));
        print('   آخر تسجيل دخول: ' + (user.lastLogin || 'N/A'));
        print('   نشط: ' + (user.isActive || false));
        print('   ---');
    });
}
"

# ==========================================
# 4. البحث في ملفات الإعدادات
# ==========================================
echo ""
echo "=================================================="
echo -e "${YELLOW}4️⃣  فحص إعدادات قواعد البيانات${NC}"
echo "=================================================="

echo -e "${BLUE}Backend .env:${NC}"
if [ -f "backend-new/.env" ]; then
    echo "اسم قاعدة البيانات المستخدمة:"
    grep "MONGODB" backend-new/.env | grep -v "URI"
else
    echo "⚠️  ملف .env غير موجود"
fi
echo ""

echo -e "${BLUE}Frontend .env.local:${NC}"
if [ -f "frontend-new/.env.local" ]; then
    echo "اسم قاعدة البيانات المستخدمة:"
    grep "MONGODB" frontend-new/.env.local | grep -v "URI"
else
    echo "⚠️  ملف .env.local غير موجود"
fi
echo ""

# ==========================================
# 5. فحص API الحالي
# ==========================================
echo "=================================================="
echo -e "${YELLOW}5️⃣  اختبار API الحالي للطلاب${NC}"
echo "=================================================="

echo -e "${BLUE}اختبار: GET /api/students/data${NC}"
echo "محاولة جلب بيانات طالب بالبريد..."
echo ""

# Get first student email from users
STUDENT_EMAIL=$(mongosh student_portal --quiet --eval "db.users.findOne({ role: 'student' })?.email" | tail -1)

if [ -n "$STUDENT_EMAIL" ]; then
    echo "اختبار البريد: $STUDENT_EMAIL"
    curl -s "http://localhost:3001/api/students/data?email=$STUDENT_EMAIL" | head -50
else
    echo "⚠️  لم يتم العثور على بريد طالب"
fi

echo ""
echo ""

# ==========================================
# النتيجة
# ==========================================
echo "=================================================="
echo -e "${GREEN}✅ انتهى البحث!${NC}"
echo "=================================================="
echo ""
echo -e "${YELLOW}📤 السؤال المهم:${NC}"
echo ""
echo "من أين يسجل الطلاب دخولهم حالياً؟"
echo "  1. من صفحة Login العادية؟"
echo "  2. من صفحة Student Portal؟"
echo ""
echo "وعندما يسجل طالب دخوله، ما هو البريد الذي يستخدمه؟"
echo "هل يمكنك إعطائي مثال على بريد طالب حقيقي يعمل حالياً؟"
echo ""
