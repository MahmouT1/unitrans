#!/bin/bash

echo "=================================================="
echo "🔍 البحث عن الطالب mahmoudtarekmonaim@gmail.com"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="/var/www/unitrans"
cd $PROJECT_DIR || exit 1

STUDENT_EMAIL="mahmoudtarekmonaim@gmail.com"

# ==========================================
# 1. البحث في جميع قواعد البيانات
# ==========================================
echo "=================================================="
echo -e "${YELLOW}1️⃣  البحث في جميع قواعد البيانات${NC}"
echo "=================================================="

mongosh --quiet --eval "
var targetEmail = '$STUDENT_EMAIL';
print('🔍 البحث عن: ' + targetEmail + '\n');

var databases = db.adminCommand('listDatabases').databases;
var found = false;

databases.forEach(function(database) {
    if (database.name !== 'admin' && database.name !== 'config' && database.name !== 'local') {
        var currentDb = db.getSiblingDB(database.name);
        var collections = currentDb.getCollectionNames();
        
        collections.forEach(function(collName) {
            // البحث بالبريد الإلكتروني
            var result = currentDb[collName].findOne({ email: targetEmail });
            
            if (result) {
                found = true;
                print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                print('✅ تم العثور على الطالب!');
                print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
                print('📂 قاعدة البيانات: ' + database.name);
                print('📁 الجدول: ' + collName);
                print('');
                print('📝 بيانات الطالب الكاملة:');
                print('═══════════════════════════════════════════\n');
                printjson(result);
                print('\n');
                
                print('🔑 جميع الحقول في هذا السجل:');
                print('═══════════════════════════════════════════\n');
                Object.keys(result).forEach(function(key) {
                    var value = result[key];
                    var type = typeof value;
                    if (value === null) type = 'null';
                    if (Array.isArray(value)) type = 'array';
                    if (value && typeof value === 'object' && value.constructor.name === 'ObjectId') type = 'ObjectId';
                    if (value && typeof value === 'object' && value instanceof Date) type = 'Date';
                    print('  ✓ ' + key.padEnd(25) + ' : ' + type);
                });
                print('\n');
                
                // عرض إحصائيات عن الجدول
                var totalInCollection = currentDb[collName].countDocuments();
                print('📊 إحصائيات الجدول ' + collName + ':');
                print('═══════════════════════════════════════════\n');
                print('  • إجمالي السجلات: ' + totalInCollection);
                
                // إذا كان فيه role, عد الطلاب
                if (result.role) {
                    var studentsCount = currentDb[collName].countDocuments({ role: 'student' });
                    print('  • عدد الطلاب (role=student): ' + studentsCount);
                }
                
                // إذا كان في isActive, عد النشطين
                if (result.hasOwnProperty('isActive')) {
                    var activeCount = currentDb[collName].countDocuments({ isActive: true });
                    print('  • السجلات النشطة: ' + activeCount);
                }
                
                print('\n');
                
                // عرض 5 سجلات من نفس الجدول
                print('👥 عينة من 5 سجلات أخرى من نفس الجدول:');
                print('═══════════════════════════════════════════\n');
                
                var query = result.role ? { role: result.role } : {};
                currentDb[collName].find(query).limit(5).forEach(function(doc) {
                    print('📌 ' + (doc.fullName || doc.name || 'بدون اسم'));
                    print('   البريد: ' + (doc.email || 'N/A'));
                    if (doc.role) print('   الدور: ' + doc.role);
                    if (doc.college) print('   الكلية: ' + doc.college);
                    if (doc.major) print('   التخصص: ' + doc.major);
                    if (doc.studentId) print('   رقم الطالب: ' + doc.studentId);
                    if (doc.isActive !== undefined) print('   نشط: ' + doc.isActive);
                    print('   ---');
                });
                print('\n');
            }
        });
    }
});

if (!found) {
    print('❌ لم يتم العثور على ' + targetEmail + ' في أي قاعدة بيانات!\n');
}
"

# ==========================================
# 2. فحص إعدادات قاعدة البيانات من الكود
# ==========================================
echo "=================================================="
echo -e "${YELLOW}2️⃣  إعدادات قاعدة البيانات من الكود${NC}"
echo "=================================================="

echo -e "${BLUE}Backend (.env):${NC}"
if [ -f "backend-new/.env" ]; then
    grep "MONGODB" backend-new/.env
else
    echo "⚠️  لا يوجد ملف .env"
fi
echo ""

echo -e "${BLUE}Frontend (.env.local):${NC}"
if [ -f "frontend-new/.env.local" ]; then
    grep "MONGODB" frontend-new/.env.local
else
    echo "⚠️  لا يوجد ملف .env.local"
fi
echo ""

# ==========================================
# 3. فحص كود Login API
# ==========================================
echo "=================================================="
echo -e "${YELLOW}3️⃣  فحص كود Login API${NC}"
echo "=================================================="

echo -e "${BLUE}البحث عن ملف login API في Backend:${NC}"
if [ -f "backend-new/routes/auth.js" ]; then
    echo "✅ وجدت: backend-new/routes/auth.js"
    echo ""
    echo "السطر الذي يبحث في قاعدة البيانات:"
    grep -n "collection\|find\|findOne" backend-new/routes/auth.js | head -5
elif [ -f "backend-new/routes/login.js" ]; then
    echo "✅ وجدت: backend-new/routes/login.js"
    echo ""
    echo "السطر الذي يبحث في قاعدة البيانات:"
    grep -n "collection\|find\|findOne" backend-new/routes/login.js | head -5
else
    echo "⚠️  لم أجد ملف login"
fi
echo ""

# ==========================================
# 4. اختبار Login API
# ==========================================
echo "=================================================="
echo -e "${YELLOW}4️⃣  اختبار Login API${NC}"
echo "=================================================="

echo -e "${BLUE}محاولة تسجيل الدخول بالحساب المذكور:${NC}"
echo ""

LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$STUDENT_EMAIL\",\"password\":\"memo123\"}" 2>&1)

echo "الاستجابة:"
echo "$LOGIN_RESPONSE" | head -30
echo ""

# ==========================================
# النتيجة
# ==========================================
echo "=================================================="
echo -e "${GREEN}✅ انتهى البحث!${NC}"
echo "=================================================="
echo ""
echo -e "${YELLOW}📊 الملخص:${NC}"
echo "• البريد المطلوب: $STUDENT_EMAIL"
echo "• تم البحث في جميع قواعد البيانات والجداول"
echo ""
echo -e "${BLUE}📤 أرسل كامل النتيجة أعلاه${NC}"
echo ""
