#!/bin/bash

echo "➕ إضافة studentId للاستجابة"
echo "==============================="
echo ""

cd /var/www/unitrans/backend-new/routes

# Backup
cp students.js students.js.backup_studentid_response_$(date +%Y%m%d_%H%M%S)

# إضافة studentId بعد fullName في الاستجابة
sed -i '/fullName: student\.fullName,/a\      studentId: student.studentId || '"'"'Not assigned'"'"',' students.js

echo "✅ تم إضافة studentId للاستجابة"
echo ""

# التحقق
echo "التحقق:"
grep -A 5 "fullName: student.fullName" students.js | head -6

echo ""

# إعادة تشغيل Backend
cd /var/www/unitrans
pm2 restart unitrans-backend
pm2 save

echo "✅ Backend تم إعادة تشغيله"
echo ""

sleep 3

# اختبار
echo "==============================="
echo "اختبار API:"
echo "==============================="

curl -s "http://localhost:3001/api/students/data?email=mahmoudtarekmonaim@gmail.com"

echo ""
echo ""
echo "✅ تم!"
echo ""
echo "الآن في المتصفح:"
echo "  1. localStorage.clear()"
echo "  2. Logout"
echo "  3. Login من جديد"
echo "  4. Generate QR Code"
echo ""
