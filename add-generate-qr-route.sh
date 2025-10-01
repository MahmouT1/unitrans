#!/bin/bash

echo "➕ إضافة Frontend API route لـ generate-qr"
echo "============================================"
echo ""

cd /var/www/unitrans/frontend-new

# إنشاء مجلد generate-qr
mkdir -p app/api/students/generate-qr

# إنشاء route.js
cat > app/api/students/generate-qr/route.js << 'ENDFILE'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    const { email, studentData } = body;
    
    console.log('[Generate QR API] Request for:', email || studentData?.email);
    
    const backendUrl = 'http://localhost:3001';
    const response = await fetch(`${backendUrl}/api/students/generate-qr`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    
    const data = await response.json();
    
    if (data.success) {
      console.log('[Generate QR API] Success - QR code generated');
    } else {
      console.log('[Generate QR API] Error:', data.message);
    }
    
    return NextResponse.json(data);
    
  } catch (error) {
    console.error('[Generate QR API] Error:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
ENDFILE

echo "✅ تم إنشاء app/api/students/generate-qr/route.js"
echo ""

# إعادة بناء Frontend
echo "============================================"
echo "إعادة بناء Frontend..."
echo "============================================"

rm -rf .next

npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build نجح"
    BUILD_OK=true
else
    echo ""
    echo "❌ Build فشل"
    BUILD_OK=false
fi

echo ""

# إعادة تشغيل
echo "============================================"
echo "إعادة تشغيل Frontend..."
echo "============================================"

cd /var/www/unitrans

pm2 delete unitrans-frontend 2>/dev/null || true

if [ "$BUILD_OK" = true ]; then
    cd frontend-new
    pm2 start npm --name unitrans-frontend -- start
else
    cd frontend-new
    pm2 start npm --name unitrans-frontend -- run dev
fi

cd /var/www/unitrans

pm2 save

echo "✅ تم تشغيل Frontend"
echo ""

# انتظار
echo "انتظار 5 ثوان..."
sleep 5

# اختبار
echo ""
echo "============================================"
echo "اختبار generate-qr:"
echo "============================================"

curl -X POST http://localhost:3000/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com"}' \
  | head -c 300

echo ""
echo ""
echo "============================================"
echo "✅ انتهى!"
echo "============================================"
echo ""
echo "جرب في المتصفح:"
echo "  افتح Student Portal"
echo "  اضغط على Generate QR Code"
echo ""

pm2 list
