#!/bin/bash

echo "🚨 الحل النهائي لـ Auth - إصلاح جذري"
echo "=================================="

cd /var/www/unitrans

echo "🔄 إيقاف جميع العمليات..."
pkill -f node || true
sleep 5

echo "🧹 تنظيف شامل..."
rm -rf frontend-new/.next
rm -rf frontend-new/node_modules/.cache
rm -rf frontend-new/app/api/login
rm -rf frontend-new/app/api/register

echo "🔧 إنشاء مسارات Auth الصحيحة..."

# إنشاء مسار /api/login
mkdir -p frontend-new/app/api/login
cat > frontend-new/app/api/login/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    
    const response = await fetch('http://localhost:3001/api/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();
    
    return NextResponse.json(data, {
      status: response.status
    });

  } catch (error) {
    return NextResponse.json({
      success: false,
      message: 'خطأ في الاتصال بالخادم'
    }, { status: 500 });
  }
}
EOF

# إنشاء مسار /api/register
mkdir -p frontend-new/app/api/register
cat > frontend-new/app/api/register/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    
    const response = await fetch('http://localhost:3001/api/auth/register', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();
    
    return NextResponse.json(data, {
      status: response.status
    });

  } catch (error) {
    return NextResponse.json({
      success: false,
      message: 'خطأ في الاتصال بالخادم'
    }, { status: 500 });
  }
}
EOF

echo "📁 فحص المسارات الجديدة..."
ls -la frontend-new/app/api/

echo "🏗️ إعادة بناء Frontend من الصفر..."
cd frontend-new
rm -rf .next
rm -rf node_modules/.cache
npm run build
cd ..

echo "🚀 تشغيل Backend..."
cd backend-new
nohup node server.js > ../logs/backend.log 2>&1 &
BACKEND_PID=$!
echo "Backend PID: $BACKEND_PID"
sleep 8

# اختبار Backend
echo "🔍 اختبار Backend..."
for i in {1..10}; do
    if curl -s http://localhost:3001/health > /dev/null; then
        echo "✅ Backend يعمل"
        break
    else
        echo "⏳ انتظار Backend... ($i/10)"
        sleep 2
    fi
done
cd ..

echo "🚀 تشغيل Frontend..."
cd frontend-new
nohup npm start > ../logs/frontend.log 2>&1 &
FRONTEND_PID=$!
echo "Frontend PID: $FRONTEND_PID"
sleep 15

# اختبار Frontend
echo "🔍 اختبار Frontend..."
for i in {1..10}; do
    if curl -s http://localhost:3000 > /dev/null; then
        echo "✅ Frontend يعمل"
        break
    else
        echo "⏳ انتظار Frontend... ($i/10)"
        sleep 3
    fi
done
cd ..

echo "🧪 اختبار Auth النهائي..."
sleep 5

# اختبار /api/login
echo "🔍 اختبار /api/login:"
LOGIN_TEST=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/login -H "Content-Type: application/json" -d '{"email":"test@test.com","password":"test123"}')
echo "Login API Status: $LOGIN_TEST"

# اختبار /api/register
echo "🔍 اختبار /api/register:"
REGISTER_TEST=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/register -H "Content-Type: application/json" -d '{"email":"test2@test.com","password":"test123","fullName":"Test User","role":"student"}')
echo "Register API Status: $REGISTER_TEST"

# اختبار مباشر للمسارات
echo "🔍 اختبار مباشر للمسارات..."
curl -s -X POST http://localhost:3000/api/login -H "Content-Type: application/json" -d '{"email":"test@test.com","password":"test123"}' | head -3

echo ""
echo "📊 تقرير الحالة النهائي:"
echo "======================="

if [ "$LOGIN_TEST" = "200" ] || [ "$LOGIN_TEST" = "401" ]; then
    echo "✅ /api/login يعمل (Status: $LOGIN_TEST)"
else
    echo "❌ /api/login لا يعمل (Status: $LOGIN_TEST)"
fi

if [ "$REGISTER_TEST" = "200" ] || [ "$REGISTER_TEST" = "401" ]; then
    echo "✅ /api/register يعمل (Status: $REGISTER_TEST)"
else
    echo "❌ /api/register لا يعمل (Status: $REGISTER_TEST)"
fi

echo ""
echo "🌍 روابط الاختبار:"
echo "=================="
echo "🔗 Login: https://unibus.online/login"
echo "🔗 Auth: https://unibus.online/auth"

if [ "$LOGIN_TEST" = "200" ] || [ "$LOGIN_TEST" = "401" ]; then
    echo ""
    echo "🎉 تم إصلاح Auth بنجاح!"
    echo "يمكنك الآن تسجيل الدخول من: https://unibus.online/login"
else
    echo ""
    echo "⚠️ لا يزال هناك مشاكل"
    echo "تحقق من اللوقز: tail -f logs/backend.log logs/frontend.log"
    echo ""
    echo "🔍 فحص إضافي:"
    echo "curl -X POST http://localhost:3000/api/login -H 'Content-Type: application/json' -d '{\"email\":\"test@test.com\",\"password\":\"test123\"}'"
fi
