#!/bin/bash

echo "🔧 إصلاح تحديث Shift في scan-qr"
echo "===================================="
echo ""

cd /var/www/unitrans/backend-new/routes

# Backup
cp attendance.js attendance.js.backup_shift_update_$(date +%Y%m%d_%H%M%S)

# تعديل scan-qr route لاستخدام id بدلاً من _id
# البحث عن السطر الذي يحدث الـ shift
sed -i "s/{ _id: shiftId }/{ id: shiftId }/g" attendance.js

echo "✅ تم تعديل shift update"
echo ""

# التحقق
grep -n "{ id: shiftId }" attendance.js

echo ""

# إعادة تشغيل Backend
cd /var/www/unitrans

pm2 restart unitrans-backend
pm2 save

echo "✅ Backend تم إعادة تشغيله"
echo ""

sleep 3

# اختبار كامل
echo "===================================="
echo "اختبار كامل:"
echo "===================================="

# Login
TOKEN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')

USER_ID=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1)

# فتح shift جديد
SHIFT=$(curl -s -X POST http://localhost:3001/api/shifts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"supervisorId\":\"$USER_ID\",\"shiftType\":\"morning\"}")

SHIFT_ID=$(echo "$SHIFT" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$SHIFT_ID" ]; then
    SHIFT_ID=$(echo "$SHIFT" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1)
fi

echo "Shift ID: $SHIFT_ID"
echo ""

# Scan QR
SCAN=$(curl -s -X POST http://localhost:3001/api/attendance/scan-qr \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"studentEmail\":\"mahmoudtarekmonaim@gmail.com\",
    \"studentName\":\"mahmoud tarek\",
    \"studentId\":\"68db086b0362753dc7fd1b36\",
    \"shiftId\":\"$SHIFT_ID\",
    \"college\":\"bis\",
    \"grade\":\"third-year\"
  }")

echo "Scan result:"
echo "$SCAN" | head -c 300
echo ""

if echo "$SCAN" | grep -q '"success":true'; then
    echo "✅ Scan نجح"
else
    echo "❌ Scan فشل"
fi

echo ""

# جلب Shift بعد Scan
SHIFT_AFTER=$(curl -s "http://localhost:3001/api/shifts?shiftId=$SHIFT_ID" \
  -H "Authorization: Bearer $TOKEN")

SCANS=$(echo "$SHIFT_AFTER" | grep -o '"totalScans":[0-9]*' | grep -o '[0-9]*')

echo "Total Scans: ${SCANS:-0}"
echo ""

if [ "${SCANS:-0}" -gt 0 ]; then
    echo "✅ Total Scans تم تحديثه!"
else
    echo "⚠️  Total Scans لم يتحدث"
fi

echo ""
