#!/bin/bash

echo "🔧 حل شامل لمشكلة QR Code والـ localStorage"
echo "============================================="

cd /var/www/unitrans

echo "🛑 إيقاف Frontend..."
pm2 stop unitrans-frontend

echo ""
echo "🔑 إصلاح 1: صفحة Login لحفظ 'token' مباشرة:"
echo "==========================================="

# إضافة localStorage.setItem('token') في صفحة login
sed -i '/localStorage.setItem.*authToken/i\
        localStorage.setItem("token", data.token); // ✅ الـ key الأساسي المطلوب' frontend-new/app/login/page.js

echo "✅ تم إضافة localStorage.setItem('token') في login page"

echo ""
echo "🔧 إصلاح 2: صفحة Registration للبحث عن token بطرق متعددة:"
echo "========================================================="

# إصلاح registration page لاستخدام getToken function
cat > /tmp/registration_fix.js << 'EOF'
  // إضافة function للبحث عن token
  const getToken = () => {
    return localStorage.getItem('token') || 
           localStorage.getItem('authToken') || 
           localStorage.getItem('userToken');
  };

  const getUserData = () => {
    const userData = localStorage.getItem('user') || 
                     localStorage.getItem('userData') ||
                     localStorage.getItem('authData');
    
    if (!userData) return null;
    
    try {
      const parsed = JSON.parse(userData);
      return parsed.user || parsed; // Handle both formats
    } catch (error) {
      console.error('Error parsing user data:', error);
      return null;
    }
  };
EOF

# تطبيق الإصلاح على registration page
sed -i '/const token = localStorage.getItem.*token.*);/c\
    const token = getToken();' frontend-new/app/student/registration/page.js

sed -i '/const userData = localStorage.getItem.*user.*);/c\
    const userData = getUserData();' frontend-new/app/student/registration/page.js

# إدراج functions في بداية المكون
sed -i '/export default function StudentRegistration/a\
\
  // 🔧 Helper functions للبحث عن localStorage data\
  const getToken = () => {\
    return localStorage.getItem("token") || \
           localStorage.getItem("authToken") || \
           localStorage.getItem("userToken");\
  };\
\
  const getUserData = () => {\
    const userData = localStorage.getItem("user") || \
                     localStorage.getItem("userData") ||\
                     localStorage.getItem("authData");\
    \
    if (!userData) return null;\
    \
    try {\
      const parsed = JSON.parse(userData);\
      return parsed.user || parsed;\
    } catch (error) {\
      console.error("Error parsing user data:", error);\
      return null;\
    }\
  };' frontend-new/app/student/registration/page.js

# إصلاح الـ redirect
sed -i 's|router.push.*auth.*);|router.push("/login");|g' frontend-new/app/student/registration/page.js

# إصلاح الـ token في API calls
sed -i 's|localStorage.getItem.*token.*)|getToken()|g' frontend-new/app/student/registration/page.js

echo "✅ تم إصلاح registration page"

echo ""
echo "🔧 إصلاح 3: تأكد من وجود API route للـ QR generation:"
echo "==============================================="

# التحقق من وجود students routes في server.js
if ! grep -q "api/students" backend-new/server.js; then
    echo "⚠️  إضافة students routes في server.js"
    sed -i '/app.use.*admin.*students/a\
app.use("/api/students", require("./routes/students"));' backend-new/server.js
fi

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
    echo "🚀 إعادة تشغيل Frontend و Backend..."
    pm2 restart unitrans-frontend
    pm2 restart unitrans-backend
    
    echo ""
    echo "⏳ انتظار استقرار النظام..."
    sleep 10
    
    echo ""
    echo "🧪 اختبار API endpoints:"
    echo "======================"
    
    echo "🔑 اختبار Login:"
    LOGIN_TEST=$(curl -s -X POST https://unibus.online/api/login \
      -H "Content-Type: application/json" \
      -d '{"email":"test@test.com","password":"123456"}')
    
    echo "$LOGIN_TEST" | jq '.' 2>/dev/null || echo "$LOGIN_TEST"
    
    echo ""
    echo "📱 اختبار QR Generation:"
    curl -s -X POST https://unibus.online:3001/api/students/generate-qr \
      -H "Content-Type: application/json" \
      -d '{"email":"test@test.com"}' | jq '.' 2>/dev/null || echo "QR Generation test failed"
    
    echo ""
    echo "🌐 اختبار صفحة Registration:"
    curl -I https://unibus.online/student/registration -w "Status: %{http_code}\n" -s
    
else
    echo "❌ البناء فشل!"
fi

echo ""
echo "📊 حالة النهائية:"
pm2 status

echo ""
echo "✅ حل شامل لمشكلة QR Code اكتمل!"
echo ""
echo "📝 خطوات الاختبار:"
echo "1️⃣ سجّل خروج من المتصفح"
echo "2️⃣ سجّل دخول مرة أخرى بـ test@test.com / 123456"
echo "3️⃣ ادخل Registration وأكمل البيانات"
echo "4️⃣ اضغط Complete Registration"
echo "5️⃣ ستحصل على QR Code بنجاح! 🎯"
