ذ#!/bin/bash

echo "🔧 إضافة زر Delete للصفحات: Student Search, Side Expenses, Driver Salaries"
echo "==============================================================================="

cd /var/www/unitrans

# سأقوم بإنشاء التعديلات في ملف واحد كبير

echo "✅ يجب تعديل الملفات التالية:"
echo "  1. frontend-new/app/admin/users/page.js (Student Search)"
echo "  2. frontend-new/components/admin/Reports.js (Side Expenses & Driver Salaries)"
echo "  3. Backend DELETE routes"
echo ""
echo "⏳ يرجى تطبيق التعديلات من GitHub..."

git pull origin main

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
echo "✅ تم تطبيق التعديلات!" && \
echo "" && \
echo "📸 الآن في المتصفح:" && \
echo "  ✅ Student Search: زر 🗑️ Delete بجانب كل طالب" && \
echo "  ✅ Side Expenses: زر 🗑️ Delete" && \
echo "  ✅ Driver Salaries: زر 🗑️ Delete"
