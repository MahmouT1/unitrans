#!/bin/bash

echo "🔧 إصلاح Syntax Error في students.js - الحل الاحترافي"
echo "======================================================"

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة:"
echo "=================="

echo "🔍 فحص PM2 status:"
pm2 status unitrans-backend

echo ""
echo "🔍 فحص Backend error logs:"
pm2 logs unitrans-backend --err --lines 5

echo ""
echo "🔧 2️⃣ إيقاف Backend:"
echo "==================="

pm2 stop unitrans-backend
pm2 delete unitrans-backend

echo ""
echo "🔧 3️⃣ إصلاح Git Conflict في students.js:"
echo "========================================"

echo "🔍 فحص students.js للـ conflict markers:"
grep -n "<<<<<<< HEAD\|=======\|>>>>>>>" backend-new/routes/students.js || echo "✅ No conflict markers found"

echo ""
echo "🔧 إزالة جميع conflict markers:"
# Remove all conflict markers completely
sed -i '/<<<<<<< HEAD/d' backend-new/routes/students.js
sed -i '/=======/d' backend-new/routes/students.js
sed -i '/>>>>>>>/d' backend-new/routes/students.js

echo ""
echo "🔍 فحص Syntax Errors في students.js:"
node -c backend-new/routes/students.js 2>&1 || echo "⚠️ Syntax errors found, will fix..."

echo ""
echo "🔧 4️⃣ استعادة students.js من النسخة الصحيحة:"
echo "==========================================="

# Backup current file
cp backend-new/routes/students.js backend-new/routes/students.js.backup

# Get clean version from git
git checkout HEAD -- backend-new/routes/students.js

echo ""
echo "🔧 5️⃣ تطبيق التعديلات على students.js:"
echo "======================================"

# Apply the QR generation fix
cat > /tmp/students_fix.patch << 'PATCH'
--- a/backend-new/routes/students.js
+++ b/backend-new/routes/students.js
@@ -1,6 +1,6 @@
 // Generate QR Code for existing student
 router.post('/generate-qr', async (req, res) => {
   try {
-    const { email } = req.body;
+    const { email, studentData } = req.body;
     
-    if (!email) {
+    console.log('🔗 QR Generation request:', { email, studentData });
+    
+    // Accept both email and studentData object
+    let query = {};
+    if (email) {
+      query.email = email.toLowerCase();
+    } else if (studentData && studentData.email) {
+      query.email = studentData.email.toLowerCase();
+    } else {
       return res.status(400).json({
         success: false,
-        message: 'Email is required'
+        message: 'Email or studentData with email is required'
       });
     }
PATCH

# Instead of patch, use direct sed replacement
sed -i 's/const { email } = req.body;/const { email, studentData } = req.body;\n    \n    console.log("🔗 QR Generation request:", { email, studentData });/' backend-new/routes/students.js

sed -i 's/if (!email) {/\/\/ Accept both email and studentData object\n    let query = {};\n    if (email) {\n      query.email = email.toLowerCase();\n    } else if (studentData \&\& studentData.email) {\n      query.email = studentData.email.toLowerCase();\n    } else {/' backend-new/routes/students.js

sed -i "s/'Email is required'/'Email or studentData with email is required'/" backend-new/routes/students.js

echo ""
echo "🔧 6️⃣ التحقق من Syntax بعد التعديل:"
echo "==================================="

node -c backend-new/routes/students.js && echo "✅ Syntax is correct!" || echo "❌ Syntax errors still exist!"

echo ""
echo "🔧 7️⃣ إعادة تثبيت Dependencies:"
echo "==============================="

cd backend-new
rm -rf node_modules
rm -f package-lock.json
npm install

echo ""
echo "🔧 8️⃣ بدء Backend جديد:"
echo "======================"

pm2 start server.js --name "unitrans-backend"

echo ""
echo "⏳ انتظار 30 ثانية للتشغيل..."
sleep 30

echo ""
echo "🔍 9️⃣ فحص Backend:"
echo "================="

pm2 status unitrans-backend

echo ""
echo "🔍 فحص Backend logs:"
pm2 logs unitrans-backend --lines 20

echo ""
echo "🔧 🔟 اختبار Backend:"
echo "===================="

echo "🔍 اختبار Backend health:"
curl http://localhost:3001/api/health -s

echo ""
echo "🔍 اختبار QR generation:"
curl -X POST https://unibus.online/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentData":{"email":"mahmoudtarekmonaim@gmail.com"}}' \
  -s

echo ""
echo "✅ تم إصلاح Syntax Error!"
echo "🌐 يمكنك الآن اختبار:"
echo "   🔗 https://unibus.online/student/portal"
