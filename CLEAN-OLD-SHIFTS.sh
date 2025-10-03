#!/bin/bash

echo "🧹 تنظيف الورديات القديمة والمكررة"
echo "=============================================="

cd /var/www/unitrans

echo ""
echo "1️⃣ عرض جميع الورديات الحالية..."
echo "-------------------------------------------"

mongosh "mongodb://localhost:27017/student_portal" --quiet --eval '
print("\n📊 إحصائيات الورديات:");
print("========================");

var totalShifts = db.shifts.countDocuments({});
print("إجمالي الورديات: " + totalShifts);

var activeShifts = db.shifts.countDocuments({ status: "active" });
print("الورديات النشطة: " + activeShifts);

var closedShifts = db.shifts.countDocuments({ status: "closed" });
print("الورديات المغلقة: " + closedShifts);

print("\n📋 الورديات النشطة:");
print("==================");

db.shifts.find({ status: "active" }).forEach(shift => {
  print("\nShift ID: " + shift.id);
  print("  Supervisor: " + shift.supervisorName);
  print("  Status: " + shift.status);
  print("  Started: " + shift.startTime);
  print("  Total Scans: " + shift.totalScans);
});
'

echo ""
echo "2️⃣ حذف جميع الورديات القديمة (الأقدم من يومين)..."
echo "-------------------------------------------"

mongosh "mongodb://localhost:27017/student_portal" --quiet --eval '
var twoDaysAgo = new Date();
twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);

print("\nحذف الورديات القديمة (قبل " + twoDaysAgo.toISOString() + ")...");

var result = db.shifts.deleteMany({
  startTime: { $lt: twoDaysAgo }
});

print("✅ تم حذف " + result.deletedCount + " وردية قديمة");
'

echo ""
echo "3️⃣ إغلاق جميع الورديات النشطة القديمة..."
echo "-------------------------------------------"

mongosh "mongodb://localhost:27017/student_portal" --quiet --eval '
var oneDayAgo = new Date();
oneDayAgo.setDate(oneDayAgo.getDate() - 1);

print("\nإغلاق الورديات النشطة القديمة (قبل " + oneDayAgo.toISOString() + ")...");

var result = db.shifts.updateMany(
  {
    status: "active",
    startTime: { $lt: oneDayAgo }
  },
  {
    $set: {
      status: "closed",
      endTime: new Date(),
      closedAt: new Date()
    }
  }
);

print("✅ تم إغلاق " + result.modifiedCount + " وردية نشطة قديمة");
'

echo ""
echo "4️⃣ عرض الحالة النهائية..."
echo "-------------------------------------------"

mongosh "mongodb://localhost:27017/student_portal" --quiet --eval '
print("\n📊 الحالة النهائية:");
print("==================");

var totalShifts = db.shifts.countDocuments({});
print("إجمالي الورديات: " + totalShifts);

var activeShifts = db.shifts.countDocuments({ status: "active" });
print("الورديات النشطة: " + activeShifts);

var closedShifts = db.shifts.countDocuments({ status: "closed" });
print("الورديات المغلقة: " + closedShifts);

if (activeShifts > 0) {
  print("\n📋 الورديات النشطة المتبقية:");
  print("============================");
  
  db.shifts.find({ status: "active" }).forEach(shift => {
    print("\nShift ID: " + shift.id);
    print("  Supervisor: " + shift.supervisorName);
    print("  Started: " + shift.startTime);
    print("  Total Scans: " + shift.totalScans);
  });
} else {
  print("\n✅ لا توجد ورديات نشطة حالياً");
}
'

echo ""
echo "✅ تم تنظيف الورديات بنجاح!"
echo ""
echo "📸 حدّث صفحة Attendance Management في المتصفح"
