#!/bin/bash

echo "🗑️ إزالة Recent Activity من Admin Dashboard"
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
echo "✅ تم إزالة Recent Activity!" && \
echo "" && \
echo "📱 افتح المتصفح:" && \
echo "  🔗 unibus.online/admin/dashboard" && \
echo "  ✅ Recent Activity اختفت!"
