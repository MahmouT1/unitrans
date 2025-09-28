// إصلاح سريع لملف الحضور
const fs = require('fs');

const filePath = 'frontend-new/app/admin/attendance/page.js';
let content = fs.readFileSync(filePath, 'utf8');

// إصلاح خطأ map في loadAttendanceRecords
content = content.replace(
  /const uniqueStudents = new Set\(data\.records\.map\(record => record\.studentEmail\)\);/g,
  'const recordsArray = Array.isArray(data.records) ? data.records : [];\n          const uniqueStudents = new Set(recordsArray.map(record => record.studentEmail));'
);

content = content.replace(
  /const uniqueShifts = new Set\(data\.records\.map\(record => record\.shiftId\)\);/g,
  'const uniqueShifts = new Set(recordsArray.map(record => record.shiftId));'
);

content = content.replace(
  /todayRecords: data\.records\.filter\(record =>/g,
  'todayRecords: recordsArray.filter(record =>'
);

// إصلاح خطأ في loadActiveShifts
content = content.replace(
  /const trulyOpenShifts = \(data\.shifts \|\| \[\]\)\.filter/g,
  'const shiftsArray = Array.isArray(data.shifts) ? data.shifts : [];\n          const trulyOpenShifts = shiftsArray.filter'
);

fs.writeFileSync(filePath, content);
console.log('✅ تم إصلاح الملف');
