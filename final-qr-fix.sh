#!/bin/bash

echo "🔧 الحل النهائي لـ QR Code"
echo "============================"
echo ""

cd /var/www/unitrans/frontend-new/app/api/students/generate-qr

# إنشاء الملف الصحيح
cat > route.js << 'ENDFILE'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    console.log('[Generate QR] Received body:', body);
    
    const { email, studentData } = body;
    
    // استخراج email من أي مصدر
    let studentEmail = email;
    if (!studentEmail && studentData) {
      studentEmail = studentData.email;
    }
    
    console.log('[Generate QR] Extracted email:', studentEmail);
    
    if (!studentEmail) {
      console.log('[Generate QR] ERROR: No email found!');
      return NextResponse.json(
        { success: false, message: 'Email is required' },
        { status: 400 }
      );
    }
    
    // إرسال للـ Backend مع كل من email و studentData
    const backendRequest = {
      email: studentEmail
    };
    
    if (studentData) {
      backendRequest.studentData = studentData;
    }
    
    console.log('[Generate QR] Sending to backend:', backendRequest);
    
    const backendUrl = 'http://localhost:3001';
    const response = await fetch(`${backendUrl}/api/students/generate-qr`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(backendRequest)
    });
    
    const data = await response.json();
    console.log('[Generate QR] Backend response:', data.success ? 'Success!' : 'Failed');
    
    return NextResponse.json(data);
    
  } catch (error) {
    console.error('[Generate QR] Exception:', error);
    return NextResponse.json(
      { success: false, message: error.message },
      { status: 500 }
    );
  }
}
ENDFILE

echo "✅ تم إنشاء route.js الجديد"
echo ""

# إعادة بناء
cd /var/www/unitrans/frontend-new

echo "حذف .next..."
rm -rf .next

echo "البناء..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build فشل!"
    exit 1
fi

echo ""
echo "✅ Build نجح"
echo ""

# إعادة تشغيل
cd /var/www/unitrans

pm2 restart unitrans-frontend
pm2 save

echo "انتظار 5 ثوان..."
sleep 5

echo ""
echo "============================"
echo "اختبار مع email فقط:"
curl -X POST http://localhost:3000/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com"}' 2>&1 | head -c 200

echo ""
echo ""

echo "اختبار مع studentData:"
curl -X POST http://localhost:3000/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentData":{"email":"mahmoudtarekmonaim@gmail.com","fullName":"mahmoud"}}' 2>&1 | head -c 200

echo ""
echo ""
echo "============================"
echo "✅ تم!"
echo "============================"
echo ""
echo "جرب في المتصفح الآن!"
echo "احذف cache أولاً!"
echo ""

pm2 list
