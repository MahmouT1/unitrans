#!/bin/bash

echo "🎯 اختبار شامل نهائي - كل الوظائف"
echo "=============================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ==========================================
# 1. Test Backend API - Student Data
# ==========================================
echo "======================================"
echo "1️⃣  Backend API: Student Data"
echo "======================================"

BACKEND_DATA=$(curl -s "http://localhost:3001/api/students/data?email=mahmoudtarekmonaim@gmail.com")
BACKEND_STUDENT_ID=$(echo "$BACKEND_DATA" | grep -o '"studentId":"[^"]*"' | head -1)

if [ -n "$BACKEND_STUDENT_ID" ]; then
    echo -e "${GREEN}✅ Backend يرجع studentId: $BACKEND_STUDENT_ID${NC}"
else
    echo -e "${RED}❌ Backend لا يرجع studentId${NC}"
fi

echo ""

# ==========================================
# 2. Test Backend API - Generate QR
# ==========================================
echo "======================================"
echo "2️⃣  Backend API: Generate QR"
echo "======================================"

BACKEND_QR=$(curl -s -X POST "http://localhost:3001/api/students/generate-qr" \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com"}')

if echo "$BACKEND_QR" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Backend Generate QR يعمل${NC}"
else
    echo -e "${RED}❌ Backend Generate QR فشل${NC}"
    echo "$BACKEND_QR" | head -c 200
fi

echo ""

# ==========================================
# 3. Test Frontend API - Student Data
# ==========================================
echo "======================================"
echo "3️⃣  Frontend API: Student Data"
echo "======================================"

FRONTEND_DATA=$(curl -s "http://localhost:3000/api/students/data?email=mahmoudtarekmonaim@gmail.com")
FRONTEND_STUDENT_ID=$(echo "$FRONTEND_DATA" | grep -o '"studentId":"[^"]*"' | head -1)

if [ -n "$FRONTEND_STUDENT_ID" ]; then
    echo -e "${GREEN}✅ Frontend API يرجع studentId: $FRONTEND_STUDENT_ID${NC}"
else
    echo -e "${RED}❌ Frontend API لا يرجع studentId${NC}"
    echo "Response: $FRONTEND_DATA" | head -c 200
fi

echo ""

# ==========================================
# 4. Test Frontend API - Generate QR
# ==========================================
echo "======================================"
echo "4️⃣  Frontend API: Generate QR"
echo "======================================"

FRONTEND_QR=$(curl -s -X POST "http://localhost:3000/api/students/generate-qr" \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com"}')

if echo "$FRONTEND_QR" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Frontend Generate QR يعمل${NC}"
else
    echo -e "${RED}❌ Frontend Generate QR فشل${NC}"
    echo "$FRONTEND_QR" | head -c 200
fi

echo ""

# ==========================================
# 5. Database Check
# ==========================================
echo "======================================"
echo "5️⃣  Database: mahmoud studentId"
echo "======================================"

DB_STUDENT_ID=$(mongosh student_portal --quiet --eval "
var student = db.students.findOne({ email: 'mahmoudtarekmonaim@gmail.com' });
if (student && student.studentId) {
    print(student.studentId);
} else {
    print('NOT_FOUND');
}
")

if [ "$DB_STUDENT_ID" != "NOT_FOUND" ]; then
    echo -e "${GREEN}✅ Database: studentId = $DB_STUDENT_ID${NC}"
else
    echo -e "${RED}❌ Database: studentId مفقود${NC}"
fi

echo ""

# ==========================================
# 6. Check Database Names
# ==========================================
echo "======================================"
echo "6️⃣  Database Names Check"
echo "======================================"

echo "Backend .env:"
grep -E "MONGODB_DB|DB_NAME" /var/www/unitrans/backend-new/.env

echo ""
echo "Frontend .env:"
if [ -f /var/www/unitrans/frontend-new/.env ]; then
    grep -E "MONGODB_DB|DB_NAME" /var/www/unitrans/frontend-new/.env
else
    echo "⚠️  Frontend .env غير موجود"
fi

echo ""

# ==========================================
# 7. Summary
# ==========================================
echo "======================================"
echo "📊 الملخص النهائي"
echo "======================================"
echo ""

PASS=0
TOTAL=5

[ -n "$BACKEND_STUDENT_ID" ] && echo "✅ Backend Student Data" && ((PASS++)) || echo "❌ Backend Student Data"
echo "$BACKEND_QR" | grep -q success.*true && echo "✅ Backend Generate QR" && ((PASS++)) || echo "❌ Backend Generate QR"
[ -n "$FRONTEND_STUDENT_ID" ] && echo "✅ Frontend Student Data" && ((PASS++)) || echo "❌ Frontend Student Data"
echo "$FRONTEND_QR" | grep -q success.*true && echo "✅ Frontend Generate QR" && ((PASS++)) || echo "❌ Frontend Generate QR"
[ "$DB_STUDENT_ID" != "NOT_FOUND" ] && echo "✅ Database StudentId" && ((PASS++)) || echo "❌ Database StudentId"

echo ""
echo "النتيجة: $PASS/$TOTAL"
echo ""

if [ $PASS -eq $TOTAL ]; then
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}🎉 كل الاختبارات نجحت 100%!${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo "المشكلة في Browser Cache فقط!"
    echo ""
    echo "في المتصفح:"
    echo "1. Ctrl+Shift+Delete → All time → Clear"
    echo "2. أغلق المتصفح تماماً"
    echo "3. افتحه من جديد"
    echo "4. Incognito Mode (Ctrl+Shift+N)"
    echo "5. unibus.online/student/portal"
else
    echo -e "${YELLOW}⚠️  بعض الاختبارات فشلت - سأحللها${NC}"
fi

echo ""

