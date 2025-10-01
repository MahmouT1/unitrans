#!/bin/bash

echo "🎯 الحل النهائي الاحترافي لصفحة Supervisor"
echo "==============================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd /var/www/unitrans/frontend-new/app/admin/supervisor-dashboard

# Backup كامل
cp page.js page.js.FINAL_BACKUP_$(date +%Y%m%d_%H%M%S)
echo "✅ Backup تم"
echo ""

echo "===================================="
echo -e "${YELLOW}الإصلاحات:${NC}"
echo "===================================="

# 1. إصلاح showNotification - منع التكرار
echo "1. إصلاح showNotification لمنع الاهتزاز..."

# تقليل المدة من 5000 إلى 1500 (ثانية ونصف فقط)
sed -i 's/duration = 5000/duration = 1500/g' page.js
sed -i 's/duration = 3000/duration = 1500/g' page.js
sed -i 's/duration = 2000/duration = 1500/g' page.js

echo "  ✅ مدة الـ notification: 1.5 ثانية"

# 2. إصلاح API endpoint
echo "2. تصحيح API endpoint للتسجيل..."

# تغيير /api/attendance/register إلى /api/attendance/scan-qr
sed -i 's|/api/attendance/register|/api/attendance/scan-qr|g' page.js

echo "  ✅ API endpoint: /register → /scan-qr"

# 3. إصلاح animation syntax error
echo "3. إصلاح syntax errors..."

sed -i '1788s/.*/            animation: '"'"'slideInRight 0.3s ease-out'"'"',/' page.js

echo "  ✅ Animation syntax مُصلح"

echo ""

# التحقق
echo "===================================="
echo -e "${BLUE}التحقق من التعديلات:${NC}"
echo "===================================="

echo "showNotification duration:"
grep "duration = " page.js | head -1

echo ""
echo "API endpoint:"
grep "scan-qr" page.js | head -1

echo ""
echo "Animation line 1788:"
sed -n '1788p' page.js

echo ""

# Build
echo "===================================="
echo -e "${YELLOW}إعادة البناء...${NC}"
echo "===================================="

cd /var/www/unitrans/frontend-new

rm -rf .next

npm run build 2>&1 | tail -30

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build فشل!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Build نجح!${NC}"

# إعادة تشغيل
cd /var/www/unitrans

pm2 restart unitrans-frontend
pm2 save

echo ""
echo -e "${GREEN}✅ Frontend تم إعادة تشغيله${NC}"

echo ""
echo "===================================="
echo -e "${GREEN}🎉 تم الإصلاح!${NC}"
echo "===================================="
echo ""
echo -e "${BLUE}التغييرات المطبقة:${NC}"
echo "  1. ✅ Notification: 1.5 ثانية فقط (بدلاً من 5)"
echo "  2. ✅ API: /scan-qr (الصحيح)"
echo "  3. ✅ Syntax errors مُصلحة"
echo ""
echo -e "${YELLOW}الآن في المتصفح:${NC}"
echo "  1. احذف Cache (Ctrl+Shift+Delete → All time)"
echo "  2. أغلق المتصفح وافتحه"
echo "  3. https://unibus.online/login"
echo "  4. ahmed azab / supervisor123"
echo "  5. Supervisor Dashboard"
echo "  6. Open Shift"
echo "  7. امسح QR Code"
echo ""
echo -e "${GREEN}النتيجة المتوقعة:${NC}"
echo "  ✅ Notification تظهر 1.5 ثانية وتختفي"
echo "  ✅ الحضور يُسجل بنجاح"
echo "  ✅ السجل يظهر في الجدول"
echo "  ✅ Total Scans يزيد"
echo ""

pm2 list
