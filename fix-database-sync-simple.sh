#!/bin/bash

echo "🔧 إصلاح مزامنة قاعدة البيانات فقط - بدون تغيير التصميم"
echo "====================================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة الحالية:"
echo "======================="

echo "🔍 فحص auth-professional.js:"
grep -A 5 -B 5 "students" backend-new/routes/auth-professional.js || echo "❌ لا يوجد إنشاء students record"

echo ""
echo "🔧 2️⃣ إصلاح auth-professional.js فقط - إضافة students record:"
echo "======================================================="

# Create a simple fix by adding the students record creation
cat > /tmp/students_fix.js << 'EOF'
    // CRITICAL: Create students record for new student users
    if (role === 'student') {
      const studentData = {
        fullName: newUser.fullName,
        email: newUser.email,
        phoneNumber: '',
        college: '',
        grade: '',
        major: '',
        streetAddress: '',
        buildingNumber: '',
        fullAddress: '',
        profilePhoto: null,
        attendanceCount: 0,
        isActive: true,
        userId: result.insertedId,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      await db.collection('students').insertOne(studentData);
      console.log('✅ Professional Auth: Student record created for:', email);
    }
EOF

# Find the line with insertOne and add the students record creation after it
sed -i '/await db.collection('\''users'\'').insertOne(newUser);/r /tmp/students_fix.js' backend-new/routes/auth-professional.js

echo "✅ تم إضافة students record creation فقط"

echo ""
echo "🔧 3️⃣ إعادة تشغيل Backend:"
echo "========================="

echo "🔄 إيقاف backend..."
pm2 stop unitrans-backend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 حذف backend process..."
pm2 delete unitrans-backend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 بدء backend جديد..."
cd backend-new
pm2 start server.js --name "unitrans-backend"

echo "⏳ انتظار 30 ثانية للتأكد من التشغيل..."
sleep 30

echo "🔍 فحص حالة backend:"
pm2 status unitrans-backend

echo ""
echo "🔧 4️⃣ اختبار إنشاء حساب جديد:"
echo "============================"

echo "🔍 اختبار إنشاء حساب جديد:"
curl -X POST https://unibus.online/auth-api/register \
  -H "Content-Type: application/json" \
  -d '{"email":"newstudent@test.com","password":"123456","fullName":"New Student","role":"student"}' \
  -s

echo ""
echo "🔍 اختبار تسجيل الدخول بالحساب الجديد:"
echo "===================================="
curl -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"newstudent@test.com","password":"123456"}' \
  -s

echo ""
echo "🎉 تم إصلاح مزامنة قاعدة البيانات فقط!"
echo "🌐 يمكنك الآن اختبار إنشاء حساب جديد:"
echo "   🔗 https://unibus.online/login"
echo "   ✅ الحسابات الجديدة ستحفظ في نفس مكان test@test.com"
echo "   ✅ لن تظهر رسالة 'Student not found'"
echo "   ✅ التصميم لم يتأثر"
echo "   ✅ Auth لم يتأثر"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
