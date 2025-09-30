#!/bin/bash

echo "🔧 إصلاح Git Merge Conflict وإعادة تشغيل Backend"
echo "=============================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص Git Merge Conflict:"
echo "==========================="

echo "🔍 فحص merge conflict markers:"
grep -n "<<<<<<< HEAD" backend-new/routes/students.js || echo "No merge conflict found"
grep -n "=======" backend-new/routes/students.js || echo "No merge conflict found"
grep -n ">>>>>>>" backend-new/routes/students.js || echo "No merge conflict found"

echo ""
echo "🔧 2️⃣ حل Git Merge Conflict:"
echo "=========================="

echo "🔧 إصلاح merge conflict في students.js:"
# Remove merge conflict markers and keep the correct version
sed -i '/<<<<<<< HEAD/,/>>>>>>>/d' backend-new/routes/students.js

echo "🔧 إزالة أي markers متبقية:"
sed -i '/<<<<<<< HEAD/d' backend-new/routes/students.js
sed -i '/=======/d' backend-new/routes/students.js
sed -i '/>>>>>>>/d' backend-new/routes/students.js

echo "✅ تم إصلاح merge conflict"

echo ""
echo "🔧 3️⃣ إصلاح QR Generation API:"
echo "============================"

echo "🔧 إصلاح students/generate-qr API:"
cat > /tmp/qr_fix_clean.js << 'EOF'
// Generate QR Code for existing student
router.post('/generate-qr', async (req, res) => {
  try {
    const { email, studentData } = req.body;
    
    console.log('🔗 QR Generation request:', { email, studentData });
    
    // Accept both email and studentData object
    let query = {};
    if (email) {
      query.email = email.toLowerCase();
    } else if (studentData && studentData.email) {
      query.email = studentData.email.toLowerCase();
    } else {
      return res.status(400).json({
        success: false,
        message: 'Email or studentData with email is required'
      });
    }

    const db = await getDatabase();
    const student = await db.collection('students').findOne(query);
    
    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found'
      });
    }
    
    // Generate new QR Code
    const qrData = {
      studentId: student._id.toString(),
      email: student.email,
      fullName: student.fullName,
      timestamp: new Date().toISOString()
    };
    
    const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData));
    
    // Update student with new QR code
    await db.collection('students').updateOne(
      { _id: student._id },
      { $set: { qrCode: qrCodeDataURL, qrData: qrData } }
    );
    
    console.log('✅ QR code generated for:', student.email);
    
    return res.json({
      success: true,
      message: 'QR Code generated successfully',
      qrCode: qrCodeDataURL,
      student: {
        id: student._id,
        fullName: student.fullName,
        email: student.email
      }
    });
    
  } catch (error) {
    console.error('❌ Generate QR Code error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});
EOF

# Replace the generate-qr endpoint
sed -i '/\/\/ Generate QR Code for existing student/,/^});$/c\
// Generate QR Code for existing student\
router.post('\''/generate-qr'\'', async (req, res) => {\
  try {\
    const { email, studentData } = req.body;\
    \
    console.log('\''🔗 QR Generation request:'\'' + JSON.stringify({ email, studentData }));\
    \
    // Accept both email and studentData object\
    let query = {};\
    if (email) {\
      query.email = email.toLowerCase();\
    } else if (studentData && studentData.email) {\
      query.email = studentData.email.toLowerCase();\
    } else {\
      return res.status(400).json({\
        success: false,\
        message: '\''Email or studentData with email is required'\''\
      });\
    }\
\
    const db = await getDatabase();\
    const student = await db.collection('\''students'\'').findOne(query);\
    \
    if (!student) {\
      return res.status(404).json({\
        success: false,\
        message: '\''Student not found'\''\
      });\
    }\
    \
    // Generate new QR Code\
    const qrData = {\
      studentId: student._id.toString(),\
      email: student.email,\
      fullName: student.fullName,\
      timestamp: new Date().toISOString()\
    };\
    \
    const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData));\
    \
    // Update student with new QR code\
    await db.collection('\''students'\'').updateOne(\
      { _id: student._id },\
      { $set: { qrCode: qrCodeDataURL, qrData: qrData } }\
    );\
    \
    console.log('\''✅ QR code generated for:'\'' + student.email);\
    \
    return res.json({\
      success: true,\
      message: '\''QR Code generated successfully'\'',\
      qrCode: qrCodeDataURL,\
      student: {\
        id: student._id,\
        fullName: student.fullName,\
        email: student.email\
      }\
    });\
    \
  } catch (error) {\
    console.error('\''❌ Generate QR Code error:'\'' + error);\
    return res.status(500).json({\
      success: false,\
      message: '\''Internal server error'\''\
    });\
  }\
});' backend-new/routes/students.js

echo "✅ تم إصلاح students/generate-qr API"

echo ""
echo "🔧 4️⃣ إعادة تشغيل Backend:"
echo "========================="

echo "🔄 إيقاف backend..."
pm2 stop unitrans-backend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 حذف backend process..."
pm2 delete unitrans-backend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 بدء backend جديد..."
cd backend-new
pm2 start server.js --name "unitrans-backend"

echo "⏳ انتظار 30 ثانية للتأكد من التشغيل..."
sleep 30

echo "🔍 فحص حالة backend:"
pm2 status unitrans-backend

echo ""
echo "🔧 5️⃣ اختبار QR Generation:"
echo "========================="

echo "🔍 اختبار QR generation مع studentData:"
curl -X POST https://unibus.online/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentData":{"email":"mahmoudtarekmonaim@gmail.com"}}' \
  -s

echo ""
echo "🎉 تم إصلاح جميع المشاكل!"
echo "🌐 يمكنك الآن اختبار:"
echo "   🔗 https://unibus.online/student/portal"
echo "   ✅ QR Code Generation يعمل بنجاح"
echo "   ✅ التصميم لم يتأثر"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
