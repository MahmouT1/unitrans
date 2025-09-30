#!/bin/bash

echo "=================================================="
echo "🎯 الحل النهائي - إعادة بناء Frontend"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="/var/www/unitrans"
cd $PROJECT_DIR || exit 1

echo -e "${GREEN}✅ البيانات المكتشفة:${NC}"
echo "  • قاعدة البيانات: student_portal"
echo "  • جدول الطلاب: students (3 طلاب)"
echo "  • Backend API موجود: /api/students/all ✅"
echo "  • Frontend API route تم إنشاؤه ✅"
echo ""
echo -e "${YELLOW}المشكلة: Frontend يحتاج إعادة بناء!${NC}"
echo ""

# ==========================================
# 1. التأكد من وجود ملف Frontend API
# ==========================================
echo "=================================================="
echo -e "${YELLOW}1️⃣  التحقق من ملف API${NC}"
echo "=================================================="

if [ -f "frontend-new/app/api/students/all/route.js" ]; then
    echo -e "${GREEN}✅ الملف موجود: frontend-new/app/api/students/all/route.js${NC}"
else
    echo -e "${RED}❌ الملف غير موجود - جاري الإنشاء...${NC}"
    
    mkdir -p frontend-new/app/api/students/all
    
    cat > frontend-new/app/api/students/all/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = searchParams.get('page') || '1';
    const limit = searchParams.get('limit') || '20';
    const search = searchParams.get('search') || '';
    
    // Build backend URL
    const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || process.env.BACKEND_URL || 'https://unibus.online:3001';
    const params = new URLSearchParams({
      page,
      limit,
      ...(search && { search })
    });
    
    console.log(`📡 Proxying to: ${backendUrl}/api/students/all?${params}`);
    
    // Fetch from backend
    const backendResponse = await fetch(`${backendUrl}/api/students/all?${params}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    const data = await backendResponse.json();
    
    if (!backendResponse.ok) {
      console.error('❌ Backend error:', data);
      return NextResponse.json(data, { status: backendResponse.status });
    }
    
    console.log(`✅ Successfully fetched ${data.students?.length || 0} students`);
    
    return NextResponse.json(data, { status: 200 });
    
  } catch (error) {
    console.error('❌ Error fetching students:', error);
    return NextResponse.json(
      { 
        success: false, 
        message: 'Failed to fetch students', 
        error: error.message 
      },
      { status: 500 }
    );
  }
}
EOF
    
    echo -e "${GREEN}✅ تم إنشاء الملف${NC}"
fi
echo ""

# ==========================================
# 2. إعادة بناء Frontend
# ==========================================
echo "=================================================="
echo -e "${YELLOW}2️⃣  إعادة بناء Frontend${NC}"
echo "=================================================="

cd frontend-new

echo -e "${BLUE}جاري حذف البناء القديم...${NC}"
rm -rf .next

echo -e "${BLUE}جاري البناء...${NC}"
npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ تم البناء بنجاح${NC}"
else
    echo -e "${RED}❌ فشل البناء${NC}"
    exit 1
fi

cd ..
echo ""

# ==========================================
# 3. إعادة تشغيل Frontend
# ==========================================
echo "=================================================="
echo -e "${YELLOW}3️⃣  إعادة تشغيل Frontend${NC}"
echo "=================================================="

if command -v pm2 &> /dev/null; then
    echo -e "${BLUE}إعادة تشغيل Frontend بـ PM2...${NC}"
    
    pm2 delete frontend-new 2>/dev/null || true
    
    cd frontend-new
    pm2 start npm --name frontend-new -- start
    cd ..
    
    pm2 save
    
    echo -e "${GREEN}✅ تم إعادة التشغيل${NC}"
    echo ""
    pm2 list
else
    echo -e "${YELLOW}⚠️  PM2 غير موجود${NC}"
    echo "الرجاء تشغيل Frontend يدوياً:"
    echo "  cd frontend-new && npm start"
fi
echo ""

# ==========================================
# 4. اختبار النتيجة
# ==========================================
echo "=================================================="
echo -e "${YELLOW}4️⃣  اختبار النتيجة${NC}"
echo "=================================================="

echo -e "${BLUE}انتظار 5 ثوان...${NC}"
sleep 5

echo ""
echo -e "${BLUE}اختبار Backend API:${NC}"
BACKEND_TEST=$(curl -s http://localhost:3001/api/students/all?page=1&limit=3)
echo "$BACKEND_TEST" | head -20
echo ""

echo -e "${BLUE}اختبار Frontend API:${NC}"
FRONTEND_TEST=$(curl -s http://localhost:3000/api/students/all?page=1&limit=3 2>&1)
echo "$FRONTEND_TEST" | head -20
echo ""

# ==========================================
# النتيجة النهائية
# ==========================================
echo "=================================================="
echo -e "${GREEN}✅ انتهى!${NC}"
echo "=================================================="
echo ""
echo -e "${BLUE}الخطوات التالية:${NC}"
echo ""
echo "1. افتح المتصفح"
echo "2. اذهب إلى: https://unibus.online/admin/users"
echo "3. اضغط F12 → Console"
echo "4. اضغط Refresh"
echo ""
echo -e "${GREEN}النتيجة المتوقعة:${NC}"
echo "  ✅ لا توجد أخطاء 404"
echo "  ✅ قائمة الطلاب تظهر"
echo "  ✅ محمود طارق يظهر في القائمة"
echo ""
echo -e "${YELLOW}إذا لم تظهر النتائج:${NC}"
echo "  pm2 logs frontend-new"
echo ""
