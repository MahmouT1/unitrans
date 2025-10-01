#!/bin/bash

echo "🔍 مقارنة بيانات Sona و mahmoud"
echo "=================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "===================================="
echo -e "${YELLOW}1️⃣  Sona Mostafa (يعمل ✅)${NC}"
echo "===================================="

mongosh student_portal --quiet --eval "
print('في users:');
var sonUser = db.users.findOne({email:'sona123@gmail.com'});
if (sonUser) {
    printjson(sonUser);
} else {
    print('  ❌ غير موجود');
}

print('');
print('في students:');
var sonStudent = db.students.findOne({email:'sona123@gmail.com'});
if (sonStudent) {
    printjson(sonStudent);
} else {
    print('  ❌ غير موجود');
}
"

echo ""

echo "===================================="
echo -e "${YELLOW}2️⃣  mahmoud tarek (لا يعمل ❌)${NC}"
echo "===================================="

mongosh student_portal --quiet --eval "
print('في users:');
var mahUser = db.users.findOne({email:'mahmoudtarekmonaim@gmail.com'});
if (mahUser) {
    printjson(mahUser);
} else {
    print('  ❌ غير موجود');
}

print('');
print('في students:');
var mahStudent = db.students.findOne({email:'mahmoudtarekmonaim@gmail.com'});
if (mahStudent) {
    printjson(mahStudent);
} else {
    print('  ❌ غير موجود');
}
"

echo ""

echo "===================================="
echo -e "${YELLOW}3️⃣  المقارنة${NC}"
echo "===================================="

mongosh student_portal --quiet --eval "
var sona = db.students.findOne({email:'sona123@gmail.com'});
var mahmoud = db.students.findOne({email:'mahmoudtarekmonaim@gmail.com'});

print('الفرق بين الاثنين:\n');

print('Sona:');
if (sona) {
    print('  _id: ' + sona._id);
    print('  studentId: ' + (sona.studentId || 'Not assigned'));
    print('  userId: ' + (sona.userId || 'Not assigned'));
    print('  في students: ✅');
} else {
    print('  ❌ غير موجود في students');
}

print('');

print('mahmoud:');
if (mahmoud) {
    print('  _id: ' + mahmoud._id);
    print('  studentId: ' + (mahmoud.studentId || 'Not assigned'));
    print('  userId: ' + (mahmoud.userId || 'Not assigned'));
    print('  في students: ✅');
} else {
    print('  ❌ غير موجود في students');
}

print('');
print('الخلاصة:');
if (sona && mahmoud) {
    print('  ✅ كلاهما في student_portal → students');
} else if (sona && !mahmoud) {
    print('  ⚠️  sona موجود، mahmoud مفقود!');
} else {
    print('  ⚠️  مشكلة في البيانات');
}
"

echo ""

echo "===================================="
echo -e "${YELLOW}4️⃣  البحث في جميع قواعد البيانات${NC}"
echo "===================================="

mongosh --quiet --eval "
var dbs = ['student_portal', 'unitrans', 'student-portal'];

dbs.forEach(function(dbName) {
    try {
        var currentDb = db.getSiblingDB(dbName);
        
        var sona = currentDb.students.findOne({email:'sona123@gmail.com'});
        var mahmoud = currentDb.students.findOne({email:'mahmoudtarekmonaim@gmail.com'});
        
        if (sona || mahmoud) {
            print('📁 ' + dbName + ':');
            if (sona) print('  ✓ sona موجود');
            if (mahmoud) print('  ✓ mahmoud موجود');
            print('');
        }
    } catch(e) {}
});
"

echo ""
echo "✅ انتهى!"
echo ""
