#!/bin/bash

echo "🧪 اختبار تسجيل حساب جديد"
echo "=============================================="

cd /var/www/unitrans

echo ""
echo "1️⃣ التحقق من Backend logs..."
echo "-------------------------------------------"

pm2 logs unitrans-backend --lines 50 --nostream | grep -i "error\|register" | tail -20

echo ""
echo "2️⃣ اختبار Registration API مباشرة..."
echo "-------------------------------------------"

curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "testuser@test.com",
    "password": "test123",
    "role": "student"
  }' | jq '.'

echo ""
echo "3️⃣ التحقق من قاعدة البيانات..."
echo "-------------------------------------------"

mongosh "mongodb://localhost:27017/student_portal" --quiet --eval '
print("عدد المستخدمين: " + db.users.countDocuments({}));
print("\nآخر 3 مستخدمين:");
db.users.find({}).sort({createdAt: -1}).limit(3).forEach(user => {
  print("  - " + user.name + " (" + user.email + ") - Role: " + user.role);
});
'

echo ""
echo "4️⃣ التحقق من اتصال قاعدة البيانات..."
echo "-------------------------------------------"

mongosh "mongodb://localhost:27017/student_portal" --quiet --eval '
print("✅ الاتصال بقاعدة البيانات ناجح");
print("Database: " + db.getName());
'

echo ""
echo "✅ الاختبار اكتمل!"
