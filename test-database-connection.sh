#!/bin/bash

echo "=================================================="
echo "🔍 فحص شامل لقاعدة البيانات والاتصالات"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_DIR="/var/www/unitrans"

echo -e "${BLUE}📂 الذهاب لمجلد المشروع...${NC}"
cd $PROJECT_DIR || exit 1
echo -e "${GREEN}✅ المسار: $(pwd)${NC}"
echo ""

# ==========================================
# 1. فحص MongoDB
# ==========================================
echo "=================================================="
echo -e "${YELLOW}1️⃣  فحص حالة MongoDB${NC}"
echo "=================================================="

if systemctl is-active --quiet mongod; then
    echo -e "${GREEN}✅ MongoDB يعمل${NC}"
else
    echo -e "${RED}❌ MongoDB لا يعمل${NC}"
    echo -e "${YELLOW}محاولة تشغيل MongoDB...${NC}"
    sudo systemctl start mongod
fi

# معلومات MongoDB
echo -e "\n${BLUE}معلومات MongoDB:${NC}"
systemctl status mongod | grep "Active:" || echo "لا يمكن الحصول على الحالة"
echo ""

# ==========================================
# 2. فحص قاعدة البيانات والجداول
# ==========================================
echo "=================================================="
echo -e "${YELLOW}2️⃣  فحص قاعدة البيانات student_portal${NC}"
echo "=================================================="

mongo --quiet --eval "
db = db.getSiblingDB('student_portal');
print('📊 قاعدة البيانات: student_portal');
print('');
print('📁 الجداول (Collections) الموجودة:');
print('=====================================');
db.getCollectionNames().forEach(function(name) {
    var count = db[name].count();
    print('  ➜ ' + name + ': ' + count + ' سجل');
});
print('');
"

# ==========================================
# 3. فحص تفصيلي لجدول الطلاب
# ==========================================
echo "=================================================="
echo -e "${YELLOW}3️⃣  فحص تفصيلي لجدول الطلاب (students)${NC}"
echo "=================================================="

mongo student_portal --quiet --eval "
print('');
print('📈 إحصائيات جدول students:');
print('=====================================');
var totalStudents = db.students.count();
print('  ✓ إجمالي عدد الطلاب: ' + totalStudents);
print('');

if (totalStudents > 0) {
    print('📝 بنية البيانات - نموذج من طالب واحد:');
    print('=====================================');
    var sampleStudent = db.students.findOne();
    printjson(sampleStudent);
    print('');
    print('');
    
    print('🔑 الحقول (Fields) الموجودة في جدول الطلاب:');
    print('=====================================');
    var keys = Object.keys(sampleStudent);
    keys.forEach(function(key) {
        var type = typeof sampleStudent[key];
        print('  ➜ ' + key + ' (' + type + ')');
    });
    print('');
    print('');
    
    print('👥 أول 3 طلاب (للمراجعة):');
    print('=====================================');
    db.students.find().limit(3).forEach(function(student) {
        print('  📌 الاسم: ' + (student.fullName || 'غير محدد'));
        print('     البريد: ' + (student.email || 'غير محدد'));
        print('     الكلية: ' + (student.college || 'غير محدد'));
        print('     التخصص: ' + (student.major || 'غير محدد'));
        print('     الحضور: ' + (student.attendanceCount || 0));
        print('     نشط: ' + (student.isActive ? 'نعم' : 'لا'));
        print('     ---');
    });
} else {
    print('⚠️  لا يوجد طلاب في قاعدة البيانات!');
}
print('');
"

# ==========================================
# 4. فحص جدول المستخدمين (users)
# ==========================================
echo "=================================================="
echo -e "${YELLOW}4️⃣  فحص جدول المستخدمين (users)${NC}"
echo "=================================================="

mongo student_portal --quiet --eval "
var usersCount = db.users.count();
print('إجمالي المستخدمين: ' + usersCount);
print('');

if (usersCount > 0) {
    print('توزيع المستخدمين حسب الدور:');
    print('=====================================');
    var roles = db.users.aggregate([
        { \$group: { _id: '\$role', count: { \$sum: 1 } } }
    ]).toArray();
    
    roles.forEach(function(role) {
        print('  ➜ ' + role._id + ': ' + role.count);
    });
    print('');
}
"

# ==========================================
# 5. فحص ملفات .env
# ==========================================
echo "=================================================="
echo -e "${YELLOW}5️⃣  فحص ملفات البيئة (.env)${NC}"
echo "=================================================="

echo -e "${BLUE}Backend .env:${NC}"
if [ -f "backend-new/.env" ]; then
    echo -e "${GREEN}✅ backend-new/.env موجود${NC}"
    echo "المحتوى (بدون أسرار):"
    grep -E "^(MONGODB_URI|MONGODB_DB_NAME|PORT|NODE_ENV)" backend-new/.env || echo "  لا توجد إعدادات واضحة"
else
    echo -e "${RED}❌ backend-new/.env غير موجود${NC}"
fi
echo ""

echo -e "${BLUE}Frontend .env.local:${NC}"
if [ -f "frontend-new/.env.local" ]; then
    echo -e "${GREEN}✅ frontend-new/.env.local موجود${NC}"
    echo "المحتوى (بدون أسرار):"
    grep -E "^(BACKEND_URL|MONGODB_URI|MONGODB_DB_NAME|NEXT_PUBLIC)" frontend-new/.env.local || echo "  لا توجد إعدادات واضحة"
else
    echo -e "${RED}❌ frontend-new/.env.local غير موجود${NC}"
fi
echo ""

# ==========================================
# 6. فحص حالة الخدمات
# ==========================================
echo "=================================================="
echo -e "${YELLOW}6️⃣  فحص حالة الخدمات (Services)${NC}"
echo "=================================================="

if command -v pm2 &> /dev/null; then
    echo -e "${BLUE}خدمات PM2:${NC}"
    pm2 list
    echo ""
else
    echo -e "${YELLOW}⚠️  PM2 غير مثبت${NC}"
fi

# ==========================================
# 7. فحص Backend API
# ==========================================
echo "=================================================="
echo -e "${YELLOW}7️⃣  اختبار Backend API${NC}"
echo "=================================================="

echo -e "${BLUE}اختبار: GET /api/students/all${NC}"
BACKEND_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" http://localhost:3001/api/students/all?page=1&limit=5)
HTTP_STATUS=$(echo "$BACKEND_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Backend API يعمل (Status: $HTTP_STATUS)${NC}"
    echo "النتيجة:"
    echo "$BACKEND_RESPONSE" | sed '/HTTP_STATUS/d' | head -20
else
    echo -e "${RED}❌ Backend API لا يعمل (Status: $HTTP_STATUS)${NC}"
    echo "الاستجابة:"
    echo "$BACKEND_RESPONSE" | sed '/HTTP_STATUS/d'
fi
echo ""

echo -e "${BLUE}اختبار: GET /health (Backend)${NC}"
curl -s http://localhost:3001/health || echo -e "${YELLOW}⚠️  لا يوجد endpoint للـ health check${NC}"
echo ""

# ==========================================
# 8. فحص Frontend API Routes
# ==========================================
echo "=================================================="
echo -e "${YELLOW}8️⃣  فحص Frontend API Routes${NC}"
echo "=================================================="

echo -e "${BLUE}الـ API Routes الموجودة في Frontend:${NC}"
if [ -d "frontend-new/app/api" ]; then
    find frontend-new/app/api -name "route.js" -type f | while read file; do
        # Extract path
        path=$(echo "$file" | sed 's|frontend-new/app||' | sed 's|/route.js||')
        echo "  ✓ $path"
    done
else
    echo -e "${RED}❌ لا يوجد مجلد app/api${NC}"
fi
echo ""

echo -e "${BLUE}اختبار: GET /api/students/all (Frontend)${NC}"
FRONTEND_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" http://localhost:3000/api/students/all?page=1&limit=5 2>&1)
FRONTEND_STATUS=$(echo "$FRONTEND_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)

if [ "$FRONTEND_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Frontend API يعمل (Status: $FRONTEND_STATUS)${NC}"
else
    echo -e "${RED}❌ Frontend API لا يعمل (Status: $FRONTEND_STATUS)${NC}"
    echo -e "${YELLOW}👉 هذا متوقع - سنقوم بإنشاء هذا الـ endpoint${NC}"
fi
echo ""

# ==========================================
# 9. فحص المنافذ (Ports)
# ==========================================
echo "=================================================="
echo -e "${YELLOW}9️⃣  فحص المنافذ المستخدمة${NC}"
echo "=================================================="

echo -e "${BLUE}المنافذ المهمة:${NC}"
echo "  Port 3000 (Frontend):"
if sudo lsof -i :3000 > /dev/null 2>&1; then
    echo -e "    ${GREEN}✅ يعمل${NC}"
    sudo lsof -i :3000 | grep LISTEN | head -1
else
    echo -e "    ${RED}❌ لا يعمل${NC}"
fi

echo "  Port 3001 (Backend):"
if sudo lsof -i :3001 > /dev/null 2>&1; then
    echo -e "    ${GREEN}✅ يعمل${NC}"
    sudo lsof -i :3001 | grep LISTEN | head -1
else
    echo -e "    ${RED}❌ لا يعمل${NC}"
fi

echo "  Port 27017 (MongoDB):"
if sudo lsof -i :27017 > /dev/null 2>&1; then
    echo -e "    ${GREEN}✅ يعمل${NC}"
    sudo lsof -i :27017 | grep LISTEN | head -1
else
    echo -e "    ${RED}❌ لا يعمل${NC}"
fi
echo ""

# ==========================================
# 10. ملخص النتائج
# ==========================================
echo "=================================================="
echo -e "${YELLOW}🎯 ملخص الفحص${NC}"
echo "=================================================="

# Count issues
ISSUES=0

# Check MongoDB
if ! systemctl is-active --quiet mongod; then
    echo -e "${RED}❌ MongoDB لا يعمل${NC}"
    ((ISSUES++))
fi

# Check backend port
if ! sudo lsof -i :3001 > /dev/null 2>&1; then
    echo -e "${RED}❌ Backend (Port 3001) لا يعمل${NC}"
    ((ISSUES++))
fi

# Check frontend port
if ! sudo lsof -i :3000 > /dev/null 2>&1; then
    echo -e "${RED}❌ Frontend (Port 3000) لا يعمل${NC}"
    ((ISSUES++))
fi

# Check students count
STUDENTS_COUNT=$(mongo student_portal --quiet --eval "db.students.count()")
if [ "$STUDENTS_COUNT" = "0" ]; then
    echo -e "${YELLOW}⚠️  لا يوجد طلاب في قاعدة البيانات${NC}"
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ جميع الخدمات تعمل بشكل جيد${NC}"
    echo -e "${BLUE}📊 البيانات جاهزة للحل${NC}"
else
    echo -e "${YELLOW}⚠️  تم اكتشاف $ISSUES مشكلة${NC}"
fi

echo ""
echo "=================================================="
echo -e "${GREEN}✅ انتهى الفحص!${NC}"
echo "=================================================="
echo ""
echo "📤 الرجاء إرسال كامل النتيجة أعلاه للمراجعة"
echo ""
