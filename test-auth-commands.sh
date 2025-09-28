#!/bin/bash

echo "🧪 اختبار نظام Auth الاحترافي بالأوامر"
echo "======================================"
echo ""

# فحص حالة الخدمات أولاً
echo "📊 حالة الخدمات:"
pm2 status

echo ""
echo "🔍 اختبار Backend API مباشرة:"
echo "================================"

# اختبار route الاحترافي
echo "1️⃣ اختبار route احترافي /api/auth-pro/login:"
curl -X POST http://localhost:3001/api/auth-pro/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\n📊 HTTP Status: %{http_code}\n" \
  -s

echo ""
echo "2️⃣ اختبار حساب الإدارة:"
curl -X POST http://localhost:3001/api/auth-pro/login \
  -H "Content-Type: application/json" \
  -d '{"email":"roo2admin@gmail.com","password":"admin123"}' \
  -w "\n📊 HTTP Status: %{http_code}\n" \
  -s

echo ""
echo "3️⃣ اختبار حساب المشرف:"
curl -X POST http://localhost:3001/api/auth-pro/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  -w "\n📊 HTTP Status: %{http_code}\n" \
  -s

echo ""
echo "🌐 اختبار Frontend الاحترافي:"
echo "=============================="

echo "4️⃣ اختبار صفحة /login:"
curl -I https://unibus.online/login -w "\n📊 HTTP Status: %{http_code}\n" -s

echo ""
echo "5️⃣ اختبار الصفحة الرئيسية:"
curl -I https://unibus.online/ -w "\n📊 HTTP Status: %{http_code}\n" -s

echo ""
echo "🔍 فحص لوجات Backend:"
echo "==================="
echo "آخر 5 رسائل من Backend:"
pm2 logs unitrans-backend --lines 5

echo ""
echo "🔍 فحص لوجات Frontend:"
echo "==================="
echo "آخر 5 رسائل من Frontend:"
pm2 logs unitrans-frontend --lines 5

echo ""
echo "✅ انتهى اختبار الأوامر!"
echo ""
echo "📋 ملخص النتائج:"
echo "==============="
echo "إذا رأيت:"
echo "  ✅ HTTP Status: 200 للمواقع"
echo "  ✅ JSON response مع success: true للـ login"
echo "  ✅ token في الاستجابة"
echo ""
echo "فالنظام يعمل بنجاح! 🎉"
echo ""
echo "🔗 جرب الآن على المتصفح:"
echo "https://unibus.online/login"
