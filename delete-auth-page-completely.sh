#!/bin/bash

echo "🔧 حذف صفحة /auth نهائياً"
echo "======================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص صفحة /auth:"
echo "=================="

echo "🔍 فحص صفحة /auth:"
AUTH_PAGE=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/auth)
echo "Auth Page: $AUTH_PAGE"

echo ""
echo "🔍 فحص صفحة /login:"
LOGIN_PAGE=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/login)
echo "Login Page: $LOGIN_PAGE"

echo ""
echo "🔧 2️⃣ حذف صفحة /auth نهائياً:"
echo "=========================="

echo "🔄 حذف مجلد صفحة /auth:"
rm -rf frontend-new/app/auth

echo "✅ تم حذف صفحة /auth نهائياً"

echo ""
echo "🔧 3️⃣ إنشاء redirect من /auth إلى /login:"
echo "====================================="

# Create redirect from /auth to /login
mkdir -p frontend-new/app/auth
cat > frontend-new/app/auth/page.js << 'EOF'
'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function AuthRedirect() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to /login immediately
    router.replace('/login');
  }, [router]);

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: 'Arial, sans-serif',
      color: 'white'
    }}>
      <div style={{
        textAlign: 'center',
        padding: '40px'
      }}>
        <div style={{
          width: '80px',
          height: '80px',
          background: 'rgba(255,255,255,0.2)',
          borderRadius: '50%',
          margin: '0 auto 20px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: '32px'
        }}>
          🔄
        </div>
        <h1 style={{
          fontSize: '24px',
          fontWeight: 'bold',
          margin: '0 0 10px 0'
        }}>
          جاري التوجيه...
        </h1>
        <p style={{
          fontSize: '16px',
          margin: '0',
          opacity: 0.8
        }}>
          يتم توجيهك إلى صفحة تسجيل الدخول
        </p>
      </div>
    </div>
  );
}
EOF

echo "✅ تم إنشاء redirect من /auth إلى /login"

echo ""
echo "🔧 4️⃣ إعادة Build Frontend:"
echo "========================="

echo "🔄 حذف .next directory:"
rm -rf frontend-new/.next

echo "🔄 حذف node_modules/.cache:"
rm -rf frontend-new/node_modules/.cache

echo "🔄 إعادة build frontend:"
cd frontend-new
npm run build

echo ""
echo "🔍 فحص build result:"
if [ -d ".next" ]; then
    echo "✅ Build نجح!"
else
    echo "❌ Build فشل!"
fi

cd ..

echo ""
echo "🔧 5️⃣ إعادة تشغيل Frontend:"
echo "=========================="

echo "🔄 إعادة تشغيل frontend..."
pm2 restart unitrans-frontend

echo "⏳ انتظار 20 ثانية للتأكد من التشغيل..."
sleep 20

echo "🔍 فحص حالة frontend:"
pm2 status unitrans-frontend

echo ""
echo "🔧 6️⃣ اختبار الصفحات:"
echo "===================="

echo "🔍 اختبار صفحة /auth (يجب أن تعيد redirect):"
AUTH_PAGE_FINAL=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/auth)
echo "Auth Page: $AUTH_PAGE_FINAL"

echo ""
echo "🔍 اختبار صفحة /login:"
LOGIN_PAGE_FINAL=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/login)
echo "Login Page: $LOGIN_PAGE_FINAL"

echo ""
echo "🔧 7️⃣ اختبار Login بالبيانات:"
echo "==========================="

echo "🔍 اختبار login مع بيانات الطالب (test@test.com):"
echo "=============================================="
STUDENT_LOGIN=$(curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -s)
echo "Response: $STUDENT_LOGIN"

echo ""
echo "🔍 اختبار login مع بيانات الإدارة (roo2admin@gmail.com):"
echo "====================================================="
ADMIN_LOGIN=$(curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"roo2admin@gmail.com","password":"admin123"}' \
  -s)
echo "Response: $ADMIN_LOGIN"

echo ""
echo "🔍 اختبار login مع بيانات المشرف (ahmedazab@gmail.com):"
echo "====================================================="
SUPERVISOR_LOGIN=$(curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  -s)
echo "Response: $SUPERVISOR_LOGIN"

echo ""
echo "🔧 8️⃣ فحص Backend Logs:"
echo "====================="

echo "🔍 فحص backend logs:"
pm2 logs unitrans-backend --lines 10

echo ""
echo "📊 9️⃣ تقرير الحذف النهائي:"
echo "======================="

echo "✅ الإصلاحات المطبقة:"
echo "   🔧 تم حذف صفحة /auth نهائياً"
echo "   🔧 تم إنشاء redirect من /auth إلى /login"
echo "   🔄 تم إعادة build frontend"
echo "   🔄 تم إعادة تشغيل frontend"
echo "   🧪 تم اختبار الصفحات"
echo "   🧪 تم اختبار Login بالبيانات"

echo ""
echo "🎯 النتائج:"
echo "   📱 Auth Page: $AUTH_PAGE_FINAL (يجب أن يعيد redirect)"
echo "   📱 Login Page: $LOGIN_PAGE_FINAL"
echo "   🔐 Student Login: $(echo $STUDENT_LOGIN | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   🔐 Admin Login: $(echo $ADMIN_LOGIN | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   🔐 Supervisor Login: $(echo $SUPERVISOR_LOGIN | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"

echo ""
echo "🎉 تم حذف صفحة /auth نهائياً!"
echo "🌐 يمكنك الآن اختبار في المتصفح:"
echo "   🔗 https://unibus.online/login"
echo "   🔗 https://unibus.online/auth (سيتم توجيهك إلى /login)"
echo "   📧 test@test.com / 123456"
echo "   📧 roo2admin@gmail.com / admin123"
echo "   📧 ahmedazab@gmail.com / supervisor123"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
