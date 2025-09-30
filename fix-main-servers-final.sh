#!/bin/bash

echo "🎯 حل نهائي للسيرفرات الأصلية - unitrans-frontend & unitrans-backend"
echo "======================================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd /var/www/unitrans

# ==========================================
# 1. إضافة API routes في frontend-new
# ==========================================
echo "=================================================="
echo -e "${YELLOW}1️⃣  إضافة ملفات API في frontend-new${NC}"
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
    
    console.log(`[Students All API] Fetching from: ${backendUrl}/api/students/all?${params}`);
    
    const response = await fetch(`${backendUrl}/api/students/all?${params}`, {
      headers: { 'Content-Type': 'application/json' },
      cache: 'no-store'
    });
    
    const data = await response.json();
    console.log(`[Students All API] Response:`, data.success ? `Success - ${data.students?.length || 0} students` : `Error - ${data.message}`);
    
    return NextResponse.json(data);
  } catch (error) {
    console.error('[Students All API] Error:', error);
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
      console.log('[Profile Simple API] Admin request - fetching all students');
      
      const response = await fetch('http://localhost:3001/api/students/all?page=1&limit=1000', {
        headers: { 'Content-Type': 'application/json' },
        cache: 'no-store'
      });
      
      const data = await response.json();
      
      if (data.success && data.students) {
        const studentsObject = {};
        data.students.forEach(s => { studentsObject[s.email] = s; });
        console.log(`[Profile Simple API] Success - converted ${data.students.length} students to object`);
        return NextResponse.json({ success: true, students: studentsObject });
      }
    }
    
    return NextResponse.json({ success: false, message: 'Invalid request' }, { status: 400 });
  } catch (error) {
    console.error('[Profile Simple API] Error:', error);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
ENDFILE

echo -e "${GREEN}✅ تم إنشاء ملفات API${NC}"
echo ""

# ==========================================
# 2. إعادة تشغيل unitrans-frontend في dev mode
# ==========================================
echo "=================================================="
echo -e "${YELLOW}2️⃣  إعادة تشغيل unitrans-frontend${NC}"
echo "=================================================="

cd frontend-new

# إيقاف القديم
pm2 delete unitrans-frontend 2>/dev/null || true

# تشغيل في dev mode
echo -e "${BLUE}تشغيل في dev mode...${NC}"
pm2 start npm --name unitrans-frontend -- run dev

cd ..

pm2 save

echo -e "${GREEN}✅ تم تشغيل unitrans-frontend${NC}"
echo ""

# ==========================================
# 3. انتظار
# ==========================================
echo "=================================================="
echo -e "${YELLOW}3️⃣  انتظار الخدمات${NC}"
echo "=================================================="

echo -e "${BLUE}انتظار 15 ثانية...${NC}"
for i in {15..1}; do
    echo -ne "  ⏳ $i ثانية...\r"
    sleep 1
done
echo ""

# ==========================================
# 4. اختبار Backend
# ==========================================
echo "=================================================="
echo -e "${YELLOW}4️⃣  اختبار Backend API${NC}"
echo "=================================================="

echo -e "${BLUE}GET http://localhost:3001/api/students/all${NC}"
BACKEND_TEST=$(curl -s http://localhost:3001/api/students/all?page=1&limit=3 2>&1)

echo "الاستجابة:"
echo "$BACKEND_TEST" | head -25

if echo "$BACKEND_TEST" | grep -q '"success":true'; then
    COUNT=$(echo "$BACKEND_TEST" | grep -o '"fullName"' | wc -l)
    echo ""
    echo -e "${GREEN}✅ Backend يعمل - وجد $COUNT طالب${NC}"
else
    echo ""
    echo -e "${YELLOW}⚠️  Backend لا يرجع بيانات صحيحة${NC}"
fi

echo ""

# ==========================================
# 5. اختبار Frontend
# ==========================================
echo "=================================================="
echo -e "${YELLOW}5️⃣  اختبار Frontend API${NC}"
echo "=================================================="

echo -e "${BLUE}GET http://localhost:3000/api/students/all${NC}"
FRONTEND_TEST=$(curl -s http://localhost:3000/api/students/all?page=1&limit=3 2>&1)

echo "الاستجابة:"
echo "$FRONTEND_TEST" | head -25

if echo "$FRONTEND_TEST" | grep -q '"success":true'; then
    COUNT=$(echo "$FRONTEND_TEST" | grep -o '"fullName"' | wc -l)
    echo ""
    echo -e "${GREEN}✅ Frontend يعمل - وجد $COUNT طالب${NC}"
else
    echo ""
    echo -e "${YELLOW}⚠️  Frontend لا يرجع بيانات صحيحة${NC}"
fi

echo ""

# ==========================================
# النتيجة
# ==========================================
echo "=================================================="
echo -e "${GREEN}✅ انتهى!${NC}"
echo "=================================================="
echo ""
echo "ما تم عمله:"
echo "  ✅ إضافة ملفات API في frontend-new"
echo "  ✅ إعادة تشغيل unitrans-frontend في dev mode"
echo "  ✅ اختبار Backend و Frontend APIs"
echo ""
echo "الآن:"
echo "  1. افتح المتصفح"
echo "  2. اذهب إلى: https://unibus.online/admin/users"
echo "  3. اضغط Ctrl+Shift+R (Hard Refresh)"
echo "  4. يجب أن ترى الطلاب! 🎉"
echo ""

echo "حالة الخدمات:"
pm2 list
