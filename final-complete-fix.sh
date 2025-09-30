#!/bin/bash

echo "🎯 الحل النهائي الكامل - إصلاح قاعدة البيانات والـ routes"
echo "============================================================"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /var/www/unitrans

# 1. إصلاح اسم قاعدة البيانات في Backend
echo "=================================================="
echo -e "${YELLOW}1️⃣  إصلاح اسم قاعدة البيانات${NC}"
echo "=================================================="

echo -e "${BLUE}تحديث server.js...${NC}"

# Backup
cp backend-new/server.js backend-new/server.js.backup

# Fix database name: student-portal -> student_portal
sed -i "s/const mongoDbName = process.env.DB_NAME || 'student-portal';/const mongoDbName = process.env.DB_NAME || 'student_portal';/" backend-new/server.js

echo -e "${GREEN}✅ تم تصحيح اسم قاعدة البيانات إلى student_portal${NC}"
echo ""

# 2. التأكد من ملف .env
echo "=================================================="
echo -e "${YELLOW}2️⃣  فحص ملف .env${NC}"
echo "=================================================="

if [ ! -f "backend-new/.env" ]; then
    echo -e "${YELLOW}إنشاء ملف .env...${NC}"
    cat > backend-new/.env << 'EOF'
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB_NAME=student_portal
DB_NAME=student_portal
PORT=3001
NODE_ENV=production
JWT_SECRET=your-secret-key-change-this
EOF
    echo -e "${GREEN}✅ تم إنشاء .env${NC}"
else
    # تحديث اسم القاعدة إذا كان موجود
    if grep -q "MONGODB_DB_NAME" backend-new/.env; then
        sed -i 's/MONGODB_DB_NAME=.*/MONGODB_DB_NAME=student_portal/' backend-new/.env
    else
        echo "MONGODB_DB_NAME=student_portal" >> backend-new/.env
    fi
    
    if grep -q "DB_NAME" backend-new/.env; then
        sed -i 's/DB_NAME=.*/DB_NAME=student_portal/' backend-new/.env
    else
        echo "DB_NAME=student_portal" >> backend-new/.env
    fi
    
    echo -e "${GREEN}✅ تم تحديث .env${NC}"
fi

echo ""

# 3. إنشاء ملفات Frontend API
echo "=================================================="
echo -e "${YELLOW}3️⃣  إنشاء ملفات Frontend API${NC}"
echo "=================================================="

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
    
    console.log(`[API] Fetching students: ${backendUrl}/api/students/all?${params}`);
    
    const response = await fetch(`${backendUrl}/api/students/all?${params}`, {
      headers: { 'Content-Type': 'application/json' },
      cache: 'no-store'
    });
    
    const data = await response.json();
    console.log(`[API] Got ${data.students?.length || 0} students`);
    
    return NextResponse.json(data);
  } catch (error) {
    console.error('[API] Error:', error);
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
      const response = await fetch('http://localhost:3001/api/students/all?page=1&limit=1000', {
        headers: { 'Content-Type': 'application/json' },
        cache: 'no-store'
      });
      
      const data = await response.json();
      
      if (data.success && data.students) {
        const studentsObject = {};
        data.students.forEach(s => { studentsObject[s.email] = s; });
        return NextResponse.json({ success: true, students: studentsObject });
      }
    }
    
    return NextResponse.json({ success: false, message: 'Invalid request' }, { status: 400 });
  } catch (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
ENDFILE

echo -e "${GREEN}✅ تم إنشاء ملفات API${NC}"
echo ""

# 4. إعادة تشغيل Backend
echo "=================================================="
echo -e "${YELLOW}4️⃣  إعادة تشغيل Backend${NC}"
echo "=================================================="

cd backend-new
pm2 delete backend-new 2>/dev/null || true
pm2 start server.js --name backend-new
pm2 save
cd ..

echo -e "${GREEN}✅ Backend تم تشغيله${NC}"
echo ""

# 5. إعادة تشغيل Frontend
echo "=================================================="
echo -e "${YELLOW}5️⃣  إعادة تشغيل Frontend${NC}"
echo "=================================================="

cd frontend-new
pm2 delete frontend-new 2>/dev/null || true
pm2 start npm --name frontend-new -- run dev
pm2 save
cd ..

echo -e "${GREEN}✅ Frontend تم تشغيله${NC}"
echo ""

# 6. انتظار
echo "=================================================="
echo -e "${YELLOW}6️⃣  انتظار الخدمات${NC}"
echo "=================================================="

echo -e "${BLUE}انتظار 10 ثوان...${NC}"
for i in {10..1}; do
    echo -ne "  ⏳ $i ثانية...\r"
    sleep 1
done
echo ""

echo -e "${GREEN}✅ الخدمات جاهزة${NC}"
echo ""

# 7. اختبار Backend
echo "=================================================="
echo -e "${YELLOW}7️⃣  اختبار Backend API${NC}"
echo "=================================================="

BACKEND_TEST=$(curl -s http://localhost:3001/api/students/all?page=1&limit=5)
echo "$BACKEND_TEST" | head -30

if echo "$BACKEND_TEST" | grep -q '"success":true'; then
    STUDENT_COUNT=$(echo "$BACKEND_TEST" | grep -o '"fullName"' | wc -l)
    echo ""
    echo -e "${GREEN}✅ Backend يعمل - وجد $STUDENT_COUNT طالب${NC}"
else
    echo ""
    echo -e "${RED}❌ Backend لا يعمل${NC}"
fi

echo ""

# 8. اختبار Frontend
echo "=================================================="
echo -e "${YELLOW}8️⃣  اختبار Frontend API${NC}"
echo "=================================================="

FRONTEND_TEST=$(curl -s http://localhost:3000/api/students/all?page=1&limit=5 2>&1)
echo "$FRONTEND_TEST" | head -30

if echo "$FRONTEND_TEST" | grep -q '"success":true'; then
    STUDENT_COUNT=$(echo "$FRONTEND_TEST" | grep -o '"fullName"' | wc -l)
    echo ""
    echo -e "${GREEN}✅ Frontend يعمل - وجد $STUDENT_COUNT طالب${NC}"
else
    echo ""
    echo -e "${RED}❌ Frontend لا يعمل${NC}"
fi

echo ""

# 9. النتيجة
echo "=================================================="
echo -e "${GREEN}✅ انتهى!${NC}"
echo "=================================================="
echo ""
echo "الآن:"
echo "1. افتح المتصفح"
echo "2. اذهب إلى: https://unibus.online/admin/users"
echo "3. اضغط Ctrl+Shift+R"
echo "4. يجب أن ترى الطلاب! ✅"
echo ""

pm2 list
