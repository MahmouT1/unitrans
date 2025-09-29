#!/bin/bash

echo "🚨 إصلاح فوري لـ Auth - الطوارئ"
echo "=============================="

cd /var/www/unitrans

echo "🔄 إيقاف جميع العمليات..."
pkill -f node || true
sleep 3

echo "📁 فحص المسارات الموجودة..."
ls -la frontend-new/app/api/

echo "🔧 إنشاء مسارات Auth الصحيحة..."

# حذف المسارات القديمة إذا كانت موجودة
rm -rf frontend-new/app/api/login
rm -rf frontend-new/app/api/register

# إنشاء مسار /api/login
mkdir -p frontend-new/app/api/login
cat > frontend-new/app/api/login/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    console.log('🔄 Login API: Request received');
    const body = await request.json();
    
    // Forward to backend
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
    console.error('❌ Login API Error:', error);
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
    console.log('🔄 Register API: Request received');
    const body = await request.json();
    
    // Forward to backend
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
    console.error('❌ Register API Error:', error);
    return NextResponse.json({
      success: false,
      message: 'خطأ في الاتصال بالخادم'
    }, { status: 500 });
  }
}
EOF

echo "📁 فحص المسارات الجديدة..."
ls -la frontend-new/app/api/

echo "🏗️ إعادة بناء Frontend..."
cd frontend-new
rm -rf .next
npm run build
cd ..

echo "🚀 تشغيل Backend..."
cd backend-new
nohup node server.js > ../logs/backend.log 2>&1 &
echo "Backend PID: $!"
sleep 5
cd ..

echo "🚀 تشغيل Frontend..."
cd frontend-new
nohup npm start > ../logs/frontend.log 2>&1 &
echo "Frontend PID: $!"
sleep 10
cd ..

echo "🧪 اختبار Auth بعد الإصلاح..."
sleep 5

# اختبار Backend أولاً
echo "🔍 اختبار Backend:"
BACKEND_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/health)
echo "Backend Status: $BACKEND_TEST"

# اختبار Frontend
echo "🔍 اختبار Frontend:"
FRONTEND_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
echo "Frontend Status: $FRONTEND_TEST"

# اختبار /api/login
echo "🔍 اختبار /api/login:"
LOGIN_TEST=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/login -H "Content-Type: application/json" -d '{"email":"test@test.com","password":"test123"}')
echo "Login API Status: $LOGIN_TEST"

# اختبار /api/register
echo "🔍 اختبار /api/register:"
REGISTER_TEST=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/register -H "Content-Type: application/json" -d '{"email":"test2@test.com","password":"test123","fullName":"Test User","role":"student"}')
echo "Register API Status: $REGISTER_TEST"

echo ""
echo "📊 تقرير الحالة النهائي:"
echo "======================="

if [ "$BACKEND_TEST" = "200" ]; then
    echo "✅ Backend يعمل"
else
    echo "❌ Backend لا يعمل (Status: $BACKEND_TEST)"
fi

if [ "$FRONTEND_TEST" = "200" ]; then
    echo "✅ Frontend يعمل"
else
    echo "❌ Frontend لا يعمل (Status: $FRONTEND_TEST)"
fi

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
fi
