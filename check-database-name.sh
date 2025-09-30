#!/bin/bash

echo "🔍 فحص اسم قاعدة البيانات الصحيح"
echo "====================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ==========================================
# 1. فحص جميع قواعد البيانات الموجودة
# ==========================================
echo "=================================================="
echo -e "${YELLOW}1️⃣  جميع قواعد البيانات الموجودة${NC}"
echo "=================================================="

mongosh --quiet --eval "
db.adminCommand('listDatabases').databases.forEach(function(database) {
    if (database.name !== 'admin' && database.name !== 'config' && database.name !== 'local') {
        print('📁 ' + database.name);
    }
});
"
echo ""

# ==========================================
# 2. البحث عن الطالب mahmoud في كل قاعدة بيانات
# ==========================================
echo "=================================================="
echo -e "${YELLOW}2️⃣  البحث عن mahmoudtarekmonaim@gmail.com${NC}"
echo "=================================================="

mongosh --quiet --eval "
var targetEmail = 'mahmoudtarekmonaim@gmail.com';
var databases = db.adminCommand('listDatabases').databases;
var found = false;

databases.forEach(function(database) {
    if (database.name !== 'admin' && database.name !== 'config' && database.name !== 'local') {
        var currentDb = db.getSiblingDB(database.name);
        var collections = currentDb.getCollectionNames();
        
        collections.forEach(function(collName) {
            var result = currentDb[collName].findOne({ email: targetEmail });
            if (result) {
                found = true;
                print('');
                print('✅ وجدت في:');
                print('   قاعدة البيانات: ' + database.name);
                print('   الجدول: ' + collName);
                print('');
            }
        });
    }
});

if (!found) {
    print('❌ لم يتم العثور على الطالب');
}
"

# ==========================================
# 3. فحص server.js - ما هو اسم القاعدة المستخدم؟
# ==========================================
echo "=================================================="
echo -e "${YELLOW}3️⃣  فحص اسم القاعدة في backend-new/server.js${NC}"
echo "=================================================="

if [ -f "/var/www/unitrans/backend-new/server.js" ]; then
    echo -e "${BLUE}البحث عن اسم قاعدة البيانات في الكود...${NC}"
    grep -n "mongoDbName\|DB_NAME\|student" /var/www/unitrans/backend-new/server.js | head -5
else
    echo -e "${YELLOW}⚠️  ملف server.js غير موجود${NC}"
fi

echo ""

# ==========================================
# 4. فحص .env
# ==========================================
echo "=================================================="
echo -e "${YELLOW}4️⃣  فحص ملف .env${NC}"
echo "=================================================="

if [ -f "/var/www/unitrans/backend-new/.env" ]; then
    echo -e "${BLUE}محتوى .env:${NC}"
    cat /var/www/unitrans/backend-new/.env | grep -E "MONGO|DB_NAME"
else
    echo -e "${YELLOW}⚠️  ملف .env غير موجود${NC}"
fi

echo ""

# ==========================================
# 5. عد الطلاب في كل قاعدة بيانات
# ==========================================
echo "=================================================="
echo -e "${YELLOW}5️⃣  عدد الطلاب في كل قاعدة بيانات${NC}"
echo "=================================================="

mongosh --quiet --eval "
var databases = db.adminCommand('listDatabases').databases;

databases.forEach(function(database) {
    if (database.name !== 'admin' && database.name !== 'config' && database.name !== 'local') {
        var currentDb = db.getSiblingDB(database.name);
        
        // فحص جدول students
        if (currentDb.getCollectionNames().indexOf('students') > -1) {
            var count = currentDb.students.countDocuments();
            if (count > 0) {
                print('📊 ' + database.name + ' → students: ' + count + ' طالب');
            }
        }
        
        // فحص جدول users (role: student)
        if (currentDb.getCollectionNames().indexOf('users') > -1) {
            var userCount = currentDb.users.countDocuments({ role: 'student' });
            if (userCount > 0) {
                print('📊 ' + database.name + ' → users (students): ' + userCount + ' طالب');
            }
        }
    }
});
"

echo ""

# ==========================================
# النتيجة
# ==========================================
echo "=================================================="
echo -e "${GREEN}✅ انتهى الفحص!${NC}"
echo "=================================================="
echo ""
echo -e "${BLUE}الخلاصة:${NC}"
echo "  انظر أعلاه لمعرفة:"
echo "  1. في أي قاعدة بيانات وجد mahmoud"
echo "  2. ما اسم القاعدة المستخدم في server.js"
echo "  3. أي قاعدة بيانات تحتوي على أكبر عدد من الطلاب"
echo ""
