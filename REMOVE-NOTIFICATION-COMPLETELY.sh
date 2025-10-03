#!/bin/bash

echo "🗑️  إزالة الإشعارات نهائياً"
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
echo "✅ تم إزالة الإشعارات نهائياً!" && \
echo "" && \
echo "📱 الآن عند عمل QR Scan:" && \
echo "  ✅ لا رسالة" && \
echo "  ✅ لا اهتزاز" && \
echo "  ✅ لا شيء - فقط تسجيل الحضور بصمت!"
