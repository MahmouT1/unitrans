#!/bin/bash

echo "🔧 إصلاح مشكلة التسجيل"
echo "=============================================="

cd /var/www/unitrans

echo ""
echo "1️⃣ إصلاح studentId null في قاعدة البيانات..."
echo "-------------------------------------------"

mongosh "mongodb://localhost:27017/student_portal" --quiet --eval '
// البحث عن students بـ studentId null
var studentsWithNullId = db.students.find({ studentId: null }).toArray();
print("عدد الطلاب بـ studentId null: " + studentsWithNullId.length);

// تحديث كل طالب بـ studentId فريد
var counter = 1000;
studentsWithNullId.forEach(student => {
  var newStudentId = "STU-" + String(counter).padStart(6, "0");
  db.students.updateOne(
    { _id: student._id },
    { $set: { studentId: newStudentId } }
  );
  print("تم تحديث: " + student.email + " → " + newStudentId);
  counter++;
});

print("\n✅ تم إصلاح studentId");
'

echo ""
echo "2️⃣ حذف Index المشكل وإعادة إنشائه..."
echo "-------------------------------------------"

mongosh "mongodb://localhost:27017/student_portal" --quiet --eval '
// حذف index القديم
try {
  db.students.dropIndex("studentId_1");
  print("✅ تم حذف Index القديم");
} catch (e) {
  print("⚠️  Index غير موجود أو تم حذفه بالفعل");
}

// إنشاء index جديد (unique و sparse)
db.students.createIndex(
  { studentId: 1 }, 
  { unique: true, sparse: true }
);
print("✅ تم إنشاء Index جديد");
'

echo ""
echo "3️⃣ التحقق من وجود auth routes..."
echo "-------------------------------------------"

if [ -f "backend-new/routes/auth.js" ]; then
  echo "✅ auth.js موجود"
  grep -n "router.post.*register" backend-new/routes/auth.js | head -5
else
  echo "❌ auth.js غير موجود!"
fi

echo ""
echo "4️⃣ التحقق من تسجيل routes في server.js..."
echo "-------------------------------------------"

grep -n "app.use.*auth" backend-new/server.js | head -5

echo ""
echo "5️⃣ إعادة تشغيل Backend..."
echo "-------------------------------------------"

pm2 restart unitrans-backend

sleep 3

echo ""
echo "6️⃣ اختبار Registration API..."
echo "-------------------------------------------"

curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Test User",
    "email": "newtest@test.com",
    "password": "test123",
    "role": "student"
  }' | jq '.'

echo ""
echo "✅ الإصلاح اكتمل!"
echo ""
echo "📸 جرب الآن في المتصفح!"
