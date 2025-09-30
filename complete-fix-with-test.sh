#!/bin/bash

echo "=================================================="
echo "🔧 حل كامل مع اختبار تلقائي"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /var/www/unitrans

# ==========================================
# 1. إنشاء ملفات API
# ==========================================
echo "=================================================="
echo -e "${YELLOW}1️⃣  إنشاء ملفات API${NC}"
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
    
    console.log(`📡 Proxying to: ${backendUrl}/api/students/all?${params}`);
    
    const response = await fetch(`${backendUrl}/api/students/all?${params}`);
    const data = await response.json();
    
    console.log(`✅ Returned ${data.students?.length || 0} students`);
    
    return NextResponse.json(data);
  } catch (error) {
    console.error('❌ Error:', error);
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
    
    return NextResponse.json({ success: false, message: 'Invalid request' }, { status: 400 });
  } catch (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
ENDFILE

echo -e "${GREEN}✅ تم إنشاء الملفات${NC}"
echo ""

# ==========================================
# 2. إعادة تشغيل Frontend
# ==========================================
echo "=================================================="
echo -e "${YELLOW}2️⃣  إعادة تشغيل Frontend${NC}"
echo "=================================================="

cd frontend-new

pm2 delete frontend-new 2>/dev/null || true

echo -e "${BLUE}جاري التشغيل في dev mode...${NC}"
pm2 start npm --name frontend-new -- run dev

pm2 save

cd ..

echo -e "${GREEN}✅ تم تشغيل Frontend${NC}"
echo ""

# ==========================================
# 3. انتظار حتى يبدأ Frontend
# ==========================================
echo "=================================================="
echo -e "${YELLOW}3️⃣  انتظار Frontend للبدء${NC}"
echo "=================================================="

echo -e "${BLUE}جاري الانتظار 15 ثانية...${NC}"

for i in {15..1}; do
    echo -ne "  ⏳ $i ثانية متبقية...\r"
    sleep 1
done

echo -e "\n${GREEN}✅ Frontend جاهز للاختبار${NC}"
echo ""

# ==========================================
# 4. اختبار Backend API
# ==========================================
echo "=================================================="
echo -e "${YELLOW}4️⃣  اختبار Backend API${NC}"
echo "=================================================="

echo -e "${BLUE}اختبار: http://localhost:3001/api/students/all${NC}"

BACKEND_RESPONSE=$(curl -s http://localhost:3001/api/students/all?page=1&limit=20)
BACKEND_SUCCESS=$(echo "$BACKEND_RESPONSE" | grep -o '"success":true' | head -1)
BACKEND_STUDENTS=$(echo "$BACKEND_RESPONSE" | grep -o '"students":\[' | head -1)

if [ -n "$BACKEND_SUCCESS" ] && [ -n "$BACKEND_STUDENTS" ]; then
    STUDENT_COUNT=$(echo "$BACKEND_RESPONSE" | grep -o '"fullName"' | wc -l)
    echo -e "${GREEN}✅ Backend يعمل - وجد $STUDENT_COUNT طالب${NC}"
    echo ""
    echo "نموذج من الاستجابة:"
    echo "$BACKEND_RESPONSE" | head -20
else
    echo -e "${RED}❌ Backend لا يعمل بشكل صحيح${NC}"
    echo "الاستجابة:"
    echo "$BACKEND_RESPONSE"
fi

echo ""

# ==========================================
# 5. اختبار Frontend API
# ==========================================
echo "=================================================="
echo -e "${YELLOW}5️⃣  اختبار Frontend API${NC}"
echo "=================================================="

echo -e "${BLUE}اختبار: http://localhost:3000/api/students/all${NC}"

FRONTEND_RESPONSE=$(curl -s http://localhost:3000/api/students/all?page=1&limit=20 2>&1)
FRONTEND_SUCCESS=$(echo "$FRONTEND_RESPONSE" | grep -o '"success":true' | head -1)
FRONTEND_STUDENTS=$(echo "$FRONTEND_RESPONSE" | grep -o '"students":\[' | head -1)

if [ -n "$FRONTEND_SUCCESS" ] && [ -n "$FRONTEND_STUDENTS" ]; then
    STUDENT_COUNT=$(echo "$FRONTEND_RESPONSE" | grep -o '"fullName"' | wc -l)
    echo -e "${GREEN}✅ Frontend API يعمل - وجد $STUDENT_COUNT طالب${NC}"
    echo ""
    echo "نموذج من الاستجابة:"
    echo "$FRONTEND_RESPONSE" | head -20
else
    echo -e "${RED}❌ Frontend API لا يعمل بشكل صحيح${NC}"
    echo "الاستجابة:"
    echo "$FRONTEND_RESPONSE" | head -30
fi

echo ""

# ==========================================
# 6. اختبار profile-simple API
# ==========================================
echo "=================================================="
echo -e "${YELLOW}6️⃣  اختبار profile-simple API${NC}"
echo "=================================================="

echo -e "${BLUE}اختبار: http://localhost:3000/api/students/profile-simple?admin=true${NC}"

PROFILE_RESPONSE=$(curl -s "http://localhost:3000/api/students/profile-simple?admin=true" 2>&1)
PROFILE_SUCCESS=$(echo "$PROFILE_RESPONSE" | grep -o '"success":true' | head -1)

if [ -n "$PROFILE_SUCCESS" ]; then
    echo -e "${GREEN}✅ Profile API يعمل${NC}"
else
    echo -e "${RED}❌ Profile API لا يعمل${NC}"
fi

echo ""

# ==========================================
# 7. النتيجة النهائية
# ==========================================
echo "=================================================="
echo -e "${GREEN}📊 ملخص الاختبار${NC}"
echo "=================================================="

ERRORS=0

if [ -z "$BACKEND_SUCCESS" ]; then
    echo -e "${RED}❌ Backend API فشل${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✅ Backend API يعمل${NC}"
fi

if [ -z "$FRONTEND_SUCCESS" ]; then
    echo -e "${RED}❌ Frontend API فشل${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✅ Frontend API يعمل${NC}"
fi

if [ -z "$PROFILE_SUCCESS" ]; then
    echo -e "${RED}❌ Profile API فشل${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✅ Profile API يعمل${NC}"
fi

echo ""

if [ $ERRORS -eq 0 ]; then
    echo "=================================================="
    echo -e "${GREEN}🎉 نجح! كل شيء يعمل بشكل ممتاز!${NC}"
    echo "=================================================="
    echo ""
    echo -e "${BLUE}الآن يمكنك:${NC}"
    echo "1. فتح المتصفح"
    echo "2. الذهاب إلى: https://unibus.online/admin/users"
    echo "3. اضغط Ctrl+Shift+R (Hard Refresh)"
    echo "4. يجب أن ترى قائمة الطلاب تظهر! ✅"
    echo ""
    echo -e "${GREEN}تم حل المشكلة بنجاح! 🎊${NC}"
else
    echo "=================================================="
    echo -e "${RED}⚠️  تم اكتشاف $ERRORS مشكلة${NC}"
    echo "=================================================="
    echo ""
    echo "الرجاء فحص الـ logs:"
    echo "  pm2 logs frontend-new"
    echo "  pm2 logs backend-new"
fi

echo ""
echo "=================================================="
echo -e "${BLUE}حالة الخدمات:${NC}"
echo "=================================================="
pm2 list

echo ""
