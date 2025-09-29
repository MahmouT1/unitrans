#!/bin/bash

echo "🧪 اختبار الحسابات على السيرفر قبل المتصفح"
echo "========================================"

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص حالة النظام:"
echo "====================="

echo "🔍 فحص PM2 processes:"
pm2 status

echo ""
echo "🔍 فحص backend logs:"
pm2 logs unitrans-backend --lines 5

echo ""
echo "🧪 2️⃣ اختبار الحسابات المختلفة:"
echo "============================="

echo ""
echo "🔑 اختبار حساب الطالب (test@test.com):"
echo "====================================="
STUDENT_LOGIN=$(curl -s -X POST https://unibus.online:3001/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\nHTTP Status: %{http_code}\n")

echo "$STUDENT_LOGIN"

echo ""
echo "🔑 اختبار حساب المشرف (supervisor@test.com):"
echo "=========================================="
SUPERVISOR_LOGIN=$(curl -s -X POST https://unibus.online:3001/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"supervisor@test.com","password":"123456"}' \
  -w "\nHTTP Status: %{http_code}\n")

echo "$SUPERVISOR_LOGIN"

echo ""
echo "🔑 اختبار حساب المدير (admin@test.com):"
echo "====================================="
ADMIN_LOGIN=$(curl -s -X POST https://unibus.online:3001/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"123456"}' \
  -w "\nHTTP Status: %{http_code}\n")

echo "$ADMIN_LOGIN"

echo ""
echo "🧪 3️⃣ اختبار إنشاء حساب جديد:"
echo "============================="

echo ""
echo "📝 اختبار إنشاء حساب طالب جديد:"
echo "=============================="
NEW_STUDENT=$(curl -s -X POST https://unibus.online:3001/api/register \
  -H "Content-Type: application/json" \
  -d '{"email":"newstudent@test.com","password":"123456","fullName":"New Student","role":"student"}' \
  -w "\nHTTP Status: %{http_code}\n")

echo "$NEW_STUDENT"

echo ""
echo "📝 اختبار إنشاء حساب مشرف جديد:"
echo "=============================="
NEW_SUPERVISOR=$(curl -s -X POST https://unibus.online:3001/api/register \
  -H "Content-Type: application/json" \
  -d '{"email":"newsupervisor@test.com","password":"123456","fullName":"New Supervisor","role":"supervisor"}' \
  -w "\nHTTP Status: %{http_code}\n")

echo "$NEW_SUPERVISOR"

echo ""
echo "🧪 4️⃣ اختبار من خلال Nginx:"
echo "=========================="

echo ""
echo "🔍 اختبار /api/login من خلال Nginx:"
echo "================================="
NGINX_LOGIN=$(curl -s -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\nHTTP Status: %{http_code}\n")

echo "$NGINX_LOGIN"

echo ""
echo "🔍 اختبار /api/register من خلال Nginx:"
echo "===================================="
NGINX_REGISTER=$(curl -s -X POST https://unibus.online/api/register \
  -H "Content-Type: application/json" \
  -d '{"email":"nginxtest@test.com","password":"123456","fullName":"Nginx Test User","role":"student"}' \
  -w "\nHTTP Status: %{http_code}\n")

echo "$NGINX_REGISTER"

echo ""
echo "🧪 5️⃣ اختبار صفحات الواجهة:"
echo "=========================="

echo ""
echo "🔍 اختبار صفحة Login:"
echo "===================="
LOGIN_PAGE=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/login)
echo "$LOGIN_PAGE"

echo ""
echo "🔍 اختبار صفحة Student Portal:"
echo "============================="
PORTAL_PAGE=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/student/portal)
echo "$PORTAL_PAGE"

echo ""
echo "🔍 اختبار صفحة Admin Dashboard:"
echo "=============================="
ADMIN_PAGE=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/admin/dashboard)
echo "$ADMIN_PAGE"

echo ""
echo "🧪 6️⃣ اختبار Health Check:"
echo "========================="

echo ""
echo "🔍 اختبار Health Check:"
echo "======================"
HEALTH_CHECK=$(curl -s https://unibus.online:3001/api/health)
echo "$HEALTH_CHECK"

echo ""
echo "📊 7️⃣ تقرير الاختبار النهائي:"
echo "=========================="

echo "✅ نتائج الاختبار:"
echo "   🔑 Student Login: $(echo "$STUDENT_LOGIN" | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   🔑 Supervisor Login: $(echo "$SUPERVISOR_LOGIN" | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   🔑 Admin Login: $(echo "$ADMIN_LOGIN" | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   📝 New Student Registration: $(echo "$NEW_STUDENT" | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   📝 New Supervisor Registration: $(echo "$NEW_SUPERVISOR" | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   🌐 Nginx Login: $(echo "$NGINX_LOGIN" | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   🌐 Nginx Register: $(echo "$NGINX_REGISTER" | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   📱 Login Page: $LOGIN_PAGE"
echo "   🏠 Portal Page: $PORTAL_PAGE"
echo "   🔧 Admin Page: $ADMIN_PAGE"

echo ""
echo "🎯 الحسابات المتاحة للاختبار:"
echo "============================"
echo "   📧 test@test.com / 123456 (Student)"
echo "   📧 supervisor@test.com / 123456 (Supervisor)"
echo "   📧 admin@test.com / 123456 (Admin)"
echo "   📧 newstudent@test.com / 123456 (New Student)"
echo "   📧 newsupervisor@test.com / 123456 (New Supervisor)"

echo ""
echo "🌐 روابط الاختبار:"
echo "================="
echo "   🔗 Login: https://unibus.online/login"
echo "   🔗 Student Portal: https://unibus.online/student/portal"
echo "   🔗 Admin Dashboard: https://unibus.online/admin/dashboard"
echo "   🔗 Supervisor Dashboard: https://unibus.online/admin/supervisor-dashboard"

echo ""
echo "🎉 تم اختبار جميع الحسابات على السيرفر!"
echo "✅ النظام جاهز للاختبار في المتصفح!"
