#!/bin/bash

echo "🎯 إصلاح السيرفرات الأصلية (unitrans-backend & unitrans-frontend)"
echo "=================================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /var/www/unitrans

# ==========================================
# 1. اكتشاف مجلدات المشروع الأصلي
# ==========================================
echo "=================================================="
echo -e "${YELLOW}1️⃣  البحث عن المجلدات الأصلية${NC}"
echo "=================================================="

# البحث عن frontend
if [ -d "frontend" ]; then
    FRONTEND_DIR="frontend"
elif [ -d "unitrans-frontend" ]; then
    FRONTEND_DIR="unitrans-frontend"
else
    FRONTEND_DIR="frontend-new"
fi

# البحث عن backend
if [ -d "backend" ]; then
    BACKEND_DIR="backend"
elif [ -d "unitrans-backend" ]; then
    BACKEND_DIR="unitrans-backend"
else
    BACKEND_DIR="backend-new"
fi

echo -e "${BLUE}Frontend directory: $FRONTEND_DIR${NC}"
echo -e "${BLUE}Backend directory: $BACKEND_DIR${NC}"
echo ""

# ==========================================
# 2. إنشاء ملفات API في Frontend الأصلي
# ==========================================
echo "=================================================="
echo -e "${YELLOW}2️⃣  إنشاء ملفات API في $FRONTEND_DIR${NC}"
echo "=================================================="

mkdir -p $FRONTEND_DIR/app/api/students/all
mkdir -p $FRONTEND_DIR/app/api/students/profile-simple

# /api/students/all
cat > $FRONTEND_DIR/app/api/students/all/route.js << 'ENDFILE'
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
    
    console.log(`[API] Fetching: ${backendUrl}/api/students/all?${params}`);
    
    const response = await fetch(`${backendUrl}/api/students/all?${params}`, {
      headers: { 'Content-Type': 'application/json' },
      cache: 'no-store'
    });
    
    const data = await response.json();
    console.log(`[API] Success: ${data.students?.length || 0} students`);
    
    return NextResponse.json(data);
  } catch (error) {
    console.error('[API] Error:', error);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
ENDFILE

# /api/students/profile-simple
cat > $FRONTEND_DIR/app/api/students/profile-simple/route.js << 'ENDFILE'
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
    
    return NextResponse.json({ success: false }, { status: 400 });
  } catch (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
ENDFILE

echo -e "${GREEN}✅ تم إنشاء ملفات API في $FRONTEND_DIR${NC}"
echo ""

# ==========================================
# 3. فحص وإصلاح Backend
# ==========================================
echo "=================================================="
echo -e "${YELLOW}3️⃣  فحص $BACKEND_DIR${NC}"
echo "=================================================="

# التحقق من وجود server.js
if [ -f "$BACKEND_DIR/server.js" ]; then
    echo -e "${BLUE}فحص اسم قاعدة البيانات في server.js...${NC}"
    
    # Backup
    cp $BACKEND_DIR/server.js $BACKEND_DIR/server.js.backup
    
    # تصحيح اسم قاعدة البيانات
    sed -i "s/'student-portal'/'student_portal'/g" $BACKEND_DIR/server.js
    
    echo -e "${GREEN}✅ تم تصحيح اسم قاعدة البيانات${NC}"
else
    echo -e "${YELLOW}⚠️  server.js غير موجود في $BACKEND_DIR${NC}"
fi

# فحص .env
if [ -f "$BACKEND_DIR/.env" ]; then
    echo -e "${BLUE}تحديث .env...${NC}"
    
    # تحديث اسم القاعدة
    if grep -q "MONGODB_DB_NAME" $BACKEND_DIR/.env; then
        sed -i 's/MONGODB_DB_NAME=.*/MONGODB_DB_NAME=student_portal/' $BACKEND_DIR/.env
    else
        echo "MONGODB_DB_NAME=student_portal" >> $BACKEND_DIR/.env
    fi
    
    if grep -q "DB_NAME" $BACKEND_DIR/.env; then
        sed -i 's/DB_NAME=.*/DB_NAME=student_portal/' $BACKEND_DIR/.env
    else
        echo "DB_NAME=student_portal" >> $BACKEND_DIR/.env
    fi
    
    echo -e "${GREEN}✅ تم تحديث .env${NC}"
fi

echo ""

# ==========================================
# 4. إعادة تشغيل السيرفرات الأصلية
# ==========================================
echo "=================================================="
echo -e "${YELLOW}4️⃣  إعادة تشغيل السيرفرات${NC}"
echo "=================================================="

echo -e "${BLUE}إعادة تشغيل unitrans-backend...${NC}"
pm2 restart unitrans-backend

echo -e "${BLUE}إعادة تشغيل unitrans-frontend...${NC}"
pm2 restart unitrans-frontend

pm2 save

echo -e "${GREEN}✅ تم إعادة التشغيل${NC}"
echo ""

# ==========================================
# 5. انتظار
# ==========================================
echo "=================================================="
echo -e "${YELLOW}5️⃣  انتظار الخدمات${NC}"
echo "=================================================="

echo -e "${BLUE}انتظار 10 ثوان...${NC}"
for i in {10..1}; do
    echo -ne "  ⏳ $i ثانية...\r"
    sleep 1
done
echo ""

# ==========================================
# 6. اختبار
# ==========================================
echo "=================================================="
echo -e "${YELLOW}6️⃣  اختبار Backend${NC}"
echo "=================================================="

BACKEND_TEST=$(curl -s http://localhost:3001/api/students/all?page=1&limit=3)

if echo "$BACKEND_TEST" | grep -q '"success":true'; then
    COUNT=$(echo "$BACKEND_TEST" | grep -o '"fullName"' | wc -l)
    echo -e "${GREEN}✅ Backend يعمل - وجد $COUNT طالب${NC}"
else
    echo -e "${RED}❌ Backend لا يعمل${NC}"
fi

echo ""
echo "نموذج من الاستجابة:"
echo "$BACKEND_TEST" | head -20

echo ""
echo ""

echo "=================================================="
echo -e "${YELLOW}7️⃣  اختبار Frontend${NC}"
echo "=================================================="

FRONTEND_TEST=$(curl -s http://localhost:3000/api/students/all?page=1&limit=3 2>&1)

if echo "$FRONTEND_TEST" | grep -q '"success":true'; then
    COUNT=$(echo "$FRONTEND_TEST" | grep -o '"fullName"' | wc -l)
    echo -e "${GREEN}✅ Frontend يعمل - وجد $COUNT طالب${NC}"
else
    echo -e "${RED}❌ Frontend لا يعمل${NC}"
fi

echo ""

# ==========================================
# النتيجة
# ==========================================
echo "=================================================="
echo -e "${GREEN}✅ انتهى!${NC}"
echo "=================================================="
echo ""
echo "الآن:"
echo "1. افتح المتصفح"
echo "2. اذهب إلى: https://unibus.online/admin/users"
echo "3. اضغط Ctrl+Shift+R (Hard Refresh)"
echo ""

echo "=================================================="
echo "حالة الخدمات:"
echo "=================================================="
pm2 list
