#!/bin/bash

echo "🧪 اختبار جميع الحسابات على السيرفر - إصدار محسن"
echo "============================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص حالة الخدمات:"
echo "====================="

echo "🔍 فحص PM2 services:"
pm2 status

echo ""
echo "🔍 فحص backend logs:"
pm2 logs unitrans-backend --lines 3

echo ""
echo "🔧 2️⃣ اختبار API endpoints:"
echo "========================="

echo "🔍 اختبار auth-api/login:"
AUTH_API_TEST=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/auth-api/login)
echo "Auth API Login: $AUTH_API_TEST"

echo ""
echo "🔍 اختبار auth-pro/login:"
AUTH_PRO_TEST=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online:3001/api/auth-pro/login)
echo "Auth Pro Login: $AUTH_PRO_TEST"

echo ""
echo "🔧 3️⃣ اختبار Login بالبيانات:"
echo "==========================="

echo "🔍 اختبار login مع بيانات الطالب (test@test.com):"
echo "=============================================="
STUDENT_LOGIN=$(curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -s)
echo "Response: $STUDENT_LOGIN"

echo ""
echo "🔍 اختبار login مع بيانات الإدارة (roo2admin@gmail.com):"
echo "====================================================="
ADMIN_LOGIN=$(curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"roo2admin@gmail.com","password":"admin123"}' \
  -s)
echo "Response: $ADMIN_LOGIN"

echo ""
echo "🔍 اختبار login مع بيانات المشرف (ahmedazab@gmail.com):"
echo "====================================================="
SUPERVISOR_LOGIN=$(curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  -s)
echo "Response: $SUPERVISOR_LOGIN"

echo ""
echo "🔧 4️⃣ اختبار Register:"
echo "===================="

echo "🔍 اختبار register مع بيانات جديدة:"
echo "================================="
NEW_USER_REGISTER=$(curl -X POST https://unibus.online/auth-api/register \
  -H "Content-Type: application/json" \
  -d '{"email":"newuser@test.com","password":"123456","fullName":"New User","role":"student"}' \
  -s)
echo "Response: $NEW_USER_REGISTER"

echo ""
echo "🔧 5️⃣ اختبار صفحة Login:"
echo "======================"

echo "🔍 اختبار صفحة Login:"
LOGIN_PAGE=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/login)
echo "Login Page: $LOGIN_PAGE"

echo ""
echo "🔍 اختبار صفحة Student Portal:"
STUDENT_PORTAL=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/student/portal)
echo "Student Portal: $STUDENT_PORTAL"

echo ""
echo "🔍 اختبار صفحة Admin Dashboard:"
ADMIN_DASHBOARD=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/admin/dashboard)
echo "Admin Dashboard: $ADMIN_DASHBOARD"

echo ""
echo "🔍 اختبار صفحة Supervisor Dashboard:"
SUPERVISOR_DASHBOARD=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/admin/supervisor-dashboard)
echo "Supervisor Dashboard: $SUPERVISOR_DASHBOARD"

echo ""
echo "🔧 6️⃣ فحص Backend Logs:"
echo "====================="

echo "🔍 فحص backend logs:"
pm2 logs unitrans-backend --lines 10

echo ""
echo "📊 7️⃣ تقرير الاختبار النهائي:"
echo "=========================="

echo "✅ نتائج الاختبار:"
echo "   📱 Login Page: $LOGIN_PAGE"
echo "   🔐 Auth API: $AUTH_API_TEST"
echo "   🔐 Auth Pro: $AUTH_PRO_TEST"
echo "   🏠 Student Portal: $STUDENT_PORTAL"
echo "   🔧 Admin Dashboard: $ADMIN_DASHBOARD"
echo "   👨‍💼 Supervisor Dashboard: $SUPERVISOR_DASHBOARD"

echo ""
echo "🎯 حالة الحسابات:"
echo "   👨‍🎓 Student (test@test.com): $(echo $STUDENT_LOGIN | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   👨‍💼 Admin (roo2admin@gmail.com): $(echo $ADMIN_LOGIN | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   👨‍💼 Supervisor (ahmedazab@gmail.com): $(echo $SUPERVISOR_LOGIN | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   ✨ New User Register: $(echo $NEW_USER_REGISTER | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"

echo ""
echo "🎉 تم اختبار جميع الحسابات على السيرفر!"
echo "🌐 يمكنك الآن اختبار في المتصفح:"
echo "   🔗 https://unibus.online/login"
echo "   📧 test@test.com / 123456"
echo "   📧 roo2admin@gmail.com / admin123"
echo "   📧 ahmedazab@gmail.com / supervisor123"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
