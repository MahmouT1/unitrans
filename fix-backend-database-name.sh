#!/bin/bash

echo "🔧 إصلاح اسم قاعدة البيانات في Backend وإعادة التشغيل"
echo "============================================================"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd /var/www/unitrans/backend-new

# ==========================================
# 1. فحص server.js
# ==========================================
echo "=================================================="
echo -e "${YELLOW}1️⃣  فحص اسم قاعدة البيانات في server.js${NC}"
echo "=================================================="

if grep -q "student-portal" server.js; then
    echo -e "${BLUE}وجدت اسم خطأ: student-portal${NC}"
    echo -e "${BLUE}سأصححه إلى: student_portal${NC}"
    
    # Backup
    cp server.js server.js.backup_$(date +%Y%m%d_%H%M%S)
    
    # تصحيح الاسم
    sed -i "s/'student-portal'/'student_portal'/g" server.js
    sed -i 's/"student-portal"/"student_portal"/g' server.js
    
    echo -e "${GREEN}✅ تم تصحيح اسم قاعدة البيانات${NC}"
else
    echo -e "${GREEN}✅ اسم قاعدة البيانات صحيح${NC}"
fi

echo ""

# ==========================================
# 2. فحص/إنشاء .env
# ==========================================
echo "=================================================="
echo -e "${YELLOW}2️⃣  فحص ملف .env${NC}"
echo "=================================================="

if [ ! -f ".env" ]; then
    echo -e "${BLUE}إنشاء ملف .env...${NC}"
    cat > .env << 'EOF'
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB_NAME=student_portal
DB_NAME=student_portal
PORT=3001
NODE_ENV=production
JWT_SECRET=unibus-secret-key-2024
EOF
    echo -e "${GREEN}✅ تم إنشاء .env${NC}"
else
    echo -e "${BLUE}تحديث .env...${NC}"
    
    # تأكد من وجود الإعدادات الصحيحة
    grep -q "MONGODB_DB_NAME" .env || echo "MONGODB_DB_NAME=student_portal" >> .env
    grep -q "DB_NAME" .env || echo "DB_NAME=student_portal" >> .env
    
    # تصحيح القيم الموجودة
    sed -i 's/MONGODB_DB_NAME=.*/MONGODB_DB_NAME=student_portal/' .env
    sed -i 's/DB_NAME=.*/DB_NAME=student_portal/' .env
    
    echo -e "${GREEN}✅ تم تحديث .env${NC}"
fi

echo ""
echo "محتوى .env:"
cat .env
echo ""

# ==========================================
# 3. إعادة تشغيل Backend
# ==========================================
echo "=================================================="
echo -e "${YELLOW}3️⃣  إعادة تشغيل unitrans-backend${NC}"
echo "=================================================="

cd /var/www/unitrans

pm2 restart unitrans-backend

pm2 save

echo -e "${GREEN}✅ تم إعادة تشغيل Backend${NC}"
echo ""

# ==========================================
# 4. انتظار
# ==========================================
echo "=================================================="
echo -e "${YELLOW}4️⃣  انتظار Backend${NC}"
echo "=================================================="

echo -e "${BLUE}انتظار 5 ثوان...${NC}"
sleep 5

# ==========================================
# 5. اختبار Backend
# ==========================================
echo "=================================================="
echo -e "${YELLOW}5️⃣  اختبار Backend${NC}"
echo "=================================================="

echo -e "${BLUE}GET http://localhost:3001/api/students/all${NC}"
BACKEND_TEST=$(curl -s http://localhost:3001/api/students/all?page=1&limit=3)

echo "الاستجابة:"
echo "$BACKEND_TEST"
echo ""

if echo "$BACKEND_TEST" | grep -q '"success":true'; then
    COUNT=$(echo "$BACKEND_TEST" | grep -o '"fullName"' | wc -l)
    echo -e "${GREEN}🎉 Backend يعمل! وجد $COUNT طالب${NC}"
else
    echo -e "${YELLOW}⚠️  Backend لا يرجع بيانات${NC}"
    echo -e "${BLUE}فحص اللوجات:${NC}"
    pm2 logs unitrans-backend --lines 20 --nostream
fi

echo ""

# ==========================================
# 6. اختبار Frontend
# ==========================================
echo "=================================================="
echo -e "${YELLOW}6️⃣  اختبار Frontend${NC}"
echo "=================================================="

echo -e "${BLUE}GET http://localhost:3000/api/students/all${NC}"
FRONTEND_TEST=$(curl -s http://localhost:3000/api/students/all?page=1&limit=3 2>&1)

echo "الاستجابة:"
echo "$FRONTEND_TEST" | head -30
echo ""

if echo "$FRONTEND_TEST" | grep -q '"success":true'; then
    COUNT=$(echo "$FRONTEND_TEST" | grep -o '"fullName"' | wc -l)
    echo -e "${GREEN}🎉 Frontend يعمل! وجد $COUNT طالب${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend لا يرجع بيانات${NC}"
fi

echo ""

# ==========================================
# النتيجة
# ==========================================
echo "=================================================="
echo -e "${GREEN}✅ انتهى!${NC}"
echo "=================================================="
echo ""

pm2 list

echo ""
echo "الآن جرب المتصفح:"
echo "  https://unibus.online/admin/users"
echo ""
