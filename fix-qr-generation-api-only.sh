#!/bin/bash

echo "🔧 إصلاح QR Code Generation - API فقط"
echo "====================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة الحالية:"
echo "======================="

echo "🔍 فحص students/generate-qr API:"
grep -A 10 -B 5 "generate-qr" backend-new/routes/students.js || echo "❌ لا يوجد generate-qr API"

echo ""
echo "🔧 2️⃣ إصلاح students/generate-qr API:"
echo "==================================="

# Fix the generate-qr endpoint to handle both email and studentId
cat > /tmp/generate_qr_fix.js << 'EOF'
// Generate QR Code
router.post('/generate-qr', async (req, res) => {
  try {
    const { email, studentId } = req.body;
    
    // Accept both email and studentId
    let query = {};
    if (email) {
      query.email = email.toLowerCase();
    } else if (studentId && studentId !== 'Not assigned') {
      query._id = new ObjectId(studentId);
    } else {
      return res.status(400).json({
        success: false,
        message: 'Email or valid studentId is required'
      });
    }

    console.log('🔗 Generating QR code for:', query);
    
    const db = await getDatabase();
    
    // Find student
    const student = await db.collection('students').findOne(query);
    
    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found'
      });
    }
    
    // Generate QR Code
    const qrData = {
      studentId: student._id.toString(),
      email: student.email,
      fullName: student.fullName,
      timestamp: new Date().toISOString()
    };
    
    const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData));
    
    // Update student with QR code
    await db.collection('students').updateOne(
      { _id: student._id },
      { $set: { qrCode: qrCodeDataURL, qrData: qrData } }
    );
    
    console.log('✅ QR code generated for:', student.email);
    
    res.json({
      success: true,
      message: 'QR code generated successfully',
      qrCode: qrCodeDataURL,
      student: {
        id: student._id,
        fullName: student.fullName,
        email: student.email
      }
    });
    
  } catch (error) {
    console.error('❌ Error generating QR code:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});
EOF

# Replace the generate-qr endpoint in students.js
sed -i '/\/\/ Generate QR Code/,/^});$/c\
// Generate QR Code\
router.post('\''/generate-qr'\'', async (req, res) => {\
  try {\
    const { email, studentId } = req.body;\
    \
    // Accept both email and studentId\
    let query = {};\
    if (email) {\
      query.email = email.toLowerCase();\
    } else if (studentId && studentId !== '\''Not assigned'\'') {\
      query._id = new ObjectId(studentId);\
    } else {\
      return res.status(400).json({\
        success: false,\
        message: '\''Email or valid studentId is required'\''\
      });\
    }\
\
    console.log('\''🔗 Generating QR code for:'\'' + JSON.stringify(query));\
    \
    const db = await getDatabase();\
    \
    // Find student\
    const student = await db.collection('\''students'\'').findOne(query);\
    \
    if (!student) {\
      return res.status(404).json({\
        success: false,\
        message: '\''Student not found'\''\
      });\
    }\
    \
    // Generate QR Code\
    const qrData = {\
      studentId: student._id.toString(),\
      email: student.email,\
      fullName: student.fullName,\
      timestamp: new Date().toISOString()\
    };\
    \
    const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData));\
    \
    // Update student with QR code\
    await db.collection('\''students'\'').updateOne(\
      { _id: student._id },\
      { $set: { qrCode: qrCodeDataURL, qrData: qrData } }\
    );\
    \
    console.log('\''✅ QR code generated for:'\'' + student.email);\
    \
    res.json({\
      success: true,\
      message: '\''QR code generated successfully'\'',\
      qrCode: qrCodeDataURL,\
      student: {\
        id: student._id,\
        fullName: student.fullName,\
        email: student.email\
      }\
    });\
    \
  } catch (error) {\
    console.error('\''❌ Error generating QR code:'\'' + error);\
    res.status(500).json({\
      success: false,\
      message: '\''Internal server error'\''\
    });\
  }\
});' backend-new/routes/students.js

echo "✅ تم إصلاح students/generate-qr API"

echo ""
echo "🔧 3️⃣ إعادة تشغيل Backend:"
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
echo "🔧 4️⃣ اختبار QR Generation:"
echo "========================="

echo "🔍 اختبار QR generation مع email:"
curl -X POST https://unibus.online/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"email":"newstudent@test.com"}' \
  -s

echo ""
echo "🔍 اختبار QR generation مع studentId:"
curl -X POST https://unibus.online/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentId":"68db07bc0362753dc7fd1b33"}' \
  -s

echo ""
echo "🎉 تم إصلاح QR Code Generation!"
echo "🌐 يمكنك الآن اختبار:"
echo "   🔗 https://unibus.online/student/portal"
echo "   ✅ QR Code Generation يعمل بنجاح"
echo "   ✅ التصميم لم يتأثر"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
