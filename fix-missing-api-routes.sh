#!/bin/bash

echo "🔧 إصلاح API Routes المفقودة ومشكلة Payload"
echo "=========================================="

cd /var/www/unitrans

echo ""
echo "📊 1️⃣ فحص API Routes الموجودة:"
echo "============================"

echo "🔍 فحص routes في backend:"
ls -la backend-new/routes/

echo ""
echo "🔍 فحص students.js:"
if [ -f "backend-new/routes/students.js" ]; then
    echo "✅ students.js موجود"
    echo "📋 محتوى students.js:"
    head -20 backend-new/routes/students.js
else
    echo "❌ students.js غير موجود!"
fi

echo ""
echo "🔧 2️⃣ إنشاء API Routes المفقودة:"
echo "==============================="

# إنشاء students.js إذا لم يكن موجود
if [ ! -f "backend-new/routes/students.js" ]; then
    echo "📝 إنشاء students.js..."
    
    cat > backend-new/routes/students.js << 'EOF'
const express = require('express');
const { MongoClient } = require('mongodb');
const router = express.Router();

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const DB_NAME = process.env.MONGODB_DB_NAME || 'student_portal';

let db;
MongoClient.connect(MONGODB_URI).then(client => {
    db = client.db(DB_NAME);
    console.log('✅ Connected to MongoDB for students routes');
}).catch(err => {
    console.error('❌ MongoDB connection error:', err);
});

// Get student data
router.get('/data', async (req, res) => {
    try {
        const { email } = req.query;
        
        if (!email) {
            return res.status(400).json({ success: false, message: 'Email is required' });
        }

        const studentsCollection = db.collection('students');
        const student = await studentsCollection.findOne({ email });

        if (!student) {
            return res.status(404).json({ success: false, message: 'Student not found' });
        }

        res.json({ success: true, student });
    } catch (error) {
        console.error('Error getting student data:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// Update student data
router.put('/data', async (req, res) => {
    try {
        const studentData = req.body;
        const { email } = studentData;

        if (!email) {
            return res.status(400).json({ success: false, message: 'Email is required' });
        }

        const studentsCollection = db.collection('students');
        
        // Update or create student
        const result = await studentsCollection.updateOne(
            { email },
            { $set: studentData },
            { upsert: true }
        );

        res.json({ 
            success: true, 
            message: 'Student data updated successfully',
            result 
        });
    } catch (error) {
        console.error('Error updating student data:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// Generate QR Code
router.post('/generate-qr', async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({ success: false, message: 'Email is required' });
        }

        // Simple QR code data
        const qrData = JSON.stringify({
            email: email,
            timestamp: new Date().toISOString(),
            type: 'student'
        });

        res.json({ 
            success: true, 
            message: 'QR Code generated successfully',
            qrCode: qrData
        });
    } catch (error) {
        console.error('Error generating QR code:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// Get student profile (simple)
router.get('/profile-simple', async (req, res) => {
    try {
        const { email } = req.query;
        
        if (!email) {
            return res.status(400).json({ success: false, message: 'Email is required' });
        }

        const studentsCollection = db.collection('students');
        const student = await studentsCollection.findOne({ email });

        if (!student) {
            return res.status(404).json({ success: false, message: 'Student not found' });
        }

        res.json({ 
            success: true, 
            student: {
                email: student.email,
                fullName: student.fullName,
                phoneNumber: student.phoneNumber,
                college: student.college,
                major: student.major
            }
        });
    } catch (error) {
        console.error('Error getting student profile:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// Search students
router.get('/search', async (req, res) => {
    try {
        const { q } = req.query;
        
        if (!q) {
            return res.status(400).json({ success: false, message: 'Search query is required' });
        }

        const studentsCollection = db.collection('students');
        const students = await studentsCollection.find({
            $or: [
                { email: { $regex: q, $options: 'i' } },
                { fullName: { $regex: q, $options: 'i' } }
            ]
        }).toArray();

        res.json({ success: true, students });
    } catch (error) {
        console.error('Error searching students:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

module.exports = router;
EOF

    echo "✅ تم إنشاء students.js"
else
    echo "✅ students.js موجود بالفعل"
fi

echo ""
echo "🔧 3️⃣ إصلاح مشكلة Payload Size:"
echo "============================="

echo "🔍 فحص server.js الحالي:"
if [ -f "backend-new/server.js" ]; then
    echo "📋 فحص express.json() limit:"
    grep -n "express.json" backend-new/server.js || echo "لم يتم العثور على express.json"
    
    echo "📋 فحص express.urlencoded() limit:"
    grep -n "express.urlencoded" backend-new/server.js || echo "لم يتم العثور على express.urlencoded"
fi

echo ""
echo "🔧 تحديث server.js لزيادة Payload limit:"
echo "======================================"

# إنشاء backup
cp backend-new/server.js backend-new/server.js.backup

# تحديث server.js
sed -i 's/express.json()/express.json({ limit: "100mb" })/g' backend-new/server.js
sed -i 's/express.urlencoded()/express.urlencoded({ limit: "100mb", extended: true })/g' backend-new/server.js

echo "✅ تم تحديث Payload limit إلى 100MB"

echo ""
echo "🔧 4️⃣ إعادة تشغيل Backend:"
echo "========================"

echo "🔄 إعادة تشغيل backend..."
pm2 restart unitrans-backend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔍 فحص حالة backend:"
pm2 status unitrans-backend

echo ""
echo "🧪 5️⃣ اختبار API Routes الجديدة:"
echo "==============================="

echo "🔍 اختبار /api/students/profile-simple:"
PROFILE_TEST=$(curl -s -X GET "https://unibus.online/api/students/profile-simple?email=test@test.com" \
  -H "Content-Type: application/json")

echo "Profile Simple Response:"
echo "$PROFILE_TEST" | jq '.' 2>/dev/null || echo "$PROFILE_TEST"

echo ""
echo "🔍 اختبار /api/students/search:"
SEARCH_TEST=$(curl -s -X GET "https://unibus.online/api/students/search?q=test" \
  -H "Content-Type: application/json")

echo "Search Response:"
echo "$SEARCH_TEST" | jq '.' 2>/dev/null || echo "$SEARCH_TEST"

echo ""
echo "🔍 اختبار /api/students/data:"
DATA_TEST=$(curl -s -X GET "https://unibus.online/api/students/data?email=test@test.com" \
  -H "Content-Type: application/json")

echo "Data Response:"
echo "$DATA_TEST" | jq '.' 2>/dev/null || echo "$DATA_TEST"

echo ""
echo "📊 6️⃣ تقرير الإصلاح النهائي:"
echo "========================="

echo "✅ الإصلاحات المطبقة:"
echo "   📝 تم إنشاء students.js مع جميع API routes"
echo "   📦 تم زيادة Payload limit إلى 100MB"
echo "   🔄 تم إعادة تشغيل backend"

echo ""
echo "🎯 النتائج:"
PROFILE_SUCCESS=$(echo "$PROFILE_TEST" | jq -r '.success' 2>/dev/null)
SEARCH_SUCCESS=$(echo "$SEARCH_TEST" | jq -r '.success' 2>/dev/null)
DATA_SUCCESS=$(echo "$DATA_TEST" | jq -r '.success' 2>/dev/null)

echo "   📋 Profile Simple: $([ "$PROFILE_SUCCESS" = "true" ] && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   🔍 Search: $([ "$SEARCH_SUCCESS" = "true" ] && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   📊 Data: $([ "$DATA_SUCCESS" = "true" ] && echo "✅ يعمل" || echo "❌ لا يعمل")"

if [ "$PROFILE_SUCCESS" = "true" ] && [ "$SEARCH_SUCCESS" = "true" ] && [ "$DATA_SUCCESS" = "true" ]; then
    echo ""
    echo "🎉 تم إصلاح جميع المشاكل!"
    echo "✅ API Routes تعمل بشكل كامل!"
    echo "🌐 يمكنك الآن اختبار Registration في المتصفح"
else
    echo ""
    echo "⚠️  لا تزال هناك مشاكل"
    echo "🔧 يُنصح بمراجعة الأخطاء"
fi
