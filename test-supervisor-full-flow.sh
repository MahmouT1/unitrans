#!/bin/bash

echo "🧪 اختبار كامل لعملية Supervisor (كما في المتصفح)"
echo "======================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ==========================================
# 1. Login كـ Supervisor
# ==========================================
echo "===================================="
echo -e "${YELLOW}1️⃣  Login (Ahmed Azab - Supervisor)${NC}"
echo "===================================="

LOGIN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}')

echo "$LOGIN" | head -c 500
echo ""

# استخراج Token و User ID
TOKEN=$(echo "$LOGIN" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
USER_ID=$(echo "$LOGIN" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ Login فشل!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Login نجح${NC}"
echo "Token: ${TOKEN:0:40}..."
echo "User ID: $USER_ID"
echo ""

# ==========================================
# 2. فتح Shift
# ==========================================
echo "===================================="
echo -e "${YELLOW}2️⃣  فتح Shift${NC}"
echo "===================================="

SHIFT=$(curl -s -X POST http://localhost:3001/api/shifts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"supervisorId\":\"$USER_ID\",\"shiftType\":\"morning\"}")

echo "$SHIFT" | head -c 500
echo ""

SHIFT_ID=$(echo "$SHIFT" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$SHIFT_ID" ]; then
    echo -e "${YELLOW}⚠️  لم يُفتح shift جديد (محاولة جلب موجود)${NC}"
    
    # جلب shifts نشطة
    ACTIVE=$(curl -s "http://localhost:3001/api/shifts/active" \
      -H "Authorization: Bearer $TOKEN")
    
    SHIFT_ID=$(echo "$ACTIVE" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1)
fi

if [ -n "$SHIFT_ID" ]; then
    echo -e "${GREEN}✅ Shift متاح${NC}"
    echo "Shift ID: $SHIFT_ID"
else
    echo -e "${RED}❌ لا يوجد shift${NC}"
    exit 1
fi

echo ""

# ==========================================
# 3. مسح QR Code (محاكاة)
# ==========================================
echo "===================================="
echo -e "${YELLOW}3️⃣  Scan QR Code${NC}"
echo "===================================="

QR_DATA='{"studentId":"68d0886b0362753dc7fd1b36","email":"mahmoudtarekmonaim@gmail.com","fullName":"mahmoud tarek","phoneNumber":"01025713978","college":"bis","grade":"third-year","major":"جلا"}'

echo "QR Data: $QR_DATA"
echo ""

# استخدام /api/attendance/scan-qr (الصحيح)
SCAN_RESULT=$(curl -s -X POST http://localhost:3001/api/attendance/scan-qr \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"qrData\":$QR_DATA,
    \"shiftId\":\"$SHIFT_ID\",
    \"supervisorId\":\"$USER_ID\",
    \"studentEmail\":\"mahmoudtarekmonaim@gmail.com\",
    \"studentName\":\"mahmoud tarek\",
    \"studentId\":\"68d0886b0362753dc7fd1b36\",
    \"college\":\"bis\",
    \"grade\":\"third-year\"
  }")

echo "Scan Result:"
echo "$SCAN_RESULT"
echo ""

if echo "$SCAN_RESULT" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Scan نجح - تم تسجيل الحضور!${NC}"
    ATTENDANCE_ID=$(echo "$SCAN_RESULT" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1)
    echo "Attendance ID: $ATTENDANCE_ID"
else
    echo -e "${RED}❌ Scan فشل${NC}"
    echo "السبب: $(echo $SCAN_RESULT | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')"
fi

echo ""

# ==========================================
# 4. جلب تفاصيل Shift المحدثة
# ==========================================
echo "===================================="
echo -e "${YELLOW}4️⃣  Refresh Shift (جلب التحديثات)${NC}"
echo "===================================="

SHIFT_UPDATED=$(curl -s "http://localhost:3001/api/shifts/$SHIFT_ID" \
  -H "Authorization: Bearer $TOKEN")

echo "$SHIFT_UPDATED" | head -c 400
echo ""

SCANNED_COUNT=$(echo "$SHIFT_UPDATED" | sed -n 's/.*"scannedCount":\([0-9]*\).*/\1/p')

if [ -n "$SCANNED_COUNT" ]; then
    echo -e "${GREEN}✅ Total Scans: $SCANNED_COUNT${NC}"
else
    echo -e "${YELLOW}⚠️  لم يتم تحديث scannedCount${NC}"
fi

echo ""

# ==========================================
# 5. جلب سجلات الحضور اليوم
# ==========================================
echo "===================================="
echo -e "${YELLOW}5️⃣  سجلات الحضور اليوم${NC}"
echo "===================================="

TODAY=$(curl -s "http://localhost:3001/api/attendance/today" \
  -H "Authorization: Bearer $TOKEN")

RECORDS_COUNT=$(echo "$TODAY" | grep -o '"studentName"' | wc -l)

echo "عدد السجلات اليوم: $RECORDS_COUNT"
echo ""

if [ $RECORDS_COUNT -gt 0 ]; then
    echo "آخر 3 سجلات:"
    echo "$TODAY" | grep -o '"studentName":"[^"]*"' | head -3
fi

echo ""

# ==========================================
# النتيجة النهائية
# ==========================================
echo "===================================="
echo -e "${GREEN}📊 ملخص الاختبار${NC}"
echo "===================================="
echo ""
echo "1. Login: ✅ نجح"
echo "2. Shift: ✅ متاح (ID: $SHIFT_ID)"
echo "3. QR Scan: $(echo $SCAN_RESULT | grep -q success && echo '✅ نجح' || echo '❌ فشل')"
echo "4. Total Scans: ${SCANNED_COUNT:-0}"
echo "5. Records اليوم: $RECORDS_COUNT"
echo ""

if echo "$SCAN_RESULT" | grep -q '"success":true'; then
    echo -e "${GREEN}🎉 جميع الوظائف تعمل على السيرفر!${NC}"
    echo ""
    echo "الآن جرب في المتصفح:"
    echo "  1. احذف Cache (Ctrl+Shift+Delete)"
    echo "  2. Login كـ Ahmed"
    echo "  3. Supervisor Dashboard"
    echo "  4. Open Shift (إذا لزم)"
    echo "  5. امسح QR Code"
    echo "  6. اضغط Refresh"
    echo "  7. يجب أن يعمل كل شيء!"
else
    echo -e "${RED}❌ هناك مشكلة في التسجيل${NC}"
    echo "السبب المحتمل: $(echo $SCAN_RESULT | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')"
fi

echo ""
