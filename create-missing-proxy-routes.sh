#!/bin/bash

echo "🔧 إنشاء proxy routes المفقودة"
echo "=============================="

cd /var/www/unitrans

# إنشاء مجلدات proxy routes
echo "📁 إنشاء مجلدات..."
mkdir -p frontend-new/app/api/login
mkdir -p frontend-new/app/api/register

# إنشاء login proxy route
echo "🔐 إنشاء login proxy route..."
cat > frontend-new/app/api/login/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    console.log('🔄 Login Proxy Request:', body.email);
    
    const backendUrl = 'http://localhost:3001'; // Backend URL
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

# إنشاء register proxy route  
echo "📝 إنشاء register proxy route..."
cat > frontend-new/app/api/register/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    console.log('🔄 Register Proxy Request:', body.email);
    
    const backendUrl = 'http://localhost:3001'; // Backend URL
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

echo ""
echo "✅ تم إنشاء proxy routes!"

echo ""
echo "📂 التحقق من الملفات المنشأة:"
ls -la frontend-new/app/api/login/
ls -la frontend-new/app/api/register/

echo ""
echo "🔨 إعادة بناء Frontend مع routes الجديدة..."
cd frontend-new

# حذف cache
rm -rf .next
rm -rf node_modules/.cache

# بناء جديد
npm run build

echo ""
echo "🔄 إعادة تشغيل Frontend..."
pm2 restart unitrans-frontend

echo ""
echo "⏳ انتظار استقرار الخدمة..."
sleep 5

echo ""
echo "🧪 اختبار proxy routes:"
echo "========================"

echo "1️⃣ اختبار login proxy:"
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\n📊 Status: %{http_code}\n"

echo ""
echo "2️⃣ اختبار register proxy:"
curl -X POST http://localhost:3000/api/register \
  -H "Content-Type: application/json" \
  -d '{"email":"newuser@test.com","password":"123456","fullName":"New User"}' \
  -w "\n📊 Status: %{http_code}\n"

echo ""
echo "📊 حالة PM2:"
pm2 status

echo ""
echo "✅ اكتمل إنشاء وتجربة proxy routes!"
echo "🔗 جرب الآن: https://unibus.online/login"
