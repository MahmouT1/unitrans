#!/bin/bash

echo "=================================================="
echo "🔧 إصلاح ملفات .env وإعادة تشغيل الخدمات"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="/var/www/unitrans"
cd $PROJECT_DIR || exit 1

# ==========================================
# 1. تحديث Frontend .env.local
# ==========================================
echo "=================================================="
echo -e "${YELLOW}1️⃣  تحديث Frontend .env.local${NC}"
echo "=================================================="

echo -e "${BLUE}القيم الحالية في frontend-new/.env.local:${NC}"
cat frontend-new/.env.local
echo ""

# Backup
cp frontend-new/.env.local frontend-new/.env.local.backup
echo -e "${GREEN}✅ تم حفظ نسخة احتياطية: .env.local.backup${NC}"

# Update BACKEND_URL to use https://unibus.online:3001
cat > frontend-new/.env.local << 'EOF'
# Backend API URL - استخدام الدومين الفعلي
NEXT_PUBLIC_BACKEND_URL=https://unibus.online:3001
BACKEND_URL=https://unibus.online:3001

# MongoDB Configuration
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB_NAME=student_portal

# Next.js
NEXT_PUBLIC_API_URL=https://unibus.online
EOF

echo -e "${GREEN}✅ تم تحديث .env.local${NC}"
echo ""
echo -e "${BLUE}القيم الجديدة:${NC}"
cat frontend-new/.env.local
echo ""

# ==========================================
# 2. تحديث Backend .env
# ==========================================
echo "=================================================="
echo -e "${YELLOW}2️⃣  التحقق من Backend .env${NC}"
echo "=================================================="

echo -e "${BLUE}القيم الحالية في backend-new/.env:${NC}"
cat backend-new/.env
echo ""

# Make sure CORS is configured for the domain
if ! grep -q "FRONTEND_URL" backend-new/.env; then
    echo "" >> backend-new/.env
    echo "FRONTEND_URL=https://unibus.online" >> backend-new/.env
    echo -e "${GREEN}✅ أضيف FRONTEND_URL للـ .env${NC}"
fi
echo ""

# ==========================================
# 3. إعادة بناء Frontend
# ==========================================
echo "=================================================="
echo -e "${YELLOW}3️⃣  إعادة بناء Frontend${NC}"
echo "=================================================="

cd frontend-new
echo -e "${BLUE}جاري البناء...${NC}"
npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ البناء نجح${NC}"
else
    echo -e "${RED}❌ البناء فشل${NC}"
    exit 1
fi
cd ..
echo ""

# ==========================================
# 4. إعادة تشغيل جميع الخدمات
# ==========================================
echo "=================================================="
echo -e "${YELLOW}4️⃣  إعادة تشغيل الخدمات${NC}"
echo "=================================================="

if command -v pm2 &> /dev/null; then
    echo -e "${BLUE}إيقاف الخدمات القديمة...${NC}"
    pm2 stop all
    
    echo -e "${BLUE}بدء الخدمات...${NC}"
    
    # Start Backend
    cd backend-new
    pm2 delete backend-new 2>/dev/null || true
    pm2 start server.js --name backend-new
    cd ..
    
    # Start Frontend
    cd frontend-new
    pm2 delete frontend-new 2>/dev/null || true
    pm2 start npm --name frontend-new -- start
    cd ..
    
    pm2 save
    
    echo -e "${GREEN}✅ تم إعادة تشغيل جميع الخدمات${NC}"
    echo ""
    pm2 list
else
    echo -e "${RED}❌ PM2 غير موجود${NC}"
    echo "الرجاء تشغيل الخدمات يدوياً:"
    echo "  Backend: cd backend-new && node server.js &"
    echo "  Frontend: cd frontend-new && npm start &"
fi
echo ""

# ==========================================
# 5. اختبار الخدمات
# ==========================================
echo "=================================================="
echo -e "${YELLOW}5️⃣  اختبار الخدمات${NC}"
echo "=================================================="

echo -e "${BLUE}انتظار 5 ثوان...${NC}"
sleep 5

echo ""
echo "Port 3000 (Frontend):"
if lsof -i :3000 > /dev/null 2>&1; then
    echo -e "${GREEN}  ✅ يعمل${NC}"
else
    echo -e "${RED}  ❌ لا يعمل${NC}"
fi

echo "Port 3001 (Backend):"
if lsof -i :3001 > /dev/null 2>&1; then
    echo -e "${GREEN}  ✅ يعمل${NC}"
else
    echo -e "${RED}  ❌ لا يعمل${NC}"
fi

echo "Port 27017 (MongoDB):"
if lsof -i :27017 > /dev/null 2>&1; then
    echo -e "${GREEN}  ✅ يعمل${NC}"
else
    echo -e "${RED}  ❌ لا يعمل${NC}"
fi

echo ""
echo "=================================================="
echo -e "${GREEN}✅ انتهى!${NC}"
echo "=================================================="
echo ""
echo "الآن جرب فتح:"
echo "  https://unibus.online/admin/users"
echo ""
echo "وتحقق من Console (F12) للتأكد من عدم وجود أخطاء"
echo ""
