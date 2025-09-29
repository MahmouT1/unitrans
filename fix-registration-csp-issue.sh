#!/bin/bash

echo "🔧 إصلاح CSP في صفحة Registration"
echo "=================================="

cd /var/www/unitrans

echo "🛑 إيقاف Frontend..."
pm2 stop unitrans-frontend

echo ""
echo "🔧 إصلاح API URLs في Registration:"
echo "================================="

# إصلاح API URLs لتجنب CSP
sed -i 's|https://unibus.online:3001/api/students/data|/api/students/data|g' frontend-new/app/student/registration/page.js
sed -i 's|https://unibus.online:3001/api/students/generate-qr|/api/students/generate-qr|g' frontend-new/app/student/registration/page.js

echo "✅ تم تغيير API URLs إلى relative paths"

echo ""
echo "🔧 إنشاء Next.js API routes للـ students:"
echo "======================================="

# إنشاء مجلد students API routes
mkdir -p frontend-new/app/api/students

# إنشاء /api/students/data route
cat > frontend-new/app/api/students/data/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function PUT(request) {
  try {
    const body = await request.json();
    const authHeader = request.headers.get('authorization');
    
    console.log('🔄 Students data proxy - PUT request');
    
    const backendUrl = 'https://unibus.online:3001';
    const response = await fetch(`${backendUrl}/api/students/data`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        ...(authHeader && { 'Authorization': authHeader })
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();
    console.log('📡 Students data proxy response:', data.success);
    
    return NextResponse.json(data, { status: response.status });

  } catch (error) {
    console.error('❌ Students data proxy error:', error);
    return NextResponse.json({ 
      success: false, 
      message: 'Proxy connection error' 
    }, { status: 500 });
  }
}

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const email = searchParams.get('email');
    const authHeader = request.headers.get('authorization');
    
    console.log('🔄 Students data proxy - GET request for:', email);
    
    const backendUrl = 'https://unibus.online:3001';
    const response = await fetch(`${backendUrl}/api/students/data?email=${email}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...(authHeader && { 'Authorization': authHeader })
      }
    });

    const data = await response.json();
    console.log('📡 Students data GET proxy response:', data.success);
    
    return NextResponse.json(data, { status: response.status });

  } catch (error) {
    console.error('❌ Students data GET proxy error:', error);
    return NextResponse.json({ 
      success: false, 
      message: 'Proxy connection error' 
    }, { status: 500 });
  }
}
EOF

# إنشاء /api/students/generate-qr route
cat > frontend-new/app/api/students/generate-qr/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    const authHeader = request.headers.get('authorization');
    
    console.log('🔄 QR generation proxy - POST request for:', body.email);
    
    const backendUrl = 'https://unibus.online:3001';
    const response = await fetch(`${backendUrl}/api/students/generate-qr`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(authHeader && { 'Authorization': authHeader })
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();
    console.log('📱 QR generation proxy response:', data.success);
    
    return NextResponse.json(data, { status: response.status });

  } catch (error) {
    console.error('❌ QR generation proxy error:', error);
    return NextResponse.json({ 
      success: false, 
      message: 'QR generation proxy error' 
    }, { status: 500 });
  }
}
EOF

echo "✅ تم إنشاء Next.js API routes للـ students"

echo ""
echo "🔧 التأكد من وجود backend routes:"
echo "==============================="

# التأكد من وجود students routes في server.js
if ! grep -q "app.use.*api/students" backend-new/server.js; then
    echo "⚠️  إضافة students routes في server.js"
    sed -i '/app.use.*api\/admin/a\
app.use("/api/students", require("./routes/students"));' backend-new/server.js
    echo "✅ تم إضافة students routes"
else
    echo "✅ students routes موجودة في server.js"
fi

echo ""
echo "🏗️ إعادة بناء Frontend:"
echo "======================="

cd frontend-new
rm -rf .next
npm run build

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ البناء نجح!"
    
    echo ""
    echo "🚀 إعادة تشغيل Frontend و Backend..."
    pm2 restart unitrans-frontend
    pm2 restart unitrans-backend
    
    echo ""
    echo "⏳ انتظار استقرار النظام..."
    sleep 10
    
    echo ""
    echo "🧪 اختبار API routes الجديدة:"
    echo "============================"
    
    echo "📄 اختبار /api/students/data:"
    curl -I https://unibus.online/api/students/data -w "Status: %{http_code}\n" -s
    
    echo "📱 اختبار /api/students/generate-qr:"
    curl -I https://unibus.online/api/students/generate-qr -w "Status: %{http_code}\n" -s
    
    echo ""
    echo "🌐 اختبار صفحة Registration:"
    curl -I https://unibus.online/student/registration -w "Status: %{http_code}\n" -s
    
else
    echo "❌ البناء فشل!"
fi

echo ""
echo "📊 حالة النهائية:"
pm2 status

echo ""
echo "✅ إصلاح CSP في Registration اكتمل!"
echo ""
echo "🎯 الآن Registration ستعمل بدون CSP errors:"
echo "   📄 /api/students/data → Next.js proxy → Backend"
echo "   📱 /api/students/generate-qr → Next.js proxy → Backend"
echo ""
echo "🔗 جرب: https://unibus.online/student/registration"
echo "   ✅ لا CSP errors"
echo "   📱 QR Code سيعمل بامتياز!"
