#!/bin/bash

echo "🔧 تحويل جميع الـ Emails إلى lowercase"
echo "========================================"

mongosh student_portal --quiet --eval '
// Update all emails to lowercase
var result = db.users.updateMany(
  {},
  [
    { $set: { email: { $toLower: "$email" } } }
  ]
);

print("✅ تم تحديث " + result.modifiedCount + " حسابات");

print("\n📋 قائمة الحسابات المحدثة:");
print("==========================");

var users = db.users.find().toArray();
users.forEach(function(u) {
  print(u.role + " | " + u.fullName + " | " + u.email);
});
'

echo ""
echo "✅ تم التحديث!"
echo ""
echo "🧪 الآن أعد اختبار تسجيل الدخول..."
echo ""

# Test one account
echo "Testing: sasasona@gmail.com"
curl -s -X POST "http://localhost:3001/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"sasasona@gmail.com","password":"Sons123"}' | jq '.success, .user.role'

echo ""
echo "📱 الآن اختبر في المتصفح:"
echo "  🔗 unibus.online/login"
echo "  📧 sasasona@gmail.com"
echo "  🔑 Sons123"
