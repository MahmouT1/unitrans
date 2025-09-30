#!/bin/bash

echo "🔧 حل بسيط بدون build"
echo "========================"

cd /var/www/unitrans

# 1. إنشاء الملفات
echo "1. إنشاء ملفات API..."

mkdir -p frontend-new/app/api/students/all
mkdir -p frontend-new/app/api/students/profile-simple

# /api/students/all
cat > frontend-new/app/api/students/all/route.js << 'ENDFILE'
import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = searchParams.get('page') || '1';
    const limit = searchParams.get('limit') || '20';
    const search = searchParams.get('search') || '';
    
    const backendUrl = 'http://localhost:3001';
    const params = new URLSearchParams({ page, limit });
    if (search) params.append('search', search);
    
    const response = await fetch(`${backendUrl}/api/students/all?${params}`);
    const data = await response.json();
    
    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
ENDFILE

# /api/students/profile-simple  
cat > frontend-new/app/api/students/profile-simple/route.js << 'ENDFILE'
import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const admin = searchParams.get('admin');
    
    if (admin === 'true') {
      const response = await fetch('http://localhost:3001/api/students/all?page=1&limit=1000');
      const data = await response.json();
      
      if (data.success && data.students) {
        const studentsObject = {};
        data.students.forEach(s => { studentsObject[s.email] = s; });
        return NextResponse.json({ success: true, students: studentsObject });
      }
    }
    
    return NextResponse.json({ success: false }, { status: 400 });
  } catch (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
ENDFILE

echo "✅ الملفات تم إنشاؤها"

# 2. إعادة تشغيل في dev mode
echo "2. إعادة تشغيل Frontend في dev mode..."

cd frontend-new

pm2 delete frontend-new 2>/dev/null

# Start in development mode (no build needed!)
pm2 start npm --name frontend-new -- run dev

pm2 save

echo ""
echo "✅ تم! Frontend يعمل في dev mode"
echo "انتظر 10 ثوان ثم جرب الصفحة"
echo ""

sleep 5
pm2 list
