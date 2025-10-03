#!/bin/bash

echo "🔧 إصلاح حقل الاسم في التسجيل"
echo "=============================================="

cd /var/www/unitrans && \
git pull origin main && \
cd backend-new && \
pm2 restart unitrans-backend && \
sleep 3 && \
echo "" && \
echo "✅ تم تحديث Backend!" && \
echo "" && \
echo "🧪 اختبار Registration API..." && \
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User Name",
    "email": "testname@test.com",
    "password": "test123",
    "role": "student"
  }' | jq '.' && \
echo "" && \
echo "📸 جرب الآن في المتصفح! يجب أن يعمل التسجيل ✅"
