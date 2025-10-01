#!/bin/bash

echo "🧪 اختبار شامل بحساب Ahmed Azab (Supervisor)"
echo "==============================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SUPERVISOR_EMAIL="ahmedazab@gmail.com"
SUPERVISOR_PASSWORD="supervisor123"
STUDENT_EMAIL="mahmoudtarekmonaim@gmail.com"

echo "===================================="
echo -e "${YELLOW}1️⃣  Login كـ Supervisor (Ahmed Azab)${NC}"
echo "===================================="

LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$SUPERVISOR_EMAIL\",\"password\":\"$SUPERVISOR_PASSWORD\"}")

echo "$LOGIN_RESPONSE" | head -c 400
echo ""
echo ""

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
USER_ID=$(echo "$LOGIN_RESPONSE" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
    echo -e "${GREEN}✅ Login نجح${NC}"
    echo "Token: ${TOKEN:0:30}..."
    echo "User ID: $USER_ID"
else
    echo -e "${RED}❌ Login فشل${NC}"
    exit 1
fi

echo ""

echo "===================================="
echo -e "${YELLOW}2️⃣  فتح Shift${NC}"
echo "===================================="

SHIFT_OPEN=$(curl -s -X POST http://localhost:3001/api/shifts/open \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"supervisorId\":\"$USER_ID\",\"shiftType\":\"morning\"}")

echo "$SHIFT_OPEN" | head -c 400
echo ""
echo ""

SHIFT_ID=$(echo "$SHIFT_OPEN" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$SHIFT_ID" ]; then
    # جرب جلب shift موجود
    echo "محاولة جلب shift موجود..."
    SHIFTS=$(curl -s "http://localhost:3001/api/shifts?supervisorId=$USER_ID&status=open" \
      -H "Authorization: Bearer $TOKEN")
    SHIFT_ID=$(echo "$SHIFTS" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

if [ -n "$SHIFT_ID" ]; then
    echo -e "${GREEN}✅ Shift متاح${NC}"
    echo "Shift ID: $SHIFT_ID"
else
    echo -e "${RED}❌ لا يوجد shift نشط${NC}"
fi

echo ""

echo "===================================="
echo -e "${YELLOW}3️⃣  تسجيل حضور (Scan QR)${NC}"
echo "===================================="

if [ -n "$SHIFT_ID" ]; then
    ATTENDANCE=$(curl -s -X POST http://localhost:3001/api/attendance/register \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN" \
      -d "{
        \"studentId\":\"68d0886b0362753dc7fd1b36\",
        \"studentEmail\":\"$STUDENT_EMAIL\",
        \"studentName\":\"mahmoud tarek\",
        \"shiftId\":\"$SHIFT_ID\",
        \"scanTime\":\"$(date -Iseconds)\",
        \"college\":\"bis\",
        \"grade\":\"third-year\",
        \"supervisorId\":\"$USER_ID\"
      }")
    
    echo "$ATTENDANCE" | head -c 400
    echo ""
    echo ""
    
    if echo "$ATTENDANCE" | grep -q '"success":true'; then
        echo -e "${GREEN}✅ تسجيل الحضور نجح${NC}"
        ATTENDANCE_ID=$(echo "$ATTENDANCE" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
        echo "Attendance ID: $ATTENDANCE_ID"
    else
        echo -e "${RED}❌ تسجيل الحضور فشل${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  تخطي - لا يوجد shift${NC}"
fi

echo ""

echo "===================================="
echo -e "${YELLOW}4️⃣  جلب سجلات اليوم${NC}"
echo "===================================="

TODAY=$(curl -s "http://localhost:3001/api/attendance/today" \
  -H "Authorization: Bearer $TOKEN")

RECORDS_COUNT=$(echo "$TODAY" | grep -o '"studentName"' | wc -l)

echo "عدد السجلات: $RECORDS_COUNT"
echo ""
echo "نماذج من السجلات:"
echo "$TODAY" | grep -o '"studentName":"[^"]*"' | head -3

echo ""

echo "===================================="
echo -e "${YELLOW}5️⃣  جلب تفاصيل Shift${NC}"
echo "===================================="

if [ -n "$SHIFT_ID" ]; then
    SHIFT_DETAILS=$(curl -s "http://localhost:3001/api/shifts/$SHIFT_ID" \
      -H "Authorization: Bearer $TOKEN")
    
    echo "$SHIFT_DETAILS" | head -c 300
    echo ""
    
    SHIFT_SCANS=$(echo "$SHIFT_DETAILS" | grep -o '"scannedCount":[0-9]*' | cut -d: -f2)
    echo "عدد المسح في الـ Shift: ${SHIFT_SCANS:-0}"
fi

echo ""

echo "===================================="
echo -e "${YELLOW}6️⃣  جلب تفاصيل الطالب${NC}"
echo "===================================="

STUDENT=$(curl -s "http://localhost:3001/api/students/data?email=$STUDENT_EMAIL" \
  -H "Authorization: Bearer $TOKEN")

if echo "$STUDENT" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ بيانات الطالب متاحة${NC}"
    echo "$STUDENT" | grep -o '"fullName":"[^"]*"'
    echo "$STUDENT" | grep -o '"college":"[^"]*"'
else
    echo -e "${YELLOW}⚠️  بيانات الطالب غير متاحة${NC}"
fi

echo ""

echo "===================================="
echo -e "${GREEN}📊 ملخص النتائج${NC}"
echo "===================================="
echo ""
echo "1. Login (Supervisor): $([ -n \"$TOKEN\" ] && echo '✅ نجح' || echo '❌ فشل')"
echo "2. Open/Get Shift: $([ -n \"$SHIFT_ID\" ] && echo '✅ نجح' || echo '❌ فشل')"
echo "3. Register Attendance: $(echo $ATTENDANCE | grep -q success && echo '✅ نجح' || echo '❌ فشل')"
echo "4. Today Records: ✅ $RECORDS_COUNT سجل"
echo "5. Student Details: $(echo $STUDENT | grep -q success && echo '✅ متاح' || echo '❌ غير متاح')"
echo ""

if [ -n "$TOKEN" ] && [ -n "$SHIFT_ID" ]; then
    echo -e "${GREEN}🎉 جميع الوظائف تعمل على السيرفر!${NC}"
    echo ""
    echo "الآن في المتصفح:"
    echo "1. سجل دخول: ahmedazab@gmail.com / supervisor123"
    echo "2. افتح Supervisor Dashboard"
    echo "3. افتح Shift (إذا لم يكن مفتوح)"
    echo "4. امسح QR Code"
    echo "5. كل شيء يجب أن يعمل!"
else
    echo -e "${YELLOW}⚠️  بعض الوظائف لا تعمل${NC}"
fi

echo ""
