#!/bin/bash

echo "🔧 إصلاح validation في attendance/scan-qr"
echo "==========================================="
echo ""

cd /var/www/unitrans/backend-new/routes

# Backup
cp attendance.js attendance.js.backup_validation_$(date +%Y%m%d_%H%M%S)

# إصلاح validation - جعل الحقول optional
sed -i 's/body.*appointmentSlot.*isIn.*first.*second.*/body('"'"'appointmentSlot'"'"').optional().isIn(['"'"'first'"'"', '"'"'second'"'"']),/' attendance.js
sed -i 's/body.*stationName.*notEmpty.*/body('"'"'stationName'"'"').optional(),/' attendance.js
sed -i 's/body.*stationLocation.*notEmpty.*/body('"'"'stationLocation'"'"').optional(),/' attendance.js
sed -i 's/body.*coordinates.*notEmpty.*/body('"'"'coordinates'"'"').optional()/' attendance.js

echo "✅ تم جعل الحقول optional"
echo ""

# إعادة تشغيل Backend
cd /var/www/unitrans

pm2 restart unitrans-backend
pm2 save

echo "✅ تم إعادة تشغيل Backend"
echo ""

sleep 3

# اختبار
echo "===================================="
echo "اختبار scan-qr (بدون الحقول الإضافية):"
echo "===================================="

# Login
TOKEN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')

echo "Token: ${TOKEN:0:40}..."
echo ""

# Scan
curl -s -X POST http://localhost:3001/api/attendance/scan-qr \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "qrData":"{\"studentId\":\"68d0886b0362753dc7fd1b36\",\"email\":\"mahmoudtarekmonaim@gmail.com\",\"fullName\":\"mahmoud tarek\"}",
    "shiftId":"68dd4ccc0379119ffb7bad59"
  }'

echo ""
echo ""
echo "===================================="
echo "✅ تم!"
echo "===================================="
