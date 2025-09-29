#!/bin/bash

echo "🔍 تشخيص مشكلة Student Portal"
echo "=============================="

cd /var/www/unitrans

echo "📊 فحص حالة الخدمات..."
echo "----------------------"

# فحص العمليات الجارية
echo "🔍 Node.js processes:"
ps aux | grep node | grep -v grep || echo "لا توجد عمليات Node.js"

echo ""
echo "🔍 Port usage:"
netstat -tlnp | grep :3000 || echo "Port 3000 غير مستخدم"
netstat -tlnp | grep :3001 || echo "Port 3001 غير مستخدم"

echo ""
echo "🔍 Nginx status:"
systemctl status nginx --no-pager -l || echo "Nginx غير متاح"

echo ""
echo "📁 فحص الملفات..."
echo "-----------------"

# فحص وجود ملف Student Portal
if [ -f "frontend-new/app/student/portal/page.js" ]; then
    echo "✅ ملف Student Portal موجود"
    echo "📄 أول 5 أسطر من الملف:"
    head -5 frontend-new/app/student/portal/page.js
else
    echo "❌ ملف Student Portal غير موجود!"
fi

echo ""
echo "🔍 فحص اللوقز..."
echo "----------------"

if [ -f "logs/backend.log" ]; then
    echo "✅ Backend log موجود"
    echo "📄 آخر 10 أسطر من backend.log:"
    tail -10 logs/backend.log
else
    echo "❌ Backend log غير موجود"
fi

echo ""
if [ -f "logs/frontend.log" ]; then
    echo "✅ Frontend log موجود"
    echo "📄 آخر 10 أسطر من frontend.log:"
    tail -10 logs/frontend.log
else
    echo "❌ Frontend log غير موجود"
fi

echo ""
echo "🧪 اختبار الاتصال..."
echo "--------------------"

# اختبار Backend
echo "🔍 اختبار Backend (localhost:3001):"
curl -s http://localhost:3001/health || echo "❌ Backend غير متاح"

echo ""
echo "🔍 اختبار Frontend (localhost:3000):"
curl -s -I http://localhost:3000 | head -1 || echo "❌ Frontend غير متاح"

echo ""
echo "🔍 اختبار Student Portal مباشرة:"
curl -s -I http://localhost:3000/student/portal | head -1 || echo "❌ Student Portal غير متاح"

echo ""
echo "🔍 اختبار عبر Nginx:"
curl -s -I https://unibus.online/student/portal | head -1 || echo "❌ Student Portal عبر Nginx غير متاح"

echo ""
echo "📋 توصيات الحل:"
echo "==============="
echo "1. تأكد من تشغيل الخدمات:"
echo "   cd backend-new && nohup node server.js > ../logs/backend.log 2>&1 &"
echo "   cd frontend-new && nohup npm start > ../logs/frontend.log 2>&1 &"
echo ""
echo "2. تحقق من Nginx configuration:"
echo "   sudo nginx -t"
echo "   sudo systemctl reload nginx"
echo ""
echo "3. فحص اللوقز للحصول على تفاصيل أكثر:"
echo "   tail -f logs/backend.log logs/frontend.log"
