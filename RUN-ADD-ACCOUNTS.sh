#!/bin/bash

echo "👥 إضافة حسابات Admin و Supervisor"
echo "===================================="

cd /var/www/unitrans

# Copy script to backend
cp ADD-ADMIN-SUPERVISOR-ACCOUNTS.js backend-new/

cd backend-new

# Run the script
node ADD-ADMIN-SUPERVISOR-ACCOUNTS.js

echo ""
echo "🧪 التحقق من الحسابات..."
echo "========================"

mongosh student_portal --quiet --eval '
var supervisors = db.users.find({role: "supervisor"}).toArray();
var admins = db.users.find({role: "admin"}).toArray();

print("\n👥 Supervisors (" + supervisors.length + "):");
print("=================");
supervisors.forEach(function(u) {
  print("  ✅ " + u.fullName + " - " + u.email);
});

print("\n👑 Admins (" + admins.length + "):");
print("=================");
admins.forEach(function(u) {
  print("  ✅ " + u.fullName + " - " + u.email);
});
'

echo ""
echo "✅ تم إضافة جميع الحسابات!"
echo ""
echo "📱 اختبر تسجيل الدخول:"
echo "  🔗 unibus.online/login"
echo ""
echo "👥 Supervisor: sasasona@gmail.com / Sons123"
echo "👑 Admin: Azabuni123@gmail.com / Unibus00444"

# Cleanup
rm -f ADD-ADMIN-SUPERVISOR-ACCOUNTS.js
