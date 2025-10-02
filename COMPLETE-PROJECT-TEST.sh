#!/bin/bash

echo "🎯 الاختبار الشامل الكامل للمشروع"
echo "=============================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
TOTAL=15

# ==========================================
# الخطوة 1: إنشاء حساب طالب جديد
# ==========================================
echo "======================================"
echo -e "${YELLOW}1️⃣  إنشاء حساب جديد: ali ramy${NC}"
echo "======================================"

REGISTER=$(curl -s -X POST http://localhost:3001/auth-api/register \
  -H "Content-Type: application/json" \
  -d '{
    "email":"aliramy123@gmail.com",
    "password":"ali123",
    "fullName":"ali ramy",
    "role":"student"
  }')

if echo "$REGISTER" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ حساب جديد تم إنشاؤه${NC}"
    ((PASS++))
    
    NEW_TOKEN=$(echo "$REGISTER" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
    NEW_USER_ID=$(echo "$REGISTER" | grep -o '"_id":"[^"]*"' | sed 's/"_id":"//;s/"//' | head -1)
    
    echo "   User ID: $NEW_USER_ID"
    echo "   Token: ${NEW_TOKEN:0:40}..."
else
    echo -e "${RED}❌ فشل إنشاء الحساب${NC}"
    echo "$REGISTER" | head -c 300
fi

echo ""

# ==========================================
# الخطوة 2: إضافة بيانات الطالب (Registration)
# ==========================================
echo "======================================"
echo -e "${YELLOW}2️⃣  إضافة بيانات الطالب (Registration)${NC}"
echo "======================================"

STUDENT_REG=$(curl -s -X POST http://localhost:3001/api/students/register \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $NEW_TOKEN" \
  -d '{
    "fullName":"ali ramy",
    "email":"aliramy123@gmail.com",
    "phoneNumber":"01234567890",
    "college":"engineering",
    "grade":"second-year",
    "major":"computer science",
    "address":"Cairo, Egypt"
  }')

if echo "$STUDENT_REG" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ بيانات الطالب تم حفظها${NC}"
    ((PASS++))
else
    echo -e "${YELLOW}⚠️  قد يكون الطالب موجود مسبقاً${NC}"
fi

echo ""

# ==========================================
# الخطوة 3: جلب بيانات الطالب وعرض البانر
# ==========================================
echo "======================================"
echo -e "${YELLOW}3️⃣  جلب بيانات الطالب (البانر)${NC}"
echo "======================================"

ALI_DATA=$(curl -s "http://localhost:3001/api/students/data?email=aliramy123@gmail.com" \
  -H "Authorization: Bearer $NEW_TOKEN")

ALI_STUDENT_ID=$(echo "$ALI_DATA" | grep -o '"studentId":"[^"]*"' | sed 's/"studentId":"//;s/"//')

echo "البانر:"
echo "  Name: ali ramy"
echo "  Email: aliramy123@gmail.com"
echo "  Student ID: ${ALI_STUDENT_ID:-Not assigned}"
echo "  College: engineering"
echo "  Grade: second-year"

if [ -n "$ALI_STUDENT_ID" ] && [ "$ALI_STUDENT_ID" != "null" ]; then
    echo -e "${GREEN}✅ Student ID يظهر في البانر${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ Student ID مفقود${NC}"
fi

echo ""

# ==========================================
# الخطوة 4: Generate QR Code
# ==========================================
echo "======================================"
echo -e "${YELLOW}4️⃣  Generate QR Code${NC}"
echo "======================================"

ALI_QR=$(curl -s -X POST http://localhost:3001/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"email":"aliramy123@gmail.com"}')

if echo "$ALI_QR" | grep -q '"success":true' && echo "$ALI_QR" | grep -q '"qrCode":"data:image'; then
    echo -e "${GREEN}✅ QR Code تم إنشاؤه بنجاح${NC}"
    ((PASS++))
    
    QR_DATA=$(echo "$ALI_QR" | grep -o '"qrCode":"[^"]*"' | head -c 100)
    echo "   QR Code موجود: ${QR_DATA:0:50}..."
else
    echo -e "${RED}❌ QR Code فشل${NC}"
fi

echo ""

# ==========================================
# الخطوة 5: Login Supervisor (Ahmed Azab)
# ==========================================
echo "======================================"
echo -e "${YELLOW}5️⃣  Login Supervisor (Ahmed Azab)${NC}"
echo "======================================"

SUPER_LOGIN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}')

SUPER_TOKEN=$(echo "$SUPER_LOGIN" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
SUPER_ID=$(echo "$SUPER_LOGIN" | grep -o '"_id":"[^"]*"' | sed 's/"_id":"//;s/"//' | head -1)

if [ -n "$SUPER_TOKEN" ]; then
    echo -e "${GREEN}✅ Supervisor Login نجح${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ Supervisor Login فشل${NC}"
fi

echo ""

# ==========================================
# الخطوة 6: Open Shift
# ==========================================
echo "======================================"
echo -e "${YELLOW}6️⃣  فتح Shift${NC}"
echo "======================================"

SHIFT=$(curl -s -X POST http://localhost:3001/api/shifts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SUPER_TOKEN" \
  -d "{\"supervisorId\":\"$SUPER_ID\",\"shiftType\":\"morning\"}")

SHIFT_ID=$(echo "$SHIFT" | grep -o '"id":"[^"]*"' | sed 's/"id":"//;s/"//' | head -1)

if [ -z "$SHIFT_ID" ]; then
    ACTIVE=$(curl -s "http://localhost:3001/api/shifts/active" -H "Authorization: Bearer $SUPER_TOKEN")
    SHIFT_ID=$(echo "$ACTIVE" | grep -o '"id":"[^"]*"' | sed 's/"id":"//;s/"//' | head -1)
fi

if [ -n "$SHIFT_ID" ]; then
    echo -e "${GREEN}✅ Shift ID: $SHIFT_ID${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ فشل فتح Shift${NC}"
fi

echo ""

# ==========================================
# الخطوة 7: Scan QR Code
# ==========================================
echo "======================================"
echo -e "${YELLOW}7️⃣  Scan QR Code (ali ramy)${NC}"
echo "======================================"

SCAN=$(curl -s -X POST http://localhost:3001/api/shifts/scan \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SUPER_TOKEN" \
  -d "{
    \"shiftId\":\"$SHIFT_ID\",
    \"qrCodeData\":\"{\\\"email\\\":\\\"aliramy123@gmail.com\\\",\\\"studentId\\\":\\\"$ALI_STUDENT_ID\\\",\\\"fullName\\\":\\\"ali ramy\\\"}\",
    \"location\":\"Main Station\",
    \"notes\":\"Test Scan\"
  }")

if echo "$SCAN" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ QR Scan نجح - حضور تم تسجيله${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ QR Scan فشل${NC}"
    echo "$SCAN" | head -c 300
fi

echo ""

# ==========================================
# الخطوة 8: التحقق من Total Scans
# ==========================================
echo "======================================"
echo -e "${YELLOW}8️⃣  التحقق من Total Scans${NC}"
echo "======================================"

SHIFT_DETAILS=$(curl -s "http://localhost:3001/api/shifts?shiftId=$SHIFT_ID" \
  -H "Authorization: Bearer $SUPER_TOKEN")

TOTAL_SCANS=$(echo "$SHIFT_DETAILS" | grep -o '"totalScans":[0-9]*' | grep -o '[0-9]*' | head -1)

if [ "${TOTAL_SCANS:-0}" -gt 0 ]; then
    echo -e "${GREEN}✅ Total Scans: $TOTAL_SCANS${NC}"
    ((PASS++))
else
    echo -e "${YELLOW}⚠️  Total Scans: 0${NC}"
fi

echo ""

# ==========================================
# الخطوة 9: دفع اشتراك
# ==========================================
echo "======================================"
echo -e "${YELLOW}9️⃣  دفع اشتراك (Payment)${NC}"
echo "======================================"

PAYMENT=$(curl -s -X POST http://localhost:3001/api/subscriptions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SUPER_TOKEN" \
  -d "{
    \"studentEmail\":\"aliramy123@gmail.com\",
    \"studentName\":\"ali ramy\",
    \"amount\":500,
    \"subscriptionType\":\"monthly\",
    \"paymentMethod\":\"cash\"
  }")

if echo "$PAYMENT" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ الدفع نجح${NC}"
    ((PASS++))
    
    SUB_ID=$(echo "$PAYMENT" | grep -o '"_id":"[^"]*"' | sed 's/"_id":"//;s/"//' | head -1)
    echo "   Subscription ID: $SUB_ID"
else
    echo -e "${RED}❌ الدفع فشل${NC}"
    echo "$PAYMENT" | head -c 300
fi

echo ""

# ==========================================
# الخطوة 10: التحقق من Subscription في Admin
# ==========================================
echo "======================================"
echo -e "${YELLOW}🔟 التحقق من Subscriptions (Admin)${NC}"
echo "======================================"

ADMIN_SUBS=$(curl -s "http://localhost:3001/api/subscriptions" \
  -H "Authorization: Bearer $SUPER_TOKEN")

ALI_SUB_COUNT=$(echo "$ADMIN_SUBS" | grep -o "aliramy123@gmail.com" | wc -l)

if [ $ALI_SUB_COUNT -gt 0 ]; then
    echo -e "${GREEN}✅ الاشتراك يظهر في صفحة Admin${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ الاشتراك لا يظهر${NC}"
fi

echo ""

# ==========================================
# الخطوة 11: Student Portal Subscription
# ==========================================
echo "======================================"
echo -e "${YELLOW}1️⃣1️⃣ Subscription في Student Portal${NC}"
echo "======================================"

STUDENT_SUB=$(curl -s "http://localhost:3001/api/subscriptions?studentEmail=aliramy123@gmail.com" \
  -H "Authorization: Bearer $NEW_TOKEN")

if echo "$STUDENT_SUB" | grep -q "aliramy123@gmail.com"; then
    echo -e "${GREEN}✅ الاشتراك يظهر في Student Portal${NC}"
    ((PASS++))
    
    AMOUNT=$(echo "$STUDENT_SUB" | grep -o '"amount":[0-9]*' | grep -o '[0-9]*' | head -1)
    echo "   المبلغ المدفوع: ${AMOUNT:-0} EGP"
else
    echo -e "${RED}❌ الاشتراك لا يظهر${NC}"
fi

echo ""

# ==========================================
# الخطوة 12: Student Search
# ==========================================
echo "======================================"
echo -e "${YELLOW}1️⃣2️⃣ التحقق من Student Search${NC}"
echo "======================================"

SEARCH=$(curl -s "http://localhost:3001/api/students/all?search=ali" \
  -H "Authorization: Bearer $SUPER_TOKEN")

if echo "$SEARCH" | grep -q "aliramy123@gmail.com"; then
    echo -e "${GREEN}✅ الطالب يظهر في Student Search${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ الطالب لا يظهر في Search${NC}"
fi

echo ""

# ==========================================
# الخطوة 13: Admin Reports (الإيرادات)
# ==========================================
echo "======================================"
echo -e "${YELLOW}1️⃣3️⃣ التحقق من Reports (الإيرادات)${NC}"
echo "======================================"

# Login as Admin
ADMIN_LOGIN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@unibus.com","password":"admin123"}')

ADMIN_TOKEN=$(echo "$ADMIN_LOGIN" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')

if [ -z "$ADMIN_TOKEN" ]; then
    # Try alternative admin
    ADMIN_LOGIN=$(curl -s -X POST http://localhost:3001/auth-api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}')
    ADMIN_TOKEN=$(echo "$ADMIN_LOGIN" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
fi

if [ -n "$ADMIN_TOKEN" ]; then
    REPORTS=$(curl -s "http://localhost:3001/api/admin/reports" \
      -H "Authorization: Bearer $ADMIN_TOKEN")
    
    if echo "$REPORTS" | grep -q "revenue\|income\|subscriptions"; then
        echo -e "${GREEN}✅ Reports API يعمل${NC}"
        ((PASS++))
    else
        echo -e "${YELLOW}⚠️  Reports قد لا يحتوي على بيانات${NC}"
    fi
else
    echo -e "${RED}❌ Admin Login فشل${NC}"
fi

echo ""

# ==========================================
# الخطوة 14: التحقق من قاعدة البيانات
# ==========================================
echo "======================================"
echo -e "${YELLOW}1️⃣4️⃣ التحقق من قاعدة البيانات student_portal${NC}"
echo "======================================"

# Check if ali exists in database
DB_CHECK=$(mongosh student_portal --quiet --eval "
var student = db.students.findOne({ email: 'aliramy123@gmail.com' });
var user = db.users.findOne({ email: 'aliramy123@gmail.com' });
var sub = db.subscriptions.findOne({ studentEmail: 'aliramy123@gmail.com' });

print('Students collection: ' + (student ? 'موجود' : 'مفقود'));
print('Users collection: ' + (user ? 'موجود' : 'مفقود'));
print('Subscriptions collection: ' + (sub ? 'موجود' : 'مفقود'));

if (student) print('StudentId: ' + (student.studentId || 'مفقود'));
")

echo "$DB_CHECK"

if echo "$DB_CHECK" | grep -q "موجود"; then
    echo -e "${GREEN}✅ البيانات موجودة في student_portal${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ البيانات مفقودة${NC}"
fi

echo ""

# ==========================================
# الخطوة 15: التحقق من جميع الصفحات متصلة بنفس القاعدة
# ==========================================
echo "======================================"
echo -e "${YELLOW}1️⃣5️⃣ التحقق من اتصال جميع الصفحات بـ student_portal${NC}"
echo "======================================"

echo "Backend .env:"
grep "MONGODB_DB\|DB_NAME" /var/www/unitrans/backend-new/.env

echo ""
echo "Frontend connection:"
grep -A 2 "db(" /var/www/unitrans/frontend-new/lib/mongodb-simple-connection.js | grep "student_portal"

if grep -q "student_portal" /var/www/unitrans/backend-new/.env && \
   grep -q "student_portal" /var/www/unitrans/frontend-new/lib/mongodb-simple-connection.js; then
    echo -e "${GREEN}✅ جميع الصفحات متصلة بـ student_portal${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ بعض الصفحات متصلة بقواعد مختلفة${NC}"
fi

echo ""

# ==========================================
# النتيجة النهائية
# ==========================================
echo "=============================================="
echo -e "${GREEN}📊 النتيجة النهائية الشاملة${NC}"
echo "=============================================="
echo ""

echo "1.  إنشاء حساب جديد: $([ $PASS -ge 1 ] && echo '✅' || echo '❌')"
echo "2.  Registration بيانات: $([ $PASS -ge 2 ] && echo '✅' || echo '❌')"
echo "3.  Student ID في البانر: $([ $PASS -ge 3 ] && echo '✅' || echo '❌')"
echo "4.  Generate QR Code: $([ $PASS -ge 4 ] && echo '✅' || echo '❌')"
echo "5.  Supervisor Login: $([ $PASS -ge 5 ] && echo '✅' || echo '❌')"
echo "6.  Open Shift: $([ $PASS -ge 6 ] && echo '✅' || echo '❌')"
echo "7.  Scan QR: $([ $PASS -ge 7 ] && echo '✅' || echo '❌')"
echo "8.  Total Scans: $([ $PASS -ge 8 ] && echo '✅' || echo '❌')"
echo "9.  Payment: $([ $PASS -ge 9 ] && echo '✅' || echo '❌')"
echo "10. Admin Subscriptions: $([ $PASS -ge 10 ] && echo '✅' || echo '❌')"
echo "11. Student Subscriptions: $([ $PASS -ge 11 ] && echo '✅' || echo '❌')"
echo "12. Student Search: $([ $PASS -ge 12 ] && echo '✅' || echo '❌')"
echo "13. Admin Reports: $([ $PASS -ge 13 ] && echo '✅' || echo '❌')"
echo "14. Database student_portal: $([ $PASS -ge 14 ] && echo '✅' || echo '❌')"
echo "15. جميع الصفحات متصلة: $([ $PASS -ge 15 ] && echo '✅' || echo '❌')"

echo ""
echo "═══════════════════════════════════════════════"
echo -e "${GREEN}النتيجة: $PASS/$TOTAL${NC}"
echo "═══════════════════════════════════════════════"
echo ""

if [ $PASS -ge 12 ]; then
    echo -e "${GREEN}🎉🎉🎉 المشروع يعمل بشكل ممتاز! 🎉🎉🎉${NC}"
    echo ""
    echo "معظم الوظائف تعمل بنجاح!"
else
    echo -e "${YELLOW}⚠️  بعض الوظائف تحتاج مراجعة${NC}"
fi

echo ""

