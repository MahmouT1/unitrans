#!/bin/bash

echo "🎯 الحل الآمن النهائي - frontend-new و backend-new"
echo "===================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd /var/www/unitrans

# ==========================================
# 1. إنشاء ملفات API في frontend-new
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
    
    console.log(`[API] Fetching: ${backendUrl}/api/students/all?${params}`);
    
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
    
    return NextResponse.json({ success: false }, { status: 400 });
  } catch (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
ENDFILE

echo -e "${GREEN}✅ تم إنشاء ملفات API${NC}"
echo ""

# ==========================================
# 2. فقط إعادة تشغيل Frontend (لا نلمس Backend!)
# ==========================================
echo "=================================================="
echo -e "${YELLOW}2️⃣  إعادة تشغيل Frontend فقط${NC}"
echo "=================================================="

pm2 restart unitrans-frontend

pm2 save

echo -e "${GREEN}✅ تم إعادة تشغيل Frontend${NC}"
echo ""

# ==========================================
# 3. انتظار
# ==========================================
echo "=================================================="
echo -e "${YELLOW}3️⃣  انتظار${NC}"
echo "=================================================="

echo -e "${BLUE}انتظار 10 ثوان...${NC}"
for i in {10..1}; do
    echo -ne "  ⏳ $i ثانية...\r"
    sleep 1
done
echo ""

# ==========================================
# 4. اختبار
# ==========================================
echo "=================================================="
echo -e "${YELLOW}4️⃣  اختبار Frontend API${NC}"
echo "=================================================="

FRONTEND_TEST=$(curl -s http://localhost:3000/api/students/all?page=1&limit=3 2>&1)

echo "الاستجابة:"
echo "$FRONTEND_TEST" | head -30

echo ""

if echo "$FRONTEND_TEST" | grep -q '"success":true'; then
    COUNT=$(echo "$FRONTEND_TEST" | grep -o '"fullName"' | wc -l)
    echo -e "${GREEN}🎉 نجح! وجد $COUNT طالب${NC}"
else
    echo -e "${YELLOW}⚠️  لا يعمل بعد${NC}"
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
echo "  ✅ إضافة ملفين API في frontend-new"
echo "  ✅ إعادة تشغيل unitrans-frontend"
echo "  ✅ لم نلمس Backend"
echo "  ✅ لم نغير قاعدة البيانات"
echo ""
echo "الآن افتح المتصفح:"
echo "  https://unibus.online/admin/users"
echo "  اضغط Ctrl+Shift+R"
echo ""

pm2 list
