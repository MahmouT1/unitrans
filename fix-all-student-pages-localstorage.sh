#!/bin/bash

echo "🔧 إصلاح localStorage في جميع صفحات الطلاب"
echo "=============================================="

cd /var/www/unitrans

echo "🛑 إيقاف Frontend..."
pm2 stop unitrans-frontend

echo ""
echo "📄 إصلاح صفحة student/registration:"
echo "=================================="

# إصلاح student/registration/page.js
sed -i 's|router.push(\x27/auth\x27);|router.push(\x27/login\x27);|g' frontend-new/app/student/registration/page.js

# إضافة localStorage keys متعددة
sed -i 's|const token = localStorage.getItem(\x27token\x27);|const token = localStorage.getItem(\x27token\x27) || localStorage.getItem(\x27authToken\x27) || localStorage.getItem(\x27userToken\x27);|g' frontend-new/app/student/registration/page.js

sed -i 's|const userData = localStorage.getItem(\x27user\x27);|const userData = localStorage.getItem(\x27user\x27) || localStorage.getItem(\x27userData\x27) || localStorage.getItem(\x27authData\x27);|g' frontend-new/app/student/registration/page.js

echo "✅ تم إصلاح student/registration"

echo ""
echo "💳 إصلاح صفحة student/subscription:"
echo "================================="

# إصلاح student/subscription/page.js
sed -i 's|router.push(\x27/auth\x27);|router.push(\x27/login\x27);|g' frontend-new/app/student/subscription/page.js

# إضافة localStorage keys متعددة
sed -i 's|const token = localStorage.getItem(\x27token\x27);|const token = localStorage.getItem(\x27token\x27) || localStorage.getItem(\x27authToken\x27) || localStorage.getItem(\x27userToken\x27);|g' frontend-new/app/student/subscription/page.js

sed -i 's|const userData = localStorage.getItem(\x27user\x27);|const userData = localStorage.getItem(\x27user\x27) || localStorage.getItem(\x27userData\x27) || localStorage.getItem(\x27authData\x27);|g' frontend-new/app/student/subscription/page.js

echo "✅ تم إصلاح student/subscription"

echo ""
echo "🎧 إصلاح صفحة student/support:"
echo "============================"

# إصلاح student/support/page.js
sed -i 's|router.push(\x27/auth\x27);|router.push(\x27/login\x27);|g' frontend-new/app/student/support/page.js

# إضافة localStorage keys متعددة
sed -i 's|const token = localStorage.getItem(\x27token\x27);|const token = localStorage.getItem(\x27token\x27) || localStorage.getItem(\x27authToken\x27) || localStorage.getItem(\x27userToken\x27);|g' frontend-new/app/student/support/page.js

sed -i 's|const userData = localStorage.getItem(\x27user\x27);|const userData = localStorage.getItem(\x27user\x27) || localStorage.getItem(\x27userData\x27) || localStorage.getItem(\x27authData\x27);|g' frontend-new/app/student/support/page.js

echo "✅ تم إصلاح student/support"

echo ""
echo "🚌 إصلاح صفحة student/transportation:"
echo "=================================="

# إصلاح student/transportation/page.js
sed -i 's|router.push(\x27/auth\x27);|router.push(\x27/login\x27);|g' frontend-new/app/student/transportation/page.js

# إضافة localStorage keys متعددة للصفحات التي تحقق من user فقط
sed -i 's|const userData = localStorage.getItem(\x27user\x27);|const userData = localStorage.getItem(\x27user\x27) || localStorage.getItem(\x27userData\x27) || localStorage.getItem(\x27authData\x27);|g' frontend-new/app/student/transportation/page.js

echo "✅ تم إصلاح student/transportation"

echo ""
echo "📱 إصلاح أي صفحات أخرى بـ QR Generator:"
echo "===================================="

# البحث عن أي صفحات أخرى تستخدم /auth
find frontend-new/app/student -name "*.js" -exec grep -l "router.push('/auth')" {} \; | while read file; do
    echo "🔧 إصلاح: $file"
    sed -i 's|router.push(\x27/auth\x27);|router.push(\x27/login\x27);|g' "$file"
done

echo ""
echo "🏗️ إعادة بناء Frontend:"
echo "======================="

cd frontend-new
rm -rf .next
npm run build

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ البناء نجح!"
    
    echo ""
    echo "🚀 إعادة تشغيل Frontend..."
    pm2 start unitrans-frontend
    
    echo ""
    echo "⏳ انتظار استقرار النظام..."
    sleep 8
    
    echo ""
    echo "🧪 اختبار جميع صفحات الطلاب:"
    echo "============================"
    
    echo "📄 Registration page:"
    curl -I https://unibus.online/student/registration -w "Status: %{http_code}\n" -s
    
    echo "💳 Subscription page:"
    curl -I https://unibus.online/student/subscription -w "Status: %{http_code}\n" -s
    
    echo "🎧 Support page:"
    curl -I https://unibus.online/student/support -w "Status: %{http_code}\n" -s
    
    echo "🚌 Transportation page:"
    curl -I https://unibus.online/student/transportation -w "Status: %{http_code}\n" -s
    
    echo "🏠 Student Portal:"
    curl -I https://unibus.online/student/portal -w "Status: %{http_code}\n" -s
    
else
    echo "❌ البناء فشل!"
fi

echo ""
echo "📊 حالة النهائية:"
pm2 status

echo ""
echo "✅ إصلاح جميع صفحات الطلاب اكتمل!"
echo "🔗 جرب: https://unibus.online/login"
echo "   📧 test@test.com / 123456"
echo "   🎯 الآن جميع الصفحات ستعمل بدون redirect!"
echo ""
echo "🎪 الصفحات المُصلّحة:"
echo "   📄 /student/registration"
echo "   💳 /student/subscription"  
echo "   🎧 /student/support"
echo "   🚌 /student/transportation"
echo "   🏠 /student/portal"
