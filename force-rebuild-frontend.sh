#!/bin/bash

echo "💪 إعادة بناء قوية للـ Frontend"
echo "================================"

cd /var/www/unitrans

echo "📥 سحب آخر التحديثات..."
git pull origin main

echo ""
echo "🛑 إيقاف Frontend تماماً..."
pm2 stop unitrans-frontend

echo ""
echo "🗑️ حذف cache شامل..."
cd frontend-new

# حذف كل cache ممكن
rm -rf .next
rm -rf node_modules/.cache  
rm -rf .next/cache
rm -rf node_modules/.next
rm -rf dist

echo ""
echo "🔍 التحقق من proxy routes قبل البناء:"
echo "--------------------------------------"
if [ -f "app/api/login/route.js" ]; then
    echo "✅ login route موجود"
    echo "   📄 المحتوى:"
    head -5 app/api/login/route.js
else
    echo "❌ login route مفقود - إنشاء..."
    mkdir -p app/api/login
    cat > app/api/login/route.js << 'LOGINEOF'
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
LOGINEOF
    echo "✅ login route تم إنشاؤه"
fi

if [ -f "app/api/register/route.js" ]; then
    echo "✅ register route موجود"
    echo "   📄 المحتوى:"
    head -5 app/api/register/route.js
else
    echo "❌ register route مفقود - إنشاء..."
    mkdir -p app/api/register
    cat > app/api/register/route.js << 'REGEOF'
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
REGEOF
    echo "✅ register route تم إنشاؤه"
fi

echo ""
echo "🔨 بناء جديد كامل (قد يستغرق دقائق...):"
echo "========================================="

# تنظيف كامل لـ npm cache
npm cache clean --force

# إعادة تثبيت dependencies (للتأكد)
npm install

# بناء مع verbose logging
echo "🏗️ البناء بدأ..."
npm run build

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ البناء نجح!"
    
    echo ""
    echo "🔍 التحقق من routes في البناء الجديد:"
    if [ -f ".next/server/app/api/login/route.js" ]; then
        echo "✅ login route مبني بنجاح"
    else
        echo "❌ login route لم يُبنى!"
    fi
    
    if [ -f ".next/server/app/api/register/route.js" ]; then
        echo "✅ register route مبني بنجاح"  
    else
        echo "❌ register route لم يُبنى!"
    fi
    
    echo ""
    echo "🔄 إعادة تشغيل Frontend..."
    pm2 restart unitrans-frontend
    
    echo ""
    echo "⏳ انتظار استقرار الخدمة..."
    sleep 8
    
    echo ""
    echo "🧪 اختبار نهائي:"
    echo "================"
    
    # اختبار direct على port 3000
    echo "1️⃣ اختبار على port 3000 (مباشر):"
    curl -X POST http://localhost:3000/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"test@test.com","password":"123456"}' \
      -w "\n📊 Status: %{http_code}\n"
    
    echo ""
    echo "2️⃣ اختبار على HTTPS domain:"
    curl -X POST https://unibus.online/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"test@test.com","password":"123456"}' \
      -w "\n📊 Status: %{http_code}\n"
    
    echo ""
    echo "3️⃣ اختبار صفحة Login:"
    curl -I https://unibus.online/login -w "\n📊 Status: %{http_code}\n"
    
else
    echo "❌ البناء فشل!"
    echo "📋 آخر errors:"
    tail -20 ~/.npm/_logs/*debug*.log 2>/dev/null || echo "لا توجد logs"
fi

echo ""
echo "📊 الحالة النهائية:"
pm2 status

echo ""
echo "✅ انتهت عملية البناء القوي!"
echo "🔗 جرب الآن: https://unibus.online/login"
