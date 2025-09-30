#!/bin/bash

echo "🔧 إغلاق الـ Shifts القديمة"
echo "==========================="

# Close all old open shifts
mongo student_portal --eval '
db.shifts.updateMany(
  { 
    status: "open",
    shiftEnd: null
  },
  { 
    $set: { 
      status: "closed",
      shiftEnd: new Date(),
      isActive: false
    } 
  }
)'

echo ""
echo "🔍 فحص الـ shifts المفتوحة الآن:"
mongo student_portal --eval "db.shifts.countDocuments({status: 'open', shiftEnd: null})"

echo ""
echo "✅ تم إغلاق الـ shifts القديمة!"
echo ""
echo "🧪 اختبار API:"
curl http://localhost:3001/api/shifts?status=open -s | jq '.shifts | length'

echo ""
echo "✅ تم!"
