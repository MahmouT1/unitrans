#!/bin/bash

echo "🔧 رسالة بسيطة أعلى الشاشة مع زر OK"
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
echo "✅ تم التحديث!" && \
echo "" && \
echo "📱 الآن على الموبايل:" && \
echo "  ✅ رسالة بسيطة في أعلى الشاشة" && \
echo "  ✅ لون أخضر" && \
echo "  ✅ زر OK لإغلاقها يدوياً" && \
echo "  ✅ بدون أي اهتزاز أو animation"
