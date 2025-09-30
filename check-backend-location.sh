#!/bin/bash

echo "🔍 فحص مجلد Backend الذي يستخدمه PM2"
echo "=========================================="
echo ""

# فحص PM2
echo "معلومات unitrans-backend من PM2:"
pm2 describe unitrans-backend | grep -E "script path|cwd|exec mode"

echo ""
echo "=========================================="
echo ""

# فحص المجلدات الموجودة
echo "مجلدات Backend الموجودة:"
ls -d /var/www/unitrans/backend* 2>/dev/null || echo "لا يوجد"

echo ""
echo "=========================================="
echo ""

# فحص أي منها يحتوي على server.js
echo "ملفات server.js الموجودة:"
find /var/www/unitrans -name "server.js" -type f 2>/dev/null

echo ""
echo "=========================================="
echo ""

# فحص routes/students.js في كل مجلد
echo "ملفات routes/students.js:"
find /var/www/unitrans -path "*/routes/students.js" -type f 2>/dev/null

echo ""
