#!/bin/bash

echo "🔧 إزالة كل التبديل التلقائي - حرية كاملة"
echo "=============================================="

cd /var/www/unitrans && \
git pull origin main && \
cd frontend-new && \
pm2 stop unitrans-frontend && \
rm -rf .next && \
npm run build && \
pm2 restart unitrans-frontend && \
pm2 save && \
echo "" && \
echo "✅ الإصلاح النهائي!" && \
echo "" && \
echo "📱 الآن بعد QR Scan:" && \
echo "  ✅ تبقى في نفس التاب" && \
echo "  ✅ تتنقل بحرية بين جميع الأزرار" && \
echo "  ✅ لا تغيير تلقائي" && \
echo "  ✅ لا رجوع تلقائي" && \
echo "  ✅ لا اهتزاز" && \
echo "" && \
echo "📋 لعرض بيانات الطالب:" && \
echo "  اضغط يدوياً على 👤 Student Details"
