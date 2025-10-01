#!/bin/bash

echo "🔧 إصلاح خطأ Syntax في السطر 1788"
echo "====================================="
echo ""

cd /var/www/unitrans/frontend-new/app/admin/supervisor-dashboard

# Backup
cp page.js page.js.backup_syntax_$(date +%Y%m%d_%H%M%S)

# إصلاح السطر 1788 - حذف الفاصلة الزائدة بعد ease-out
# نبحث عن السطر ونستبدله
sed -i 's/animation: slideInRight 0\.2s ease-out,/animation: slideInRight 0.2s ease-out/' page.js

# التحقق من الإصلاح
echo "السطر 1788 بعد الإصلاح:"
sed -n '1788p' page.js

echo ""

# إذا كان هناك أي مشاكل أخرى مع ease-out,
# نصلح كل الحالات
sed -i 's/ease-out;,/ease-out,/g' page.js
sed -i 's/0\.2s ease-out,/0.2s ease-out/g' page.js
sed -i 's/0\.3s ease-out,/0.3s ease-out/g' page.js

echo "✅ تم إصلاح جميع الأخطاء المشابهة"
echo ""

# Build
cd /var/www/unitrans/frontend-new

echo "حذف .next..."
rm -rf .next

echo ""
echo "البناء..."
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build نجح!"
    
    # إعادة تشغيل
    cd /var/www/unitrans
    pm2 restart unitrans-frontend
    pm2 save
    
    echo ""
    echo "✅ تم إعادة تشغيل Frontend"
else
    echo ""
    echo "❌ Build فشل - عرض الأخطاء:"
    npm run build 2>&1 | grep "Error" | head -10
    exit 1
fi

echo ""
echo "====================================="
echo "✅ تم الإصلاح!"
echo "====================================="
echo ""
echo "جرب في المتصفح الآن!"
echo "اضغط Ctrl+Shift+R"
echo ""

pm2 list
