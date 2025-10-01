#!/bin/bash

echo "🏗️  إعادة بناء Frontend من الصفر"
echo "====================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd /var/www/unitrans/frontend-new

# 1. إيقاف Frontend
echo -e "${YELLOW}1️⃣  إيقاف Frontend${NC}"
pm2 stop unitrans-frontend
pm2 delete unitrans-frontend 2>/dev/null || true
echo -e "${GREEN}✅ تم الإيقاف${NC}"
echo ""

# 2. حذف كل ملفات Build والـ Cache
echo -e "${YELLOW}2️⃣  حذف جميع ملفات Build والـ Cache${NC}"
rm -rf .next
rm -rf node_modules/.cache
rm -rf .cache
echo -e "${GREEN}✅ تم الحذف${NC}"
echo ""

# 3. إعادة البناء
echo -e "${YELLOW}3️⃣  إعادة البناء من الصفر${NC}"
echo -e "${BLUE}جاري البناء... (قد يستغرق 1-3 دقائق)${NC}"
echo ""

npm run build 2>&1 | tail -30

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Build نجح!${NC}"
    USE_PROD=true
else
    echo ""
    echo -e "${RED}❌ Build فشل!${NC}"
    echo -e "${YELLOW}سنستخدم dev mode...${NC}"
    USE_PROD=false
fi

echo ""

# 4. بدء Frontend
echo -e "${YELLOW}4️⃣  بدء Frontend${NC}"

if [ "$USE_PROD" = true ]; then
    echo -e "${BLUE}Production Mode...${NC}"
    pm2 start npm --name unitrans-frontend -- start
else
    echo -e "${YELLOW}Dev Mode...${NC}"
    pm2 start npm --name unitrans-frontend -- run dev
fi

pm2 save

echo -e "${GREEN}✅ تم التشغيل${NC}"
echo ""

# 5. انتظار
echo -e "${YELLOW}5️⃣  انتظار Frontend${NC}"
for i in {15..1}; do
    echo -ne "  ⏳ $i ثانية...\r"
    sleep 1
done
echo ""

# 6. اختبار شامل
echo -e "${YELLOW}6️⃣  اختبار شامل${NC}"
echo "=====================================" 
echo ""

echo -e "${BLUE}Test 1: /api/students/all${NC}"
TEST1=$(curl -s http://localhost:3000/api/students/all?page=1&limit=1)
if echo "$TEST1" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Students API يعمل${NC}"
else
    echo -e "${RED}❌ Students API فشل${NC}"
fi

echo ""

echo -e "${BLUE}Test 2: /api/students/generate-qr (email)${NC}"
TEST2=$(curl -s -X POST http://localhost:3000/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com"}')
if echo "$TEST2" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Generate QR (email) يعمل${NC}"
else
    echo -e "${RED}❌ Generate QR (email) فشل${NC}"
    echo "Response: $TEST2"
fi

echo ""

echo -e "${BLUE}Test 3: /api/students/generate-qr (studentData)${NC}"
TEST3=$(curl -s -X POST http://localhost:3000/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentData":{"email":"mahmoudtarekmonaim@gmail.com","fullName":"mahmoud"}}')
if echo "$TEST3" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Generate QR (studentData) يعمل${NC}"
else
    echo -e "${RED}❌ Generate QR (studentData) فشل${NC}"
    echo "Response: $TEST3"
fi

echo ""

echo "====================================="
echo -e "${GREEN}✅ انتهى!${NC}"
echo "====================================="
echo ""

if [ "$USE_PROD" = true ]; then
    echo -e "${GREEN}Frontend يعمل في Production Mode${NC}"
else
    echo -e "${YELLOW}Frontend يعمل في Dev Mode${NC}"
fi

echo ""
echo -e "${BLUE}الآن في المتصفح:${NC}"
echo "1. افتح Incognito (Ctrl+Shift+N)"
echo "2. اذهب لـ: https://unibus.online/login"
echo "3. سجل دخول وجرب Generate QR"
echo ""

pm2 list
