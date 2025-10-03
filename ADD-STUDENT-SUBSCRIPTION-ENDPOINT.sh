#!/bin/bash

echo "🔧 إضافة Student Subscription Endpoint"
echo "=============================================="

cd /var/www/unitrans && \
git pull origin main && \
cd backend-new && \
pm2 restart unitrans-backend && \
sleep 3 && \
echo "" && \
echo "✅ Backend تم إعادة تشغيله!" && \
echo "" && \
echo "🧪 اختبار API..." && \
echo "-------------------------------------------" && \
curl -s "http://localhost:3001/api/subscriptions/student?email=karimahmed@gmail.com" | jq '.' && \
echo "" && \
echo "✅ الاختبار اكتمل!" && \
echo "" && \
echo "📊 يجب أن يظهر:" && \
echo "  - totalPaid: 2200 EGP" && \
echo "  - confirmationDate: التاريخ" && \
echo "  - renewalDate: التاريخ" && \
echo "  - status: active" && \
echo "  - totalPayments: 2"

