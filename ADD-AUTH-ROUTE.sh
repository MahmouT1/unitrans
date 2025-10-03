#!/bin/bash

echo "🔧 إضافة /api/auth route"
echo "=============================================="

cd /var/www/unitrans && \
git pull origin main && \
cd backend-new && \
pm2 restart unitrans-backend && \
sleep 3 && \
echo "" && \
echo "✅ تم إضافة /api/auth route!" && \
echo "" && \
echo "🧪 اختبار Registration API..." && \
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Final Test User",
    "email": "finaltest@test.com",
    "password": "test123",
    "role": "student"
  }' | jq '.' && \
echo "" && \
echo "📸 جرب الآن في المتصفح!"
