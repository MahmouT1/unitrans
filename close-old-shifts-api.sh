#!/bin/bash

echo "🔧 إغلاق الـ Shifts القديمة عبر API"
echo "===================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص الـ shifts المفتوحة حالياً:"
curl http://localhost:3001/api/shifts?status=open -s | jq '.shifts | length'

echo ""
echo "🔧 2️⃣ إغلاق جميع الـ shifts المفتوحة:"

# Get all open shifts and close them one by one
SHIFT_IDS=$(curl http://localhost:3001/api/shifts?status=open -s | jq -r '.shifts[]._id // .shifts[].id' 2>/dev/null)

if [ -z "$SHIFT_IDS" ]; then
    echo "✅ لا توجد shifts مفتوحة"
else
    echo "🔧 إغلاق الـ shifts..."
    for SHIFT_ID in $SHIFT_IDS; do
        echo "🔧 إغلاق shift: $SHIFT_ID"
        curl -X POST http://localhost:3001/api/shifts/close \
          -H "Content-Type: application/json" \
          -d "{\"shiftId\":\"$SHIFT_ID\"}" \
          -s | jq '.success, .message' 2>/dev/null || echo "تم"
    done
fi

echo ""
echo "🔍 3️⃣ فحص النتيجة:"
curl http://localhost:3001/api/shifts?status=open -s | jq '.shifts | length'

echo ""
echo "✅ تم!"
