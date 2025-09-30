#!/bin/bash

echo "🛡️  حل آمن - إضافة ملفات API فقط (بدون تغيير أي شيء آخر)"
echo "================================================================"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd /var/www/unitrans

# ==========================================
# 1. البحث عن مجلد Frontend الأصلي
# ==========================================
echo "=================================================="
echo -e "${YELLOW}1️⃣  البحث عن مجلد Frontend${NC}"
echo "=================================================="

if [ -d "unitrans-frontend" ]; then
    FRONTEND_DIR="unitrans-frontend"
elif [ -d "frontend" ]; then
    FRONTEND_DIR="frontend"
else
    echo -e "${RED}❌ لم أجد مجلد Frontend!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ وجدت: $FRONTEND_DIR${NC}"
echo ""

# ==========================================
# 2. التحقق من وجود مجلد app/api
# ==========================================
echo "=================================================="
echo -e "${YELLOW}2️⃣  التحقق من بنية المشروع${NC}"
echo "=================================================="

if [ ! -d "$FRONTEND_DIR/app" ]; then
    echo -e "${RED}❌ هذا ليس مشروع Next.js App Router${NC}"
    echo "المجلد $FRONTEND_DIR لا يحتوي على مجلد app/"
    exit 1
fi

echo -e "${GREEN}✅ المشروع Next.js App Router${NC}"
echo ""

# ==========================================
# 3. إنشاء ملفات API فقط - بدون تغيير أي شيء آخر
# ==========================================
echo "=================================================="
echo -e "${YELLOW}3️⃣  إضافة ملفات API المفقودة${NC}"
echo "=================================================="

# إنشاء المجلدات
mkdir -p $FRONTEND_DIR/app/api/students/all
mkdir -p $FRONTEND_DIR/app/api/students/profile-simple

echo -e "${BLUE}جاري إنشاء: /api/students/all/route.js${NC}"

# ملف /api/students/all/route.js
cat > $FRONTEND_DIR/app/api/students/all/route.js << 'ENDFILE'
import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = searchParams.get('page') || '1';
    const limit = searchParams.get('limit') || '20';
    const search = searchParams.get('search') || '';
    
    // Proxy to backend (استخدام نفس Backend الموجود)
    const backendUrl = 'http://localhost:3001';
    const params = new URLSearchParams({ page, limit });
    if (search) params.append('search', search);
    
    console.log(`[Students API] Fetching from backend: ${backendUrl}/api/students/all?${params}`);
    
    const response = await fetch(`${backendUrl}/api/students/all?${params}`, {
      headers: { 'Content-Type': 'application/json' },
      cache: 'no-store'
    });
    
    const data = await response.json();
    
    if (data.success) {
      console.log(`[Students API] Success - returned ${data.students?.length || 0} students`);
    } else {
      console.log(`[Students API] Backend returned: ${data.message || 'error'}`);
    }
    
    return NextResponse.json(data);
    
  } catch (error) {
    console.error('[Students API] Error:', error);
    return NextResponse.json(
      { success: false, error: error.message }, 
      { status: 500 }
    );
  }
}
ENDFILE

echo -e "${GREEN}✅ تم إنشاء: /api/students/all/route.js${NC}"

echo -e "${BLUE}جاري إنشاء: /api/students/profile-simple/route.js${NC}"

# ملف /api/students/profile-simple/route.js
cat > $FRONTEND_DIR/app/api/students/profile-simple/route.js << 'ENDFILE'
import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const admin = searchParams.get('admin');
    
    if (admin === 'true') {
      // جلب جميع الطلاب من Backend
      const response = await fetch('http://localhost:3001/api/students/all?page=1&limit=1000', {
        headers: { 'Content-Type': 'application/json' },
        cache: 'no-store'
      });
      
      const data = await response.json();
      
      if (data.success && data.students) {
        // تحويل إلى Object format
        const studentsObject = {};
        data.students.forEach(student => {
          studentsObject[student.email] = student;
        });
        
        return NextResponse.json({ 
          success: true, 
          students: studentsObject 
        });
      }
    }
    
    return NextResponse.json(
      { success: false, message: 'Invalid request' }, 
      { status: 400 }
    );
    
  } catch (error) {
    return NextResponse.json(
      { success: false, error: error.message }, 
      { status: 500 }
    );
  }
}
ENDFILE

echo -e "${GREEN}✅ تم إنشاء: /api/students/profile-simple/route.js${NC}"
echo ""

# ==========================================
# 4. عرض الملفات المضافة
# ==========================================
echo "=================================================="
echo -e "${YELLOW}4️⃣  الملفات المضافة${NC}"
echo "=================================================="

echo -e "${GREEN}✅ $FRONTEND_DIR/app/api/students/all/route.js${NC}"
echo -e "${GREEN}✅ $FRONTEND_DIR/app/api/students/profile-simple/route.js${NC}"
echo ""

# ==========================================
# 5. إعادة تشغيل Frontend فقط (بدون Backend!)
# ==========================================
echo "=================================================="
echo -e "${YELLOW}5️⃣  إعادة تشغيل Frontend فقط${NC}"
echo "=================================================="

echo -e "${BLUE}جاري إعادة تشغيل unitrans-frontend...${NC}"

pm2 restart unitrans-frontend

pm2 save

echo -e "${GREEN}✅ تم إعادة تشغيل Frontend${NC}"
echo ""

# ==========================================
# 6. انتظار
# ==========================================
echo "=================================================="
echo -e "${YELLOW}6️⃣  انتظار Frontend${NC}"
echo "=================================================="

echo -e "${BLUE}انتظار 10 ثوان...${NC}"
for i in {10..1}; do
    echo -ne "  ⏳ $i ثانية...\r"
    sleep 1
done
echo ""

# ==========================================
# 7. اختبار Frontend API فقط
# ==========================================
echo "=================================================="
echo -e "${YELLOW}7️⃣  اختبار Frontend API${NC}"
echo "=================================================="

FRONTEND_TEST=$(curl -s http://localhost:3000/api/students/all?page=1&limit=3 2>&1)

echo "الاستجابة:"
echo "$FRONTEND_TEST" | head -30
echo ""

if echo "$FRONTEND_TEST" | grep -q '"success":true'; then
    COUNT=$(echo "$FRONTEND_TEST" | grep -o '"fullName"' | wc -l)
    echo -e "${GREEN}🎉 نجح! Frontend API يعمل - وجد $COUNT طالب${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend API لا يعمل بعد${NC}"
fi

echo ""

# ==========================================
# النتيجة النهائية
# ==========================================
echo "=================================================="
echo -e "${GREEN}✅ انتهى بأمان!${NC}"
echo "=================================================="
echo ""
echo -e "${BLUE}ما تم عمله:${NC}"
echo "  ✅ إضافة ملفين API في Frontend فقط"
echo "  ✅ إعادة تشغيل Frontend فقط"
echo "  ✅ لم يتم لمس Backend"
echo "  ✅ لم يتم تغيير قاعدة البيانات"
echo "  ✅ لم يتم تغيير أي تصميم"
echo ""
echo "الآن:"
echo "1. افتح المتصفح"
echo "2. اذهب إلى: https://unibus.online/admin/users"
echo "3. اضغط Ctrl+Shift+R (Hard Refresh)"
echo "4. يجب أن ترى الطلاب! ✅"
echo ""

pm2 list
