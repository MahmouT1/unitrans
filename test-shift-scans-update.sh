#!/bin/bash

echo "🎯 اختبار Total Scans وظهور السجل في Supervisor"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Login
echo "Login..."
LOGIN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}')

TOKEN=$(echo "$LOGIN" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
USER_ID=$(echo "$LOGIN" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1)

echo "✅ Token: ${TOKEN:0:30}..."
echo ""

# Open Shift
echo "===================================="
echo "فتح Shift جديد:"
echo "===================================="

SHIFT=$(curl -s -X POST http://localhost:3001/api/shifts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"supervisorId\":\"$USER_ID\",\"shiftType\":\"evening\"}")

SHIFT_ID=$(echo "$SHIFT" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$SHIFT_ID" ]; then
    ACTIVE=$(curl -s "http://localhost:3001/api/shifts/active" -H "Authorization: Bearer $TOKEN")
    SHIFT_ID=$(echo "$ACTIVE" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1)
fi

echo "✅ Shift ID: $SHIFT_ID"
echo ""

# جلب تفاصيل Shift قبل المسح
echo "===================================="
echo "تفاصيل Shift قبل المسح:"
echo "===================================="

SHIFT_BEFORE=$(curl -s "http://localhost:3001/api/shifts?shiftId=$SHIFT_ID" \
  -H "Authorization: Bearer $TOKEN")

SCANS_BEFORE=$(echo "$SHIFT_BEFORE" | grep -o '"totalScans":[0-9]*\|"scannedCount":[0-9]*' | head -1 | grep -o '[0-9]*')

echo "Total Scans قبل المسح: ${SCANS_BEFORE:-0}"
echo ""

# Scan QR
echo "===================================="
echo "مسح QR Code (mahmoud):"
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

if echo "$SCAN" | grep -q '"success":true'; then
    echo "✅ Scan نجح"
else
    echo "❌ Scan فشل: $(echo $SCAN | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')"
fi

echo ""

# جلب تفاصيل Shift بعد المسح
echo "===================================="
echo "تفاصيل Shift بعد المسح:"
echo "===================================="

sleep 2  # انتظار التحديث

SHIFT_AFTER=$(curl -s "http://localhost:3001/api/shifts?shiftId=$SHIFT_ID" \
  -H "Authorization: Bearer $TOKEN")

echo "$SHIFT_AFTER" | head -c 500
echo ""
echo ""

SCANS_AFTER=$(echo "$SHIFT_AFTER" | grep -o '"totalScans":[0-9]*\|"scannedCount":[0-9]*' | head -1 | grep -o '[0-9]*')

echo "Total Scans بعد المسح: ${SCANS_AFTER:-0}"
echo ""

# جلب السجلات من Shift
RECORDS_IN_SHIFT=$(echo "$SHIFT_AFTER" | grep -o '"attendanceRecords":\[[^\]]*\]')

echo "السجلات في Shift:"
echo "$RECORDS_IN_SHIFT"

echo ""

# جلب سجلات اليوم
echo "===================================="
echo "سجلات الحضور اليوم:"
echo "===================================="

TODAY=$(curl -s "http://localhost:3001/api/attendance/today" \
  -H "Authorization: Bearer $TOKEN")

TODAY_COUNT=$(echo "$TODAY" | grep -o '"studentName":"mahmoud tarek"' | wc -l)

echo "سجلات mahmoud اليوم: $TODAY_COUNT"

echo ""

# Frontend API
echo "===================================="
echo "Frontend API (/api/attendance/today):"
echo "===================================="

FRONTEND=$(curl -s "http://localhost:3000/api/attendance/today")

FRONTEND_COUNT=$(echo "$FRONTEND" | grep -o '"studentName":"mahmoud tarek"' | wc -l)

echo "Frontend - سجلات mahmoud: $FRONTEND_COUNT"

echo ""
echo "===================================="
echo "النتيجة:"
echo "===================================="
echo ""
echo "Before: Total Scans = ${SCANS_BEFORE:-0}"
echo "After:  Total Scans = ${SCANS_AFTER:-0}"
echo ""

if [ "${SCANS_AFTER:-0}" -gt "${SCANS_BEFORE:-0}" ]; then
    echo "✅ Total Scans زاد!"
else
    echo "⚠️  Total Scans لم يتحدث"
fi

echo ""
echo "Backend /today: mahmoud ظهر $TODAY_COUNT مرة"
echo "Frontend /today: mahmoud ظهر $FRONTEND_COUNT مرة"
echo ""

if [ $TODAY_COUNT -gt 0 ] && [ $FRONTEND_COUNT -gt 0 ]; then
    echo "✅ السجلات تظهر في Backend و Frontend!"
else
    echo "⚠️  السجلات لا تظهر بشكل كامل"
fi

echo ""
