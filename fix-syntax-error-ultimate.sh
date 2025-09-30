#!/bin/bash

echo "🔧 إصلاح Syntax Error - الحل النهائي"
echo "===================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة:"
echo "=================="

pm2 status unitrans-backend
pm2 logs unitrans-backend --err --lines 5

echo ""
echo "🔧 2️⃣ إيقاف Backend:"
echo "==================="

pm2 stop unitrans-backend
pm2 delete unitrans-backend

echo ""
echo "🔧 3️⃣ حذف students.js التالف واستعادة النسخة الصحيحة:"
echo "=================================================="

cd /var/www/unitrans

# Backup
cp backend-new/routes/students.js backend-new/routes/students.js.corrupted.backup

# Force restore from git
git checkout HEAD -- backend-new/routes/students.js

echo "✅ تم استعادة students.js من Git"

echo ""
echo "🔧 4️⃣ تطبيق تعديلات QR Generation:"
echo "================================="

# Create the complete fixed students.js generate-qr endpoint
cat > /tmp/generate_qr_fix.js << 'ENDFIX'

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

ENDFIX

# Find and replace the generate-qr endpoint in students.js
# Use Python for more reliable text replacement
python3 << 'PYEND'
import re

# Read the file
with open('backend-new/routes/students.js', 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern to find the generate-qr endpoint
pattern = r"// Generate QR Code for existing student\s*router\.post\('/generate-qr'.*?\}\);\s*\}\);"

# Read the replacement
with open('/tmp/generate_qr_fix.js', 'r', encoding='utf-8') as f:
    replacement = f.read().strip()

# Replace
new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Write back
with open('backend-new/routes/students.js', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("✅ تم تطبيق التعديلات على students.js")
PYEND

echo ""
echo "🔧 5️⃣ التحقق من Syntax:"
echo "======================"

cd backend-new
node -c routes/students.js && echo "✅ Syntax is correct!" || echo "❌ Syntax errors found!"

echo ""
echo "🔧 6️⃣ إعادة تثبيت Dependencies:"
echo "==============================="

rm -rf node_modules
rm -f package-lock.json
npm install

echo ""
echo "🔧 7️⃣ بدء Backend:"
echo "================="

pm2 start server.js --name "unitrans-backend"

echo ""
echo "⏳ انتظار 30 ثانية..."
sleep 30

echo ""
echo "🔍 8️⃣ فحص Backend:"
echo "================="

pm2 status unitrans-backend
pm2 logs unitrans-backend --lines 20

echo ""
echo "🔧 9️⃣ اختبار Backend:"
echo "==================="

curl http://localhost:3001/api/health -s
echo ""
curl -X POST https://unibus.online/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentData":{"email":"mahmoudtarekmonaim@gmail.com"}}' \
  -s

echo ""
echo "✅ تم إصلاح المشكلة!"
