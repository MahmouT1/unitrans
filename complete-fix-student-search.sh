#!/bin/bash

echo "=================================================="
echo "🔧 الحل الكامل لمشكلة Student Search"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="/var/www/unitrans"
cd $PROJECT_DIR || exit 1

echo -e "${BLUE}📂 المسار الحالي: $(pwd)${NC}"
echo ""

# ==========================================
# 1. فحص Frontend
# ==========================================
echo "=================================================="
echo -e "${YELLOW}1️⃣  فحص حالة Frontend${NC}"
echo "=================================================="

if lsof -i :3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend يعمل على Port 3000${NC}"
else
    echo -e "${RED}❌ Frontend لا يعمل على Port 3000${NC}"
    echo -e "${YELLOW}محاولة تشغيل Frontend...${NC}"
    
    cd frontend-new
    
    # Check if build exists
    if [ ! -d ".next" ]; then
        echo -e "${YELLOW}بناء Frontend...${NC}"
        npm run build
    fi
    
    # Start with PM2
    if command -v pm2 &> /dev/null; then
        pm2 delete frontend-new 2>/dev/null || true
        pm2 start npm --name frontend-new -- start
        echo -e "${GREEN}✅ تم تشغيل Frontend بـ PM2${NC}"
    else
        echo -e "${YELLOW}⚠️  PM2 غير موجود - التشغيل اليدوي مطلوب${NC}"
    fi
    
    cd ..
fi
echo ""

# ==========================================
# 2. فحص قاعدة البيانات بـ mongosh
# ==========================================
echo "=================================================="
echo -e "${YELLOW}2️⃣  فحص قاعدة البيانات${NC}"
echo "=================================================="

# Try mongosh first, fall back to mongo
if command -v mongosh &> /dev/null; then
    MONGO_CMD="mongosh"
elif command -v mongo &> /dev/null; then
    MONGO_CMD="mongo"
else
    echo -e "${RED}❌ لا يوجد mongo أو mongosh${NC}"
    MONGO_CMD=""
fi

if [ -n "$MONGO_CMD" ]; then
    echo -e "${BLUE}استخدام: $MONGO_CMD${NC}"
    
    $MONGO_CMD --quiet --eval "
    use student_portal;
    print('📊 قاعدة البيانات: student_portal\n');
    print('📁 عدد الطلاب: ' + db.students.countDocuments());
    print('📁 عدد المستخدمين: ' + db.users.countDocuments());
    print('📁 عدد سجلات الحضور: ' + db.attendance.countDocuments());
    print('');
    
    var studentCount = db.students.countDocuments();
    if (studentCount > 0) {
        print('✅ يوجد ' + studentCount + ' طالب في قاعدة البيانات');
        print('');
        print('نموذج من طالب واحد:');
        print('===================');
        var sample = db.students.findOne();
        printjson(sample);
    } else {
        print('⚠️  لا يوجد طلاب في قاعدة البيانات');
    }
    "
else
    echo -e "${YELLOW}⚠️  تخطي فحص MongoDB - الأمر غير موجود${NC}"
fi
echo ""

# ==========================================
# 3. التأكد من الملف الجديد موجود
# ==========================================
echo "=================================================="
echo -e "${YELLOW}3️⃣  التأكد من ملف API الجديد${NC}"
echo "=================================================="

if [ -f "frontend-new/app/api/students/all/route.js" ]; then
    echo -e "${GREEN}✅ ملف route.js موجود في frontend-new/app/api/students/all/${NC}"
else
    echo -e "${RED}❌ ملف route.js غير موجود!${NC}"
    echo -e "${YELLOW}جاري الإنشاء...${NC}"
    
    mkdir -p frontend-new/app/api/students/all
    
    cat > frontend-new/app/api/students/all/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = searchParams.get('page') || '1';
    const limit = searchParams.get('limit') || '20';
    const search = searchParams.get('search') || '';
    
    const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || process.env.BACKEND_URL || 'http://localhost:3001';
    const params = new URLSearchParams({ page, limit, ...(search && { search }) });
    
    console.log(`📡 Proxying to: ${backendUrl}/api/students/all?${params}`);
    
    const backendResponse = await fetch(`${backendUrl}/api/students/all?${params}`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
    });
    
    const data = await backendResponse.json();
    return NextResponse.json(data, { status: backendResponse.status });
    
  } catch (error) {
    console.error('❌ Error fetching students:', error);
    return NextResponse.json(
      { success: false, message: 'Failed to fetch students', error: error.message },
      { status: 500 }
    );
  }
}
EOF
    
    echo -e "${GREEN}✅ تم إنشاء الملف${NC}"
fi
echo ""

# ==========================================
# 4. إعادة بناء Frontend
# ==========================================
echo "=================================================="
echo -e "${YELLOW}4️⃣  إعادة بناء Frontend${NC}"
echo "=================================================="

cd frontend-new

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
# 5. إعادة تشغيل الخدمات
# ==========================================
echo "=================================================="
echo -e "${YELLOW}5️⃣  إعادة تشغيل الخدمات${NC}"
echo "=================================================="

if command -v pm2 &> /dev/null; then
    echo -e "${BLUE}إعادة تشغيل بـ PM2...${NC}"
    
    # Restart frontend
    pm2 restart frontend-new || (cd frontend-new && pm2 start npm --name frontend-new -- start)
    
    # Optionally restart backend
    pm2 restart backend-new 2>/dev/null || true
    
    pm2 save
    
    echo -e "${GREEN}✅ تم إعادة التشغيل${NC}"
    echo ""
    echo -e "${BLUE}حالة الخدمات:${NC}"
    pm2 list
else
    echo -e "${YELLOW}⚠️  PM2 غير موجود - الرجاء إعادة تشغيل الخدمات يدوياً${NC}"
fi
echo ""

# ==========================================
# 6. اختبار النتيجة
# ==========================================
echo "=================================================="
echo -e "${YELLOW}6️⃣  اختبار الحل${NC}"
echo "=================================================="

echo -e "${BLUE}انتظار 5 ثوان لتشغيل الخدمات...${NC}"
sleep 5

echo ""
echo -e "${BLUE}اختبار Frontend API:${NC}"
FRONTEND_TEST=$(curl -s -w "\n%{http_code}" http://localhost:3000/api/students/all?page=1&limit=3 2>&1 | tail -1)

if [ "$FRONTEND_TEST" = "200" ]; then
    echo -e "${GREEN}✅ Frontend API يعمل!${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend API Status: $FRONTEND_TEST${NC}"
fi

echo ""
echo -e "${BLUE}اختبار Backend API:${NC}"
BACKEND_TEST=$(curl -s -w "\n%{http_code}" http://localhost:3001/api/students/all?page=1&limit=3 2>&1 | tail -1)

if [ "$BACKEND_TEST" = "200" ]; then
    echo -e "${GREEN}✅ Backend API يعمل!${NC}"
else
    echo -e "${YELLOW}⚠️  Backend API Status: $BACKEND_TEST${NC}"
    echo -e "${YELLOW}💡 ملاحظة: Backend قد لا يحتوي على route /api/students/all${NC}"
    echo -e "${YELLOW}   لكن Frontend API يستطيع استخدام routes أخرى${NC}"
fi

echo ""

# ==========================================
# النتيجة النهائية
# ==========================================
echo "=================================================="
echo -e "${GREEN}✅ انتهى الحل!${NC}"
echo "=================================================="
echo ""
echo -e "${BLUE}الخطوات التالية:${NC}"
echo "1. افتح المتصفح"
echo "2. اذهب لصفحة Student Search"
echo "3. اضغط F12 لفتح Console"
echo "4. اضغط Refresh"
echo "5. يجب أن ترى الطلاب يظهرون ✅"
echo ""
echo -e "${YELLOW}إذا لم تظهر النتائج:${NC}"
echo "- تحقق من Logs: pm2 logs frontend-new"
echo "- تحقق من Console في المتصفح"
echo "- تأكد من وجود بيانات: mongosh student_portal --eval 'db.students.countDocuments()'"
echo ""
