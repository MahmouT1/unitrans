#!/bin/bash

echo "🧪 اختبار اشتراك karimahmed@gmail.com"
echo "=============================================="

cd /var/www/unitrans

echo ""
echo "1️⃣ التحقق من الاشتراك في قاعدة البيانات..."
echo "-------------------------------------------"

mongosh "mongodb://localhost:27017/student_portal" --quiet --eval '
db.subscriptions.find(
  { studentEmail: "karimahmed@gmail.com" }
).forEach(sub => {
  print("\n✅ اشتراك موجود:");
  print("  - Student: " + sub.studentName);
  print("  - Email: " + sub.studentEmail);
  print("  - Amount: " + sub.amount + " EGP");
  print("  - Type: " + sub.subscriptionType);
  print("  - Status: " + sub.status);
  print("  - Start Date: " + sub.startDate);
  print("  - End Date: " + sub.endDate);
  print("");
});

var count = db.subscriptions.countDocuments({ studentEmail: "karimahmed@gmail.com" });
print("📊 إجمالي الاشتراكات: " + count);
'

echo ""
echo "2️⃣ اختبار Backend API..."
echo "-------------------------------------------"

curl -s "http://localhost:3001/api/subscriptions/student?email=karimahmed@gmail.com" | jq '.'

echo ""
echo "3️⃣ اختبار Frontend API..."
echo "-------------------------------------------"

curl -s "http://localhost:3000/api/subscriptions/student?email=karimahmed@gmail.com" | jq '.'

echo ""
echo "✅ الاختبار اكتمل!"

