#!/bin/bash

echo "🔧 إصلاح شامل لـ Student Portal"
echo "==============================="

cd /var/www/unitrans

echo "📥 Step 1: جلب آخر التحديثات..."
git reset --hard HEAD
git pull origin main

echo "📦 Step 2: تحديث Dependencies..."
cd backend-new
npm install
cd ../frontend-new
npm install
cd ..

echo "🏗️ Step 3: بناء Frontend..."
cd frontend-new
npm run build
cd ..

echo "🔄 Step 4: إيقاف جميع العمليات..."
pkill -f node || true
sleep 3

echo "📁 Step 5: إنشاء مجلد اللوقز..."
mkdir -p logs

echo "🚀 Step 6: تشغيل Backend..."
cd backend-new
nohup node server.js > ../logs/backend.log 2>&1 &
BACKEND_PID=$!
echo "Backend PID: $BACKEND_PID"
sleep 5

# اختبار Backend
echo "🧪 اختبار Backend..."
for i in {1..10}; do
    if curl -s http://localhost:3001/health > /dev/null; then
        echo "✅ Backend يعمل بشكل صحيح"
        break
    else
        echo "⏳ انتظار Backend... ($i/10)"
        sleep 2
    fi
done
cd ..

echo "🚀 Step 7: تشغيل Frontend..."
cd frontend-new
nohup npm start > ../logs/frontend.log 2>&1 &
FRONTEND_PID=$!
echo "Frontend PID: $FRONTEND_PID"
sleep 10

# اختبار Frontend
echo "🧪 اختبار Frontend..."
for i in {1..10}; do
    if curl -s http://localhost:3000 > /dev/null; then
        echo "✅ Frontend يعمل بشكل صحيح"
        break
    else
        echo "⏳ انتظار Frontend... ($i/10)"
        sleep 3
    fi
done
cd ..

echo "🔧 Step 8: إعادة تحميل Nginx..."
sudo systemctl reload nginx
sleep 2

echo "🧪 Step 9: اختبار شامل..."

# اختبار Student Portal محلياً
echo "🔍 اختبار Student Portal (localhost:3000):"
LOCAL_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/student/portal)
echo "HTTP Status: $LOCAL_TEST"

# اختبار عبر Nginx
echo "🔍 اختبار Student Portal (unibus.online):"
NGINX_TEST=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/student/portal)
echo "HTTP Status: $NGINX_TEST"

echo ""
echo "📊 تقرير الحالة:"
echo "================"

if [ "$LOCAL_TEST" = "200" ]; then
    echo "✅ Student Portal يعمل محلياً"
else
    echo "❌ Student Portal لا يعمل محلياً (Status: $LOCAL_TEST)"
fi

if [ "$NGINX_TEST" = "200" ]; then
    echo "✅ Student Portal يعمل عبر Nginx"
else
    echo "❌ Student Portal لا يعمل عبر Nginx (Status: $NGINX_TEST)"
fi

echo ""
echo "🔍 فحص العمليات الجارية:"
ps aux | grep -E "(node|npm)" | grep -v grep

echo ""
echo "📋 معلومات الاتصال:"
echo "==================="
echo "🌍 Student Portal: https://unibus.online/student/portal"
echo "🔧 Backend API: http://localhost:3001/health"
echo "🖥️ Frontend: http://localhost:3000"
echo "📊 Logs: tail -f logs/backend.log logs/frontend.log"

echo ""
if [ "$LOCAL_TEST" = "200" ] && [ "$NGINX_TEST" = "200" ]; then
    echo "🎉 تم إصلاح Student Portal بنجاح!"
    echo "يمكنك الآن الوصول إلى: https://unibus.online/student/portal"
else
    echo "⚠️ هناك مشاكل تحتاج إلى فحص إضافي"
    echo "تحقق من اللوقز: tail -f logs/backend.log logs/frontend.log"
fi
