#!/bin/bash

echo "🔧 إصلاح مسارات Auth المكسورة"
echo "============================="

cd /var/www/unitrans

echo "📥 جلب آخر التحديثات..."
git reset --hard HEAD
git pull origin main

echo "🔍 فحص المسارات الحالية..."

# فحص المسارات الموجودة
echo "📁 مسارات API الموجودة:"
find frontend-new/app/api -name "*.js" | head -10

echo ""
echo "🔧 إصلاح مسارات Auth..."

# إنشاء مسار /api/login الصحيح
mkdir -p frontend-new/app/api/login
cat > frontend-new/app/api/login/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    console.log('🔄 Login API: Request received');
    const body = await request.json();
    console.log('📥 Login API: Request data:', { email: body.email, hasPassword: !!body.password });
    
    // Forward to backend
    const backendUrl = 'http://localhost:3001/api/auth/login';
    
    const response = await fetch(backendUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();
    console.log('📤 Login API: Backend response:', data);
    
    return NextResponse.json(data, {
      status: response.status,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      }
    });

  } catch (error) {
    console.error('❌ Login API Error:', error);
    return NextResponse.json({
      success: false,
      message: 'خطأ في الاتصال بالخادم'
    }, { status: 500 });
  }
}

export async function OPTIONS(request) {
  return new NextResponse(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    }
  });
}
EOF

# إنشاء مسار /api/register الصحيح
mkdir -p frontend-new/app/api/register
cat > frontend-new/app/api/register/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    console.log('🔄 Register API: Request received');
    const body = await request.json();
    console.log('📥 Register API: Request data:', { email: body.email, hasPassword: !!body.password });
    
    // Forward to backend
    const backendUrl = 'http://localhost:3001/api/auth/register';
    
    const response = await fetch(backendUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();
    console.log('📤 Register API: Backend response:', data);
    
    return NextResponse.json(data, {
      status: response.status,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      }
    });

  } catch (error) {
    console.error('❌ Register API Error:', error);
    return NextResponse.json({
      success: false,
      message: 'خطأ في الاتصال بالخادم'
    }, { status: 500 });
  }
}

export async function OPTIONS(request) {
  return new NextResponse(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    }
  });
}
EOF

echo "🏗️ إعادة بناء Frontend..."
cd frontend-new
npm run build
cd ..

echo "🔄 إعادة تشغيل الخدمات..."
pkill -f node || true
sleep 3

# تشغيل Backend
cd backend-new
nohup node server.js > ../logs/backend.log 2>&1 &
echo "Backend started"
sleep 3
cd ..

# تشغيل Frontend
cd frontend-new
nohup npm start > ../logs/frontend.log 2>&1 &
echo "Frontend started"
sleep 5
cd ..

echo "🧪 اختبار Auth..."
sleep 3

# اختبار /api/login
echo "🔍 اختبار /api/login:"
LOGIN_TEST=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/login -H "Content-Type: application/json" -d '{"email":"test@test.com","password":"test123"}')
echo "HTTP Status: $LOGIN_TEST"

# اختبار /api/register
echo "🔍 اختبار /api/register:"
REGISTER_TEST=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/register -H "Content-Type: application/json" -d '{"email":"test2@test.com","password":"test123","fullName":"Test User","role":"student"}')
echo "HTTP Status: $REGISTER_TEST"

echo ""
echo "📊 تقرير الحالة:"
echo "================"

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
echo "🌍 اختبار Auth عبر الموقع:"
echo "=========================="
echo "🔗 Login: https://unibus.online/login"
echo "🔗 Auth: https://unibus.online/auth"

echo ""
if [ "$LOGIN_TEST" = "200" ] || [ "$LOGIN_TEST" = "401" ]; then
    echo "🎉 تم إصلاح Auth بنجاح!"
    echo "يمكنك الآن تسجيل الدخول من: https://unibus.online/login"
else
    echo "⚠️ هناك مشاكل تحتاج فحص إضافي"
    echo "تحقق من اللوقز: tail -f logs/backend.log logs/frontend.log"
fi
