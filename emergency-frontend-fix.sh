#!/bin/bash

echo "🚨 إصلاح طارئ للـ Frontend"
echo "=========================="

cd /var/www/unitrans

echo "🛑 إيقاف Frontend تماماً..."
pm2 stop unitrans-frontend
pm2 delete unitrans-frontend

echo ""
echo "🗑️ حذف شامل للـ cache والبناء القديم..."
cd frontend-new

# حذف كل شيء متعلق بالبناء
rm -rf .next
rm -rf node_modules/.cache
rm -rf .next/cache
rm -rf node_modules/.next
rm -rf dist
rm -rf .turbo

echo ""
echo "🧹 تنظيف npm cache..."
npm cache clean --force

echo ""
echo "📦 إعادة تثبيت dependencies..."
rm -rf node_modules
npm install

echo ""
echo "🔍 التأكد من proxy routes قبل البناء:"
echo "===================================="
if [ ! -f "app/api/login/route.js" ]; then
    echo "❌ login route مفقود - إنشاء..."
    mkdir -p app/api/login
    cat > app/api/login/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    console.log('🔄 Login Proxy Request:', body.email);
    
    const backendUrl = 'http://localhost:3001';
    const response = await fetch(`${backendUrl}/api/auth-pro/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();
    console.log('📡 Login Proxy Response:', data.success);
    
    return NextResponse.json(data, { status: response.status });

  } catch (error) {
    console.error('❌ Login proxy error:', error);
    return NextResponse.json({ 
      success: false, 
      message: 'Connection error' 
    }, { status: 500 });
  }
}
EOF
fi

if [ ! -f "app/api/register/route.js" ]; then
    echo "❌ register route مفقود - إنشاء..."
    mkdir -p app/api/register
    cat > app/api/register/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    console.log('🔄 Register Proxy Request:', body.email);
    
    const backendUrl = 'http://localhost:3001';
    const response = await fetch(`${backendUrl}/api/auth-pro/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();
    console.log('📡 Register Proxy Response:', data.success);
    
    return NextResponse.json(data, { status: response.status });

  } catch (error) {
    console.error('❌ Register proxy error:', error);
    return NextResponse.json({ 
      success: false, 
      message: 'Connection error' 
    }, { status: 500 });
  }
}
EOF
fi

echo "✅ proxy routes جاهزة"

echo ""
echo "🏗️ بناء جديد كامل..."
echo "==================="

# بناء مع إعدادات خاصة
export NODE_ENV=production
export GENERATE_SOURCEMAP=false

npm run build

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ البناء نجح!"
    
    echo ""
    echo "🔍 التحقق من البناء الجديد:"
    echo "========================="
    
    # التحقق من .next structure
    if [ -d ".next/server/app/api/login" ]; then
        echo "✅ login route مبني"
        ls -la .next/server/app/api/login/
    else
        echo "❌ login route غير مبني!"
    fi
    
    if [ -d ".next/server/app/api/register" ]; then
        echo "✅ register route مبني"
        ls -la .next/server/app/api/register/
    else
        echo "❌ register route غير مبني!"
    fi
    
    echo ""
    echo "🚀 إعادة تشغيل Frontend..."
    pm2 start npm --name "unitrans-frontend" -- start -- --port 3000
    
    echo ""
    echo "⏳ انتظار استقرار النظام..."
    sleep 10
    
    echo ""
    echo "🧪 اختبار فوري:"
    echo "==============="
    
    # اختبار direct على port 3000
    echo "1️⃣ اختبار port 3000:"
    curl -X POST http://localhost:3000/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"test@test.com","password":"123456"}' \
      -w "\n📊 Status: %{http_code}\n"
    
    echo ""
    echo "2️⃣ اختبار HTTPS domain:"
    curl -X POST https://unibus.online/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"test@test.com","password":"123456"}' \
      -w "\n📊 Status: %{http_code}\n"
    
    echo ""
    echo "3️⃣ اختبار Admin login:"
    curl -X POST https://unibus.online/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"roo2admin@gmail.com","password":"admin123"}' \
      -w "\n📊 Status: %{http_code}\n"
    
else
    echo "❌ البناء فشل!"
    echo "🔍 آخر errors:"
    tail -30 ~/.npm/_logs/*debug*.log 2>/dev/null || echo "لا توجد npm logs"
fi

echo ""
echo "📊 الحالة النهائية:"
pm2 status

echo ""
echo "✅ الإصلاح الطارئ اكتمل!"
echo "🔗 جرب الآن: https://unibus.online/login"
