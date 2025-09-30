#!/bin/bash

echo "🧹 تنظيف السيرفرات الزائدة من PM2"
echo "======================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}السيرفرات الحالية:${NC}"
pm2 list
echo ""

echo "======================================="
echo -e "${YELLOW}سأحذف السيرفرات الزائدة:${NC}"
echo "  ❌ frontend-new"
echo "  ❌ backend-new"
echo ""
echo -e "${GREEN}وأبقي السيرفرات الأصلية:${NC}"
echo "  ✅ unitrans-frontend"
echo "  ✅ unitrans-backend"
echo ""

read -p "هل تريد المتابعة؟ (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "تم الإلغاء"
    exit 0
fi

echo ""
echo "======================================="
echo -e "${YELLOW}حذف السيرفرات الزائدة...${NC}"
echo "======================================="

# حذف frontend-new
if pm2 list | grep -q "frontend-new"; then
    echo -e "${BLUE}حذف frontend-new...${NC}"
    pm2 delete frontend-new
    echo -e "${GREEN}✅ تم حذف frontend-new${NC}"
else
    echo -e "${YELLOW}⚠️  frontend-new غير موجود${NC}"
fi

echo ""

# حذف backend-new
if pm2 list | grep -q "backend-new"; then
    echo -e "${BLUE}حذف backend-new...${NC}"
    pm2 delete backend-new
    echo -e "${GREEN}✅ تم حذف backend-new${NC}"
else
    echo -e "${YELLOW}⚠️  backend-new غير موجود${NC}"
fi

echo ""

# حفظ التغييرات
pm2 save

echo ""
echo "======================================="
echo -e "${GREEN}✅ تم التنظيف!${NC}"
echo "======================================="
echo ""
echo -e "${BLUE}السيرفرات المتبقية:${NC}"
pm2 list

echo ""
echo -e "${GREEN}السيرفرات الأصلية فقط متبقية:${NC}"
echo "  ✅ unitrans-frontend"
echo "  ✅ unitrans-backend"
echo ""
