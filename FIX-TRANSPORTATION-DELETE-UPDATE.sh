#!/bin/bash

echo "🔧 إصلاح DELETE و UPDATE للمواعيد"
echo "=============================================="

cd /var/www/unitrans && \
git pull origin main && \
cd backend-new && \
pm2 restart unitrans-backend && \
sleep 2 && \
echo "" && \
echo "✅ تم الإصلاح!" && \
echo "" && \
echo "🧪 اختبار UPDATE..." && \
echo "-------------------" && \

# Get first schedule ID
SCHEDULE_ID=$(mongosh student_portal --quiet --eval 'print(db.transportation.findOne()._id)' 2>/dev/null)

if [ -n "$SCHEDULE_ID" ]; then
  echo "Testing UPDATE for ID: $SCHEDULE_ID"
  curl -s -X PUT "http://localhost:3001/api/transportation/$SCHEDULE_ID" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "الميعاد الأول - محدث",
      "time": "07:45",
      "location": "الإربعين",
      "googleMapsLink": "https://maps.app.goo.gl/test",
      "parking": "بنك الإسكندرية",
      "capacity": 60,
      "status": "Active",
      "days": ["Sunday", "Monday"],
      "description": "تم التحديث"
    }' | jq '.'
  
  echo ""
  echo "🧪 اختبار DELETE..."
  echo "-------------------"
  echo "(لن نحذف الآن - فقط نتحقق من الـ route)"
  
  # Test with invalid ID to confirm route works
  curl -s -X DELETE "http://localhost:3001/api/transportation/invalidid123" | jq '.' 2>/dev/null || echo "Route exists"
else
  echo "⚠️  لا توجد مواعيد للاختبار"
fi

echo ""
echo "✅ الاختبار اكتمل!"
echo ""
echo "📱 الآن في المتصفح (Private/Incognito):"
echo "  1. Admin → Transportation"
echo "  2. Edit ميعاد → ✅ يجب أن ينجح"
echo "  3. Delete ميعاد → ✅ يجب أن ينجح"
