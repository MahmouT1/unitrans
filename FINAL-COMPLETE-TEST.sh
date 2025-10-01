#!/bin/bash

echo "🎯 الاختبار النهائي الشامل - جميع الوظائف"
echo "=============================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ==========================================
# 1. Login Supervisor
# ==========================================
echo "===================================="
echo -e "${YELLOW}1️⃣  Login (Ahmed - Supervisor)${NC}"
echo "===================================="

LOGIN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}')

TOKEN=$(echo "$LOGIN" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
USER_ID=$(echo "$LOGIN" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1)

if [ -n "$TOKEN" ]; then
    echo -e "${GREEN}✅ Login نجح${NC}"
else
    echo -e "${RED}❌ Login فشل${NC}"
    exit 1
fi

echo ""

# ==========================================
# 2. Open Shift
# ==========================================
echo "===================================="
echo -e "${YELLOW}2️⃣  Open Shift${NC}"
echo "===================================="

SHIFT=$(curl -s -X POST http://localhost:3001/api/shifts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"supervisorId\":\"$USER_ID\",\"shiftType\":\"morning\"}")

SHIFT_ID=$(echo "$SHIFT" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$SHIFT_ID" ]; then
    ACTIVE=$(curl -s "http://localhost:3001/api/shifts/active" -H "Authorization: Bearer $TOKEN")
    SHIFT_ID=$(echo "$ACTIVE" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1)
fi

if [ -n "$SHIFT_ID" ]; then
    echo -e "${GREEN}✅ Shift ID: $SHIFT_ID${NC}"
else
    echo -e "${RED}❌ No shift${NC}"
    exit 1
fi

echo ""

# ==========================================
# 3. Scan mahmoud QR Code
# ==========================================
echo "===================================="
echo -e "${YELLOW}3️⃣  Scan QR (mahmoud tarek)${NC}"
echo "===================================="

SCAN=$(curl -s -X POST http://localhost:3001/api/attendance/scan-qr \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"qrData\":\"{\\\"studentId\\\":\\\"STU-1759337924297\\\",\\\"email\\\":\\\"mahmoudtarekmonaim@gmail.com\\\",\\\"fullName\\\":\\\"mahmoud tarek\\\"}\",
    \"studentEmail\":\"mahmoudtarekmonaim@gmail.com\",
    \"studentName\":\"mahmoud tarek\",
    \"studentId\":\"68db086b0362753dc7fd1b36\",
    \"shiftId\":\"$SHIFT_ID\",
    \"college\":\"bis\",
    \"grade\":\"third-year\"
  }")

echo "$SCAN" | head -c 400
echo ""

if echo "$SCAN" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Scan نجح - تم تسجيل الحضور${NC}"
else
    echo -e "${RED}❌ Scan فشل${NC}"
    echo "السبب: $(echo $SCAN | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')"
fi

echo ""

# ==========================================
# 4. Get Today Attendance
# ==========================================
echo "===================================="
echo -e "${YELLOW}4️⃣  سجلات الحضور اليوم${NC}"
echo "===================================="

TODAY=$(curl -s "http://localhost:3001/api/attendance/today" \
  -H "Authorization: Bearer $TOKEN")

RECORDS=$(echo "$TODAY" | grep -o '"studentName"' | wc -l)
echo "عدد السجلات: $RECORDS"

if [ $RECORDS -gt 0 ]; then
    echo ""
    echo "آخر 3 سجلات:"
    echo "$TODAY" | grep -o '"studentName":"[^"]*"' | head -3
fi

echo ""

# ==========================================
# 5. Frontend API Test
# ==========================================
echo "===================================="
echo -e "${YELLOW}5️⃣  Frontend API (/api/attendance/today)${NC}"
echo "===================================="

FRONTEND_TODAY=$(curl -s "http://localhost:3000/api/attendance/today")

FRONTEND_RECORDS=$(echo "$FRONTEND_TODAY" | grep -o '"studentName"' | wc -l)
echo "عدد السجلات من Frontend: $FRONTEND_RECORDS"

if [ $FRONTEND_RECORDS -gt 0 ]; then
    echo -e "${GREEN}✅ Frontend API يعمل${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend API يرجع فارغ${NC}"
fi

echo ""

# ==========================================
# 6. Student Details
# ==========================================
echo "===================================="
echo -e "${YELLOW}6️⃣  Student Details (mahmoud)${NC}"
echo "===================================="

STUDENT=$(curl -s "http://localhost:3001/api/students/data?email=mahmoudtarekmonaim@gmail.com" \
  -H "Authorization: Bearer $TOKEN")

if echo "$STUDENT" | grep -q '"studentId":"STU-'; then
    STUDENT_ID=$(echo "$STUDENT" | sed -n 's/.*"studentId":"\([^"]*\)".*/\1/p')
    echo -e "${GREEN}✅ Student ID: $STUDENT_ID${NC}"
else
    echo -e "${YELLOW}⚠️  Student ID: Not found${NC}"
fi

echo ""

# ==========================================
# النتيجة النهائية
# ==========================================
echo "===================================="
echo -e "${GREEN}📊 الملخص النهائي${NC}"
echo "===================================="
echo ""

PASS=0
TOTAL=6

echo "1. Login: ✅ نجح" && ((PASS++))
echo "2. Shift: $([ -n \"$SHIFT_ID\" ] && echo '✅ نجح' && ((PASS++)) || echo '❌ فشل')"
echo "3. Scan QR: $(echo $SCAN | grep -q success.*true && echo '✅ نجح' && ((PASS++)) || echo '❌ فشل')"
echo "4. Backend /today: ✅ $RECORDS سجل" && ((PASS++))
echo "5. Frontend /today: $([ $FRONTEND_RECORDS -gt 0 ] && echo '✅ '$FRONTEND_RECORDS' سجل' && ((PASS++)) || echo '⚠️ فارغ')"
echo "6. Student Details: $(echo $STUDENT | grep -q studentId.*STU && echo '✅ صحيح' && ((PASS++)) || echo '⚠️ مفقود')"

echo ""
echo "النتيجة: $PASS/$TOTAL"
echo ""

if [ $PASS -eq $TOTAL ]; then
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}🎉 نجح 100%! كل الوظائف تعمل!${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo "المشروع جاهز للاستخدام على المتصفح!"
else
    echo -e "${YELLOW}⚠️  بعض الوظائف تحتاج مراجعة${NC}"
fi

echo ""
