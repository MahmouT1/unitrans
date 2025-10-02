#!/bin/bash

echo "🔧 إصلاح عرض Student ID"
echo "======================================"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd /var/www/unitrans

echo -e "${YELLOW}1. سحب أحدث التعديلات...${NC}"
git pull origin main

echo ""
echo -e "${YELLOW}2. إعادة تشغيل Backend...${NC}"
pm2 restart unitrans-backend
pm2 save

echo ""
echo -e "${GREEN}✅ Backend تم تحديثه!${NC}"
echo ""

sleep 3

echo "======================================"
echo -e "${YELLOW}3. اختبار Student Data API:${NC}"
echo "======================================"
echo ""

# Test /api/students/data
STUDENT_DATA=$(curl -s "http://localhost:3001/api/students/data?email=mahmoudtarekmonaim@gmail.com")

echo "Student Data Response:"
echo "$STUDENT_DATA" | python3 -m json.tool | head -30

echo ""

STUDENT_ID=$(echo "$STUDENT_DATA" | grep -o '"studentId":"[^"]*"' | head -1)

if [ -n "$STUDENT_ID" ]; then
    echo -e "${GREEN}✅ studentId موجود في الاستجابة: $STUDENT_ID${NC}"
else
    echo -e "${RED}❌ studentId مفقود!${NC}"
fi

echo ""
echo "======================================"
echo -e "${YELLOW}4. اختبار Generate QR API:${NC}"
echo "======================================"
echo ""

QR_RESPONSE=$(curl -s -X POST "http://localhost:3001/api/students/generate-qr" \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com"}')

echo "Generate QR Response:"
echo "$QR_RESPONSE" | python3 -m json.tool | grep -A 10 '"student"'

echo ""

QR_STUDENT_ID=$(echo "$QR_RESPONSE" | grep -o '"studentId":"[^"]*"' | head -1)

if echo "$QR_RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ QR Generation نجح${NC}"
    if [ -n "$QR_STUDENT_ID" ]; then
        echo -e "${GREEN}✅ studentId موجود: $QR_STUDENT_ID${NC}"
    else
        echo -e "${YELLOW}⚠️  studentId مفقود في الاستجابة${NC}"
    fi
else
    echo -e "${RED}❌ QR Generation فشل${NC}"
    echo "$QR_RESPONSE" | head -c 200
fi

echo ""
echo "======================================"
echo -e "${GREEN}🎯 التطبيق اكتمل!${NC}"
echo "======================================"
echo ""
echo "الآن في المتصفح:"
echo "1. Ctrl+Shift+Delete → Clear all"
echo "2. Hard reload (Ctrl+Shift+R)"
echo "3. Student ID يجب أن يظهر!"
echo "4. Generate QR Code يجب أن يعمل!"
echo ""

