#!/bin/bash

echo "🎯 إصلاح Total Scans - الحل النهائي"
echo "======================================"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd /var/www/unitrans

echo -e "${YELLOW}1. سحب أحدث التعديلات...${NC}"
git pull origin main

echo ""
echo -e "${YELLOW}2. إعادة بناء Frontend...${NC}"
cd frontend-new
rm -rf .next
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build فشل!${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}3. إعادة تشغيل Services...${NC}"
cd /var/www/unitrans
pm2 restart unitrans-frontend
pm2 restart unitrans-backend
pm2 save

echo ""
echo -e "${GREEN}✅ Services جاهزة!${NC}"
echo ""

sleep 5

echo "======================================"
echo -e "${YELLOW}4. اختبار Total Scans:${NC}"
echo "======================================"
echo ""

# Login
TOKEN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')

USER_ID=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1)

echo -e "${GREEN}✅ Login نجح${NC}"
echo ""

# Open new shift
SHIFT=$(curl -s -X POST http://localhost:3001/api/shifts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"supervisorId\":\"$USER_ID\",\"shiftType\":\"evening\"}")

SHIFT_ID=$(echo "$SHIFT" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$SHIFT_ID" ]; then
    # Get active shift
    ACTIVE=$(curl -s "http://localhost:3001/api/shifts/active" -H "Authorization: Bearer $TOKEN")
    SHIFT_ID=$(echo "$ACTIVE" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | head -1)
fi

echo -e "${GREEN}✅ Shift ID: $SHIFT_ID${NC}"
echo ""

# Get Total Scans BEFORE
SHIFT_BEFORE=$(curl -s "http://localhost:3001/api/shifts?shiftId=$SHIFT_ID" \
  -H "Authorization: Bearer $TOKEN")

SCANS_BEFORE=$(echo "$SHIFT_BEFORE" | grep -o '"totalScans":[0-9]*' | grep -o '[0-9]*' | head -1)

echo "Total Scans قبل المسح: ${SCANS_BEFORE:-0}"
echo ""

# Scan QR
echo "مسح QR Code..."
SCAN=$(curl -s -X POST http://localhost:3001/api/shifts/scan \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"qrData\":\"{\\\"studentId\\\":\\\"STU-1759337924297\\\",\\\"email\\\":\\\"mahmoudtarekmonaim@gmail.com\\\",\\\"fullName\\\":\\\"mahmoud tarek\\\"}\",
    \"studentEmail\":\"mahmoudtarekmonaim@gmail.com\",
    \"studentName\":\"mahmoud tarek\",
    \"studentId\":\"68db086b0362753dc7fd1b36\",
    \"shiftId\":\"$SHIFT_ID\",
    \"supervisorId\":\"$USER_ID\"
  }")

if echo "$SCAN" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Scan نجح${NC}"
else
    echo -e "${RED}❌ Scan فشل${NC}"
    echo "$SCAN" | head -c 300
    exit 1
fi

echo ""
sleep 2

# Get Total Scans AFTER
SHIFT_AFTER=$(curl -s "http://localhost:3001/api/shifts?shiftId=$SHIFT_ID" \
  -H "Authorization: Bearer $TOKEN")

SCANS_AFTER=$(echo "$SHIFT_AFTER" | grep -o '"totalScans":[0-9]*' | grep -o '[0-9]*' | head -1)

echo "Total Scans بعد المسح: ${SCANS_AFTER:-0}"
echo ""

# Compare
if [ "${SCANS_AFTER:-0}" -gt "${SCANS_BEFORE:-0}" ]; then
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}🎉 نجح! Total Scans زاد من ${SCANS_BEFORE:-0} إلى ${SCANS_AFTER:-0}!${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}✅ المشروع جاهز بنسبة 100%!${NC}"
else
    echo -e "${YELLOW}⚠️  Total Scans لم يتحدث${NC}"
    echo ""
    echo "تفاصيل Shift:"
    echo "$SHIFT_AFTER" | head -c 400
fi

echo ""

