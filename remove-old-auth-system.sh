#!/bin/bash

echo "🗑️ إزالة نظام Auth القديم تماماً"
echo "================================="

cd /var/www/unitrans

echo "🛑 إيقاف Frontend..."
pm2 stop unitrans-frontend

echo ""
echo "🗂️ حذف صفحة Auth القديمة:"
echo "========================="

# حذف صفحة /auth القديمة
if [ -f "frontend-new/app/auth/page.js" ]; then
    echo "❌ حذف /auth القديمة..."
    rm -rf frontend-new/app/auth/
    echo "✅ تم حذف /auth"
else
    echo "ℹ️ /auth غير موجودة"
fi

# حذف proxy routes القديمة  
if [ -d "frontend-new/app/api/proxy/auth/" ]; then
    echo "❌ حذف proxy routes القديمة..."
    rm -rf frontend-new/app/api/proxy/
    echo "✅ تم حذف proxy routes القديمة"
else
    echo "ℹ️ proxy routes القديمة غير موجودة"
fi

echo ""
echo "🔄 إنشاء redirect من /auth إلى /login:"
echo "======================================"

# إنشاء صفحة redirect بدلاً من Auth القديمة
mkdir -p frontend-new/app/auth
cat > frontend-new/app/auth/page.js << 'EOF'
'use client';

import { useEffect } from 'react';

export default function AuthRedirect() {
  useEffect(() => {
    // توجيه فوري للصفحة الجديدة
    window.location.replace('/login');
  }, []);

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: '#f8f9fa'
    }}>
      <div style={{
        textAlign: 'center',
        color: '#6c757d'
      }}>
        <div style={{ fontSize: '48px', marginBottom: '20px' }}>🔄</div>
        <p>Redirecting to new login page...</p>
      </div>
    </div>
  );
}
EOF

echo "✅ تم إنشاء redirect page"

echo ""
echo "🔍 التأكد من proxy routes الجديدة:"
echo "================================="

# التأكد من proxy routes الجديدة
if [ ! -f "frontend-new/app/api/login/route.js" ]; then
    echo "🔧 إنشاء login route..."
    mkdir -p frontend-new/app/api/login
    cat > frontend-new/app/api/login/route.js << 'LOGINEOF'
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
fi

if [ ! -f "frontend-new/app/api/register/route.js" ]; then
    echo "🔧 إنشاء register route..."
    mkdir -p frontend-new/app/api/register
    cat > frontend-new/app/api/register/route.js << 'REGEOF'
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
fi

echo "✅ proxy routes جاهزة"

echo ""
echo "🏗️ إعادة بناء Frontend:"
echo "======================="

cd frontend-new

# حذف cache
rm -rf .next
rm -rf node_modules/.cache

# بناء جديد
npm run build

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ البناء نجح!"
    
    echo ""
    echo "🚀 إعادة تشغيل Frontend..."
    pm2 start unitrans-frontend
    
    echo ""
    echo "⏳ انتظار استقرار النظام..."
    sleep 8
    
    echo ""
    echo "🧪 اختبار النظام الجديد:"
    echo "======================="
    
    echo "1️⃣ اختبار /auth (redirect):"
    curl -I https://unibus.online/auth -w "\n📊 Status: %{http_code}\n"
    
    echo ""
    echo "2️⃣ اختبار /login (الجديدة):"
    curl -I https://unibus.online/login -w "\n📊 Status: %{http_code}\n"
    
    echo ""
    echo "3️⃣ اختبار login API:"
    curl -X POST https://unibus.online/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"test@test.com","password":"123456"}' \
      -w "\n📊 Status: %{http_code}\n"
    
    echo ""
    echo "4️⃣ اختبار Admin login:"
    curl -X POST https://unibus.online/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"roo2admin@gmail.com","password":"admin123"}' \
      -w "\n📊 Status: %{http_code}\n"
    
else
    echo "❌ البناء فشل!"
fi

echo ""
echo "📊 الحالة النهائية:"
pm2 status

echo ""
echo "✅ تم إزالة النظام القديم وتفعيل الجديد!"
echo "🔗 الآن اذهب إلى: https://unibus.online/login"
echo "🔗 أو https://unibus.online/auth (سيوجهك تلقائياً)"
