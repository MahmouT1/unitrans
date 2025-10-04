#!/bin/bash

echo "🔧 تطبيق إصلاح Transportation POST"
echo "=============================================="

cd /var/www/unitrans && \
git pull origin main && \
cd backend-new && \
pm2 restart unitrans-backend && \
sleep 3 && \
echo "" && \
echo "✅ تم تطبيق الإصلاح!" && \
echo "" && \
echo "🧪 الآن نختبر POST مرة أخرى..." && \
echo "" && \
curl -s -X POST "http://localhost:3001/api/transportation" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "الميعاد الأول",
    "time": "07:30",
    "location": "الإربعين",
    "googleMapsLink": "https://maps.app.goo.gl/wBrB51jCrs9e1dri6",
    "parking": "بنك الإسكندرية الإربعين",
    "capacity": 50,
    "status": "Active",
    "days": ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
    "description": "Any additional information about this route..."
  }' | jq '.' 2>/dev/null || echo "تم الإرسال"

echo ""
echo ""
echo "📊 التحقق من قاعدة البيانات..."
mongosh student_portal --quiet --eval '
var count = db.transportation.countDocuments({});
print("عدد المواعيد الآن: " + count);

if (count > 0) {
  print("\nآخر موعد تم إضافته:");
  var latest = db.transportation.find().sort({_id: -1}).limit(1).toArray()[0];
  print("  الاسم: " + latest.name);
  print("  الوقت: " + latest.time);
  print("  الموقع: " + latest.location);
  print("  السعة: " + latest.capacity);
}
'

echo ""
echo "✅ الاختبار اكتمل!"
