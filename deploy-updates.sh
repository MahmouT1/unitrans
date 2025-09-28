#!/bin/bash

# =================================================
# 🚀 نشر التحديثات الجديدة على سيرفر الدومين
# =================================================

echo "🔄 بدء نشر التحديثات الجديدة..."

# 1️⃣ سحب آخر التحديثات من GitHub
echo "📥 سحب آخر التحديثات من GitHub..."
cd /var/www/unitrans
git pull origin main

# 2️⃣ تثبيت المكتبات الجديدة في Backend
echo "📦 تثبيت المكتبات الجديدة في Backend..."
cd backend-new
npm install qrcode
cd ..

# 3️⃣ إعادة تشغيل Backend
echo "🔄 إعادة تشغيل Backend..."
pm2 restart unitrans-backend

# 4️⃣ بناء Frontend مع التحديثات الجديدة
echo "🔨 بناء Frontend مع التحديثات..."
cd frontend-new
rm -rf .next
npm run build
cd ..

# 5️⃣ إعادة تشغيل Frontend
echo "🔄 إعادة تشغيل Frontend..."
pm2 restart unitrans-frontend

# 6️⃣ فحص حالة الخدمات
echo "📊 فحص حالة الخدمات..."
pm2 status

# 7️⃣ اختبار الـ APIs الجديدة
echo "🧪 اختبار الـ APIs الجديدة..."
echo "🔗 اختبار API تسجيل الطلاب:"
curl -X GET https://unibus.online:3001/api/students/all?page=1&limit=5

echo ""
echo "🔗 اختبار API الحضور:"
curl -X GET https://unibus.online:3001/api/attendance/all-records

echo ""
echo "🔗 اختبار الصحة العامة:"
curl -X GET https://unibus.online:3001/health

echo ""
echo "✅ تم نشر جميع التحديثات بنجاح!"
echo "🌐 يمكنك الآن اختبار النظام على: https://unibus.online"
echo ""
echo "📋 الميزات الجديدة:"
echo "  - ✅ تسجيل طلاب جديد مع QR Code"
echo "  - ✅ تتبع عدد أيام الحضور تلقائياً"
echo "  - ✅ عرض بيانات الحضور في البحث"
echo "  - ✅ APIs محسنة للطلاب والحضور"
