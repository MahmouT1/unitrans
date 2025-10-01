#!/bin/bash

echo "🧪 اختبار كامل لتسجيل الحضور"
echo "================================"
echo ""

# Login
echo "Login..."
curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  -o /tmp/supervisor_login.json

# استخراج Token
TOKEN=$(cat /tmp/supervisor_login.json | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')

if [ -z "$TOKEN" ]; then
    echo "❌ فشل Login"
    cat /tmp/supervisor_login.json
    exit 1
fi

echo "✅ Login نجح"
echo "Token length: ${#TOKEN}"
echo ""

# Test scan-qr
echo "================================"
echo "Scan QR Test:"
echo "================================"

curl -s -X POST http://localhost:3001/api/attendance/scan-qr \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "studentEmail":"mahmoudtarekmonaim@gmail.com",
    "studentName":"mahmoud tarek",
    "shiftId":"175932915362",
    "studentId":"68d0886b0362753dc7fd1b36",
    "college":"bis",
    "grade":"third-year"
  }'

echo ""
echo ""
echo "================================"
echo "✅ انتهى الاختبار"
echo "================================"
