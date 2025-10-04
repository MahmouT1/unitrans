#!/bin/bash

echo "🧪 اختبار Transportation الكامل على السيرفر"
echo "=============================================="

cd /var/www/unitrans

echo ""
echo "1️⃣ التحقق من البيانات في قاعدة البيانات..."
echo "-------------------------------------------"

mongosh student_portal --quiet --eval '
var count = db.transportation.countDocuments({});
print("عدد المواعيد في قاعدة البيانات: " + count);

if (count > 0) {
  print("\nالمواعيد الموجودة:");
  db.transportation.find().limit(3).forEach(function(t) {
    print("  - " + t.name + " | " + t.time + " | " + t.location);
    print("    Days: " + (t.days || []).join(", "));
  });
} else {
  print("\n⚠️  لا توجد مواعيد - سنضيف واحدة للاختبار...");
}
'

echo ""
echo "2️⃣ اختبار Backend GET /api/transportation..."
echo "-------------------------------------------"

curl -s "http://localhost:3001/api/transportation" | jq '{
  success: .success,
  count: (.transportation | length),
  schedules: .transportation | map({name: .name, time: .time, location: .location})
}' 2>/dev/null || curl -s "http://localhost:3001/api/transportation"

echo ""
echo "3️⃣ اختبار Frontend GET /api/transportation..."
echo "-------------------------------------------"

curl -s "http://localhost:3000/api/transportation" | jq '{
  success: .success,
  count: (.transportation | length)
}' 2>/dev/null || curl -s "http://localhost:3000/api/transportation"

echo ""
echo "4️⃣ اختبار إضافة موعد جديد (POST)..."
echo "-------------------------------------------"

curl -s -X POST "http://localhost:3001/api/transportation" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "الميعاد الأول",
    "time": "07:30",
    "location": "الإربعين",
    "googleMapsLink": "https://maps.app.goo.gl/test",
    "parking": "بنك الإسكندرية الإربعين",
    "capacity": 50,
    "status": "Active",
    "days": ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
    "description": "اختبار"
  }' | jq '.success, .message' 2>/dev/null || echo "تم الإرسال"

echo ""
echo "5️⃣ التحقق من البيانات بعد الإضافة..."
echo "-------------------------------------------"

mongosh student_portal --quiet --eval '
var count = db.transportation.countDocuments({});
print("عدد المواعيد الآن: " + count);
'

echo ""
echo "✅ الاختبار اكتمل!"
echo ""
echo "📊 الخلاصة:"
echo "  إذا ظهر success: true في الخطوات أعلاه ="
echo "  ✅ Backend يعمل"
echo "  ✅ Frontend API يعمل"
echo "  ✅ يمكنك إضافة مواعيد"
echo "  ✅ ستظهر في Student Portal"
