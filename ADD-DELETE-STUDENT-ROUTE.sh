#!/bin/bash

echo "🔧 إضافة زر Delete للطلاب - إصلاح نهائي"
echo "=============================================="

cd /var/www/unitrans && \
git pull origin main && \
cd backend-new && \
pm2 restart unitrans-backend && \
sleep 2 && \
cd ../frontend-new && \
pm2 stop unitrans-frontend && \
rm -rf .next && \
npm run build && \
pm2 restart unitrans-frontend && \
pm2 save && \
echo "" && \
echo "✅ تم إضافة Delete للطلاب!" && \
echo "" && \
echo "📸 الآن في المتصفح:" && \
echo "  ✅ Student Search: زر 🗑️ Delete يعمل" && \
echo "  ✅ Side Expenses: زر 🗑️ Delete يعمل" && \
echo "  ✅ Driver Salaries: زر 🗑️ Delete يعمل"
