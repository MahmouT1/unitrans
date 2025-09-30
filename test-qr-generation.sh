#!/bin/bash

echo "🧪 اختبار QR Generation"
echo "======================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص Backend status:"
pm2 status unitrans-backend

echo ""
echo "🔍 2️⃣ فحص generate-qr endpoint في students.js:"
grep -A 30 "router.post('/generate-qr'" backend-new/routes/students.js | head -35

echo ""
echo "🔍 3️⃣ اختبار QR Generation مع email:"
curl -X POST http://localhost:3001/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com"}' \
  -s | jq

echo ""
echo "🔍 4️⃣ اختبار QR Generation مع studentData:"
curl -X POST http://localhost:3001/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentData":{"email":"mahmoudtarekmonaim@gmail.com"}}' \
  -s | jq

echo ""
echo "✅ تم الاختبار!"
