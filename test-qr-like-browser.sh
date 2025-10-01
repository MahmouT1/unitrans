#!/bin/bash

echo "🧪 اختبار QR Code كما في المتصفح"
echo "===================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# البيانات كما يرسلها المتصفح
STUDENT_DATA='{
  "studentData": {
    "id": "68d0886b0362753dc7fd1b36",
    "studentId": "Not assigned",
    "fullName": "mahmoud tarek",
    "email": "mahmoudtarekmonaim@gmail.com",
    "phoneNumber": "01025713978",
    "college": "bis",
    "grade": "third-year",
    "major": "جلا"
  }
}'

echo -e "${YELLOW}البيانات المرسلة (كما في المتصفح):${NC}"
echo "$STUDENT_DATA" | head -15
echo ""

echo "===================================="
echo -e "${BLUE}1️⃣  اختبار Frontend API${NC}"
echo "===================================="

FRONTEND_RESPONSE=$(curl -s -X POST http://localhost:3000/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d "$STUDENT_DATA" 2>&1)

echo "الاستجابة:"
echo "$FRONTEND_RESPONSE" | head -50
echo ""

if echo "$FRONTEND_RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Frontend API نجح!${NC}"
    echo -e "${GREEN}✅ QR Code تم إنشاؤه!${NC}"
    FRONTEND_OK=true
elif echo "$FRONTEND_RESPONSE" | grep -q '"success":false'; then
    echo -e "${RED}❌ Frontend API رجع خطأ${NC}"
    ERROR_MSG=$(echo "$FRONTEND_RESPONSE" | grep -o '"message":"[^"]*"')
    echo -e "${RED}الخطأ: $ERROR_MSG${NC}"
    FRONTEND_OK=false
else
    echo -e "${YELLOW}⚠️  Frontend API رجع HTML أو invalid response${NC}"
    FRONTEND_OK=false
fi

echo ""
echo "===================================="
echo -e "${BLUE}2️⃣  اختبار Backend API مباشرة${NC}"
echo "===================================="

BACKEND_RESPONSE=$(curl -s -X POST http://localhost:3001/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d "$STUDENT_DATA" 2>&1)

echo "الاستجابة:"
echo "$BACKEND_RESPONSE" | head -50
echo ""

if echo "$BACKEND_RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Backend API نجح!${NC}"
    BACKEND_OK=true
else
    echo -e "${RED}❌ Backend API فشل${NC}"
    BACKEND_OK=false
fi

echo ""
echo "===================================="
echo -e "${YELLOW}📊 النتيجة النهائية${NC}"
echo "===================================="
echo ""

if [ "$FRONTEND_OK" = true ] && [ "$BACKEND_OK" = true ]; then
    echo -e "${GREEN}🎉 كل شيء يعمل على السيرفر!${NC}"
    echo ""
    echo -e "${BLUE}المشكلة في المتصفح - Cache!${NC}"
    echo ""
    echo "الحل:"
    echo "1. أغلق المتصفح تماماً"
    echo "2. افتحه من جديد"
    echo "3. Incognito Mode (Ctrl+Shift+N)"
    echo "4. اذهب لـ: https://unibus.online/login"
    echo "5. سجل دخول وجرب"
    echo ""
    echo -e "${GREEN}في Incognito سيعمل 100%!${NC}"
elif [ "$FRONTEND_OK" = false ] && [ "$BACKEND_OK" = true ]; then
    echo -e "${YELLOW}⚠️  Backend يعمل لكن Frontend لا يعمل${NC}"
    echo ""
    echo "يحتاج Frontend إعادة build و restart"
elif [ "$BACKEND_OK" = false ]; then
    echo -e "${RED}❌ Backend لا يعمل${NC}"
    echo ""
    echo "يحتاج Backend إصلاح"
fi

echo ""
