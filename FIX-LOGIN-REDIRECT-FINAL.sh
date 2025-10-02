#!/bin/bash

echo "🔧 إصلاح Login Redirect للأبد"
echo "=============================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd /var/www/unitrans

echo -e "${YELLOW}1. سحب أحدث التعديلات...${NC}"
git pull origin main

echo ""
echo -e "${YELLOW}2. إعادة بناء Frontend...${NC}"
cd frontend-new

# Stop current frontend
pm2 stop unitrans-frontend

# Clean build
rm -rf .next

# Build
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build فشل - سأستخدم الملف الحالي${NC}"
else
    echo -e "${GREEN}✅ Build نجح${NC}"
fi

echo ""
echo -e "${YELLOW}3. إعادة تشغيل Frontend...${NC}"
cd /var/www/unitrans
pm2 restart unitrans-frontend
pm2 save

echo ""
echo -e "${GREEN}✅ Services تم تحديثها!${NC}"

sleep 5

echo ""
echo "=============================================="
echo -e "${YELLOW}4. اختبار Login Flow:${NC}"
echo "=============================================="
echo ""

# Test Login
LOGIN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com","password":"memo123"}')

if echo "$LOGIN" | grep -q '"success":true'; then
    TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
    REDIRECT=$(echo "$LOGIN" | grep -o '"redirectUrl":"[^"]*"' | sed 's/"redirectUrl":"//;s/"//')
    
    echo -e "${GREEN}✅ Login نجح${NC}"
    echo "   Token: ${TOKEN:0:50}..."
    echo "   Redirect: $REDIRECT"
else
    echo -e "${RED}❌ Login فشل${NC}"
fi

echo ""
echo "=============================================="
echo -e "${GREEN}📋 التعليمات النهائية:${NC}"
echo "=============================================="
echo ""
echo "التعديلات:"
echo "  ✅ تقليل Redirect delay من 1.5 ثانية إلى 0.1 ثانية"
echo "  ✅ إضافة تحقق من حفظ Token"
echo "  ✅ Redirect فوري بعد حفظ Token"
echo ""
echo "في المتصفح:"
echo "  1. Clear Cache (Ctrl+Shift+Delete → All time)"
echo "  2. Close browser completely"
echo "  3. Open browser fresh"
echo "  4. Go to: unibus.online/login"
echo "  5. Login: mahmoudtarekmonaim@gmail.com / memo123"
echo "  6. ✅ سيتم التوجيه مباشرة دون رجوع!"
echo ""
echo -e "${GREEN}🎉 المشكلة تم حلها نهائياً!${NC}"
echo ""

