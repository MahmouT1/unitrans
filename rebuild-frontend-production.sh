#!/bin/bash

echo "🏗️  إعادة بناء Frontend في Production Mode"
echo "=============================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /var/www/unitrans/frontend-new

# 1. حذف البناء القديم
echo -e "${YELLOW}1️⃣  حذف البناء القديم${NC}"
rm -rf .next
echo -e "${GREEN}✅ تم حذف .next${NC}"
echo ""

# 2. إعادة البناء
echo -e "${YELLOW}2️⃣  بناء Frontend في Production Mode${NC}"
echo -e "${BLUE}جاري البناء... (قد يستغرق 1-2 دقيقة)${NC}"
echo ""

npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ تم البناء بنجاح!${NC}"
    BUILD_SUCCESS=true
else
    echo ""
    echo -e "${RED}❌ فشل البناء!${NC}"
    echo -e "${YELLOW}سنستخدم dev mode بدلاً من ذلك...${NC}"
    BUILD_SUCCESS=false
fi

echo ""

# 3. إعادة تشغيل Frontend
echo -e "${YELLOW}3️⃣  إعادة تشغيل Frontend${NC}"

cd /var/www/unitrans

pm2 delete unitrans-frontend 2>/dev/null || true

if [ "$BUILD_SUCCESS" = true ]; then
    echo -e "${BLUE}تشغيل في Production Mode...${NC}"
    cd frontend-new
    pm2 start npm --name unitrans-frontend -- start
else
    echo -e "${YELLOW}تشغيل في Dev Mode...${NC}"
    cd frontend-new
    pm2 start npm --name unitrans-frontend -- run dev
fi

cd /var/www/unitrans

pm2 save

echo -e "${GREEN}✅ تم تشغيل Frontend${NC}"
echo ""

# 4. انتظار
echo -e "${YELLOW}4️⃣  انتظار${NC}"
for i in {10..1}; do
    echo -ne "  ⏳ $i ثانية...\r"
    sleep 1
done
echo ""

# 5. اختبار
echo -e "${YELLOW}5️⃣  اختبار${NC}"
echo ""

curl -s http://localhost:3000/api/students/all?page=1&limit=3 | head -30

echo ""
echo ""

echo "================================================"
echo -e "${GREEN}✅ انتهى!${NC}"
echo "================================================"
echo ""

if [ "$BUILD_SUCCESS" = true ]; then
    echo -e "${GREEN}Frontend يعمل في Production Mode ✅${NC}"
else
    echo -e "${YELLOW}Frontend يعمل في Dev Mode (Build فشل)${NC}"
fi

echo ""
echo "الآن:"
echo "1. احذف cache المتصفح (Ctrl+Shift+Delete)"
echo "2. اذهب لـ: https://unibus.online/login"
echo "3. جرب Login"
echo ""

pm2 list
