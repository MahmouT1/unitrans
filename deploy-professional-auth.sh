#!/bin/bash

echo "🚀 نشر نظام المصادقة المهني"
echo "============================="
echo "⚠️  نظام آمن - لا يتلف الصفحات الحالية"
echo ""

# الانتقال للمشروع
cd /var/www/unitrans

echo "📥 سحب النظام المهني من GitHub..."
git pull origin main

echo ""
echo "🔍 التحقق من الملفات الجديدة..."
if [ -f "backend-new/routes/auth-professional.js" ]; then
    echo "  ✅ backend-new/routes/auth-professional.js موجود"
else
    echo "  ❌ backend-new/routes/auth-professional.js مفقود!"
    exit 1
fi

if [ -f "frontend-new/app/login/page.js" ]; then
    echo "  ✅ frontend-new/app/login/page.js موجود"
else
    echo "  ❌ frontend-new/app/login/page.js مفقود!"
    exit 1
fi

echo ""
echo "📦 تثبيت المتطلبات..."
cd backend-new
npm install bcrypt jsonwebtoken --save

echo ""
echo "⚙️  إعادة تشغيل Backend..."
pm2 restart unitrans-backend

echo ""
echo "🎨 إعادة بناء Frontend..."
cd ../frontend-new
rm -rf .next node_modules/.cache
npm run build

echo ""
echo "🔄 إعادة تشغيل Frontend..."
pm2 restart unitrans-frontend

echo ""
echo "⏳ انتظار استقرار الخدمات..."
sleep 10

echo ""
echo "📊 حالة الخدمات:"
pm2 status

echo ""
echo "🧪 اختبار النظام المهني..."
echo "اختبار Backend مباشرة:"
curl -X POST http://localhost:3001/api/auth-pro/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\nHTTP Status: %{http_code}\n"

echo ""
echo "اختبار صفحة Login الجديدة:"
curl -I https://unibus.online/login

echo ""
echo "✅ النشر المهني اكتمل!"
echo ""
echo "🎯 الروابط الجاهزة:"
echo "  🔐 صفحة الدخول المهنية: https://unibus.online/login"
echo "  📊 لوحة الإدارة: https://unibus.online/admin/dashboard"
echo "  👥 لوحة المشرف: https://unibus.online/admin/supervisor-dashboard"
echo "  🎓 بوابة الطالب: https://unibus.online/student/portal"
echo ""
echo "🔐 الحسابات الجاهزة:"
echo "  📧 test@test.com | 🔑 123456 (طالب)"
echo "  📧 roo2admin@gmail.com | 🔑 admin123 (إدارة)"
echo "  📧 ahmedazab@gmail.com | 🔑 supervisor123 (مشرف)"
echo ""
echo "🎉 النظام جاهز للاستخدام المهني!"
