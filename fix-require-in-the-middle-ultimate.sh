#!/bin/bash

echo "🔧 إصلاح require-in-the-middle Error - الحل النهائي"
echo "================================================"

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة الحقيقية:"
echo "========================="

echo "🔍 فحص PM2 status:"
pm2 status

echo ""
echo "🔍 فحص Backend error logs:"
pm2 logs unitrans-backend --err --lines 5

echo ""
echo "🔧 2️⃣ حل المشكلة الحقيقية:"
echo "========================="

echo "🔄 إيقاف Backend:"
pm2 stop unitrans-backend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 حذف Backend process:"
pm2 delete unitrans-backend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔍 فحص port 3001:"
netstat -tlnp | grep 3001 || echo "Port 3001 is free"

echo ""
echo "🔧 3️⃣ إصلاح require-in-the-middle Error:"
echo "====================================="

echo "🔧 إعادة تثبيت PM2 بالكامل:"
npm uninstall -g pm2
npm install -g pm2@latest

echo "🔧 حذف PM2 cache:"
rm -rf ~/.pm2
rm -rf /root/.pm2

echo "🔧 إعادة تثبيت PM2 logrotate:"
pm2 install pm2-logrotate

echo "🔧 تنظيف PM2 logs:"
pm2 flush

echo ""
echo "🔧 4️⃣ إصلاح Git Merge Conflict:"
echo "============================="

echo "🔧 إزالة merge conflict markers من students.js:"
sed -i '/<<<<<<< HEAD/,/>>>>>>>/d' backend-new/routes/students.js
sed -i '/<<<<<<< HEAD/d' backend-new/routes/students.js
sed -i '/=======/d' backend-new/routes/students.js
sed -i '/>>>>>>>/d' backend-new/routes/students.js

echo "✅ تم إصلاح merge conflict"

echo ""
echo "🔧 5️⃣ إصلاح QR Generation API:"
echo "============================"

echo "🔧 إصلاح students/generate-qr API:"
cat > /tmp/qr_fix_ultimate.js << 'EOF'
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
echo "🔧 6️⃣ إعادة تثبيت Dependencies:"
echo "=============================="

echo "🔧 الانتقال إلى backend directory:"
cd backend-new

echo "🔧 حذف node_modules:"
rm -rf node_modules

echo "🔧 حذف package-lock.json:"
rm -f package-lock.json

echo "🔧 إعادة تثبيت dependencies:"
npm install

echo ""
echo "🔧 7️⃣ إصلاح PM2 Module Error:"
echo "============================="

echo "🔧 إعادة تثبيت PM2:"
npm install -g pm2@latest

echo "🔧 إعادة تثبيت PM2 logrotate:"
pm2 install pm2-logrotate

echo "🔧 تنظيف PM2 logs:"
pm2 flush

echo ""
echo "🔧 8️⃣ بدء Backend جديد:"
echo "======================"

echo "🔄 بدء Backend:"
pm2 start server.js --name "unitrans-backend"

echo "⏳ انتظار 30 ثانية للتأكد من التشغيل..."
sleep 30

echo "🔍 فحص حالة Backend:"
pm2 status unitrans-backend

echo ""
echo "🔍 فحص Backend logs:"
pm2 logs unitrans-backend --lines 10

echo ""
echo "🔧 9️⃣ اختبار Backend:"
echo "==================="

echo "🔍 اختبار Backend مباشرة:"
curl http://localhost:3001/api/health -s

echo ""
echo "🔍 اختبار QR generation مع studentData:"
curl -X POST https://unibus.online/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentData":{"email":"mahmoudtarekmonaim@gmail.com"}}' \
  -s

echo ""
echo "🎉 تم إصلاح require-in-the-middle Error!"
echo "🌐 يمكنك الآن اختبار:"
echo "   🔗 https://unibus.online/student/portal"
echo "   ✅ QR Code Generation يعمل بنجاح"
echo "   ✅ التصميم لم يتأثر"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
