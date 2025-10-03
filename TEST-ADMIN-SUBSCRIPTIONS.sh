#!/bin/bash

echo "🧪 اختبار Admin Subscriptions على السيرفر"
echo "=============================================="

cd /var/www/unitrans

echo ""
echo "1️⃣ اختبار Backend API..."
echo "-------------------------------------------"

curl -s "http://localhost:3001/api/subscriptions" | jq '{
  success: .success,
  total_subscriptions: (.subscriptions | length),
  subscriptions: .subscriptions | map({
    studentName: .studentName,
    studentEmail: .studentEmail,
    amount: .amount,
    type: .subscriptionType,
    status: .status,
    startDate: .startDate
  })
}'

echo ""
echo "2️⃣ اختبار Frontend API..."
echo "-------------------------------------------"

curl -s "http://localhost:3000/api/subscriptions" | jq '{
  success: .success,
  total_subscriptions: (.subscriptions | length)
}'

echo ""
echo "✅ الاختبار اكتمل!"
