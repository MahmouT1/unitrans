#!/bin/bash

echo "🚨 إصلاح طارئ - حل فوري"
echo "======================================"

cd /var/www/unitrans

# 1. إنشاء المجلدات
echo "1. إنشاء المجلدات..."
mkdir -p frontend-new/app/api/students/all
mkdir -p frontend-new/app/api/students/profile-simple

# 2. إنشاء /api/students/all/route.js
echo "2. إنشاء /api/students/all..."
cat > frontend-new/app/api/students/all/route.js << 'EOF'
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
    
    console.log(`📡 Fetching: ${backendUrl}/api/students/all?${params}`);
    
    const response = await fetch(`${backendUrl}/api/students/all?${params}`, {
      headers: { 'Content-Type': 'application/json' }
    });
    
    const data = await response.json();
    console.log(`✅ Got ${data.students?.length || 0} students`);
    
    return NextResponse.json(data);
  } catch (error) {
    console.error('❌ Error:', error);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
EOF

# 3. إنشاء /api/students/profile-simple/route.js
echo "3. إنشاء /api/students/profile-simple..."
cat > frontend-new/app/api/students/profile-simple/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const admin = searchParams.get('admin');
    
    if (admin === 'true') {
      const backendUrl = 'http://localhost:3001';
      const response = await fetch(`${backendUrl}/api/students/all?page=1&limit=1000`);
      const data = await response.json();
      
      if (data.success && data.students) {
        const studentsObject = {};
        data.students.forEach(student => {
          studentsObject[student.email] = student;
        });
        return NextResponse.json({ success: true, students: studentsObject });
      }
    }
    
    return NextResponse.json({ success: false, message: 'Invalid request' }, { status: 400 });
  } catch (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
EOF

echo "✅ الملفات تم إنشاؤها"

# 4. حذف البناء القديم
echo "4. حذف البناء القديم..."
cd frontend-new
rm -rf .next

# 5. إعادة البناء
echo "5. إعادة البناء..."
npm run build

# 6. إعادة تشغيل PM2
echo "6. إعادة تشغيل Frontend..."
pm2 delete frontend-new 2>/dev/null
pm2 start npm --name frontend-new -- start
pm2 save

echo ""
echo "✅ تم! انتظر 10 ثوان ثم جرب الصفحة"
echo ""
echo "اختبار سريع:"
sleep 3
curl -s http://localhost:3000/api/students/all?page=1&limit=3 | head -20
