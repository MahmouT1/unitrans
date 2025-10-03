#!/bin/bash

echo "🗑️  حذف جميع الورديات النشطة"
echo "=============================================="

cd /var/www/unitrans

echo ""
echo "1️⃣ عرض الورديات النشطة الحالية..."
echo "-------------------------------------------"

mongosh "mongodb://localhost:27017/student_portal" --quiet --eval '
var activeShifts = db.shifts.find({ status: "active" }).toArray();
print("عدد الورديات النشطة: " + activeShifts.length);

activeShifts.forEach(shift => {
  print("\n  Shift ID: " + shift.id);
  print("  Supervisor: " + shift.supervisorName);
  print("  Started: " + shift.startTime);
});
'

echo ""
echo "2️⃣ حذف جميع الورديات النشطة..."
echo "-------------------------------------------"

mongosh "mongodb://localhost:27017/student_portal" --quiet --eval '
var result = db.shifts.deleteMany({ status: "active" });
print("✅ تم حذف " + result.deletedCount + " وردية نشطة");
'

echo ""
echo "3️⃣ حذف جميع الورديات (اختياري - احتياطي)..."
echo "-------------------------------------------"

mongosh "mongodb://localhost:27017/student_portal" --quiet --eval '
// حذف كل الورديات الأقدم من اليوم
var today = new Date();
today.setHours(0, 0, 0, 0);

var result = db.shifts.deleteMany({
  startTime: { $lt: today }
});

print("✅ تم حذف " + result.deletedCount + " وردية قديمة إضافية");
'

echo ""
echo "4️⃣ التحقق من الحالة النهائية..."
echo "-------------------------------------------"

mongosh "mongodb://localhost:27017/student_portal" --quiet --eval '
var totalShifts = db.shifts.countDocuments({});
var activeShifts = db.shifts.countDocuments({ status: "active" });
var closedShifts = db.shifts.countDocuments({ status: "closed" });

print("\n📊 الحالة النهائية:");
print("==================");
print("إجمالي الورديات: " + totalShifts);
print("الورديات النشطة: " + activeShifts);
print("الورديات المغلقة: " + closedShifts);

if (activeShifts > 0) {
  print("\n⚠️  لا تزال هناك ورديات نشطة:");
  db.shifts.find({ status: "active" }).forEach(shift => {
    print("  - Shift ID: " + shift.id);
  });
} else {
  print("\n✅ تم حذف جميع الورديات النشطة بنجاح!");
}
'

echo ""
echo "✅ العملية اكتملت!"
echo ""
echo "📸 حدّث صفحة Attendance Management الآن (Ctrl+Shift+R)"
