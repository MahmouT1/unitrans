#!/bin/bash

echo "🔄 إعادة تشغيل Frontend في dev mode"
echo "========================================"

cd /var/www/unitrans/frontend-new

# إيقاف Frontend القديم
pm2 delete unitrans-frontend 2>/dev/null || true

# تشغيل في dev mode (بدون الحاجة لـ build)
pm2 start npm --name unitrans-frontend -- run dev

pm2 save

echo ""
echo "✅ تم تشغيل Frontend في dev mode"
echo ""
echo "انتظر 10 ثوان..."
sleep 10

echo ""
echo "اختبار:"
curl -s http://localhost:3000/api/students/all?page=1&limit=3 | head -30

echo ""
echo ""
pm2 list
