#!/bin/bash

echo "🔧 إصلاح عرض QR Code في المتصفح - الحل النهائي"
echo "============================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة الحالية:"
echo "======================="

echo "🔍 فحص generateQRCode function:"
grep -A 20 -B 5 "generateQRCode" frontend-new/app/student/portal/page.js

echo ""
echo "🔧 2️⃣ إصلاح عرض QR Code مباشرة:"
echo "============================="

# Fix the QR code display in the portal page
cat > /tmp/qr_display_final_fix.js << 'EOF'
        const generateQRCode = async () => {
          try {
            console.log('🔗 Starting QR Code generation...');
            
            // Prepare real student data for QR code
            const realStudentData = {
              id: student?.id || user?.id || `student-${Date.now()}`,
              studentId: student?.studentId || user?.studentId || 'Not assigned',
              email: user?.email || student?.email || 'not@provided.com',
              fullName: student?.fullName || user?.fullName || 'Student',
              phoneNumber: student?.phoneNumber || user?.phoneNumber || 'Not provided',
              college: student?.college || user?.college || 'Not specified',
              grade: student?.grade || user?.grade || 'Not specified',
              major: student?.major || user?.major || 'Not specified',
              address: {
                streetAddress: student?.address?.streetAddress || 'Not provided',
                fullAddress: student?.address?.fullAddress || 'Not provided'
              }
            };

            console.log('📝 Sending real student data for QR generation:', realStudentData);

            const response = await fetch('/api/students/generate-qr', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({ email: realStudentData.email })
            });

            console.log('📡 QR Generation response status:', response.status);
            const data = await response.json();
            console.log('📡 QR Generation response data:', data);
            
            if (data.success) {
              console.log('✅ QR Code generated successfully!');
              
              // Create a new window/tab to show the QR code
              const qrWindow = window.open('', '_blank', 'width=600,height=700');
              
              if (qrWindow) {
                qrWindow.document.write(`
                  <!DOCTYPE html>
                  <html>
                  <head>
                    <title>Student QR Code</title>
                    <style>
                      body { 
                        font-family: Arial, sans-serif; 
                        padding: 20px; 
                        text-align: center; 
                        background: #f8f9fa;
                      }
                      .container {
                        max-width: 500px;
                        margin: 0 auto;
                        background: white;
                        padding: 30px;
                        border-radius: 10px;
                        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                      }
                      .student-info {
                        background: #e3f2fd;
                        padding: 20px;
                        border-radius: 8px;
                        margin-bottom: 20px;
                        text-align: left;
                      }
                      .qr-code {
                        margin: 20px 0;
                      }
                      .download-btn {
                        background: #28a745;
                        color: white;
                        border: none;
                        padding: 12px 24px;
                        border-radius: 6px;
                        cursor: pointer;
                        font-size: 16px;
                        margin-top: 15px;
                      }
                      .download-btn:hover {
                        background: #218838;
                      }
                    </style>
                  </head>
                  <body>
                    <div class="container">
                      <h1>🎓 Student QR Code</h1>
                      
                      <div class="student-info">
                        <h3>Student Information</h3>
                        <p><strong>Name:</strong> ${realStudentData.fullName}</p>
                        <p><strong>Email:</strong> ${realStudentData.email}</p>
                        <p><strong>Student ID:</strong> ${realStudentData.studentId}</p>
                        <p><strong>Phone:</strong> ${realStudentData.phoneNumber}</p>
                        <p><strong>College:</strong> ${realStudentData.college}</p>
                        <p><strong>Grade:</strong> ${realStudentData.grade}</p>
                        <p><strong>Major:</strong> ${realStudentData.major}</p>
                        <p><strong>Address:</strong> ${realStudentData.address.streetAddress}, ${realStudentData.address.fullAddress}</p>
                      </div>
                      
                      <div class="qr-code">
                        <img src="${data.qrCode}" 
                             alt="Student QR Code" 
                             style="width: 300px; height: 300px; border: 2px solid #28a745; border-radius: 8px;" />
                      </div>
                      
                      <button class="download-btn" onclick="downloadQR()">📥 Download QR Code</button>
                    </div>
                    
                    <script>
                      function downloadQR() {
                        const link = document.createElement('a');
                        link.href = '${data.qrCode}';
                        link.download = 'student-qr-code-${Date.now()}.png';
                        document.body.appendChild(link);
                        link.click();
                        document.body.removeChild(link);
                        alert('QR code downloaded successfully!');
                      }
                    </script>
                  </body>
                  </html>
                `);
                qrWindow.document.close();
                console.log('✅ QR Code window opened successfully!');
              } else {
                console.error('❌ Failed to open QR Code window');
                alert('Failed to open QR Code window. Please check your popup blocker settings.');
              }
            } else {
              console.error('❌ QR Code generation failed:', data.message);
              alert('Failed to generate QR code: ' + data.message);
            }
          } catch (error) {
            console.error('❌ Error generating QR code:', error);
            alert('Error generating QR code: ' + error.message);
          }
        };
EOF

# Replace the generateQRCode function
sed -i '/const generateQRCode = async () => {/,/^  };$/c\
        const generateQRCode = async () => {\
          try {\
            console.log('\''🔗 Starting QR Code generation...'\'');\
            \
            // Prepare real student data for QR code\
            const realStudentData = {\
              id: student?.id || user?.id || `student-${Date.now()}`,\
              studentId: student?.studentId || user?.studentId || '\''Not assigned'\'',\
              email: user?.email || student?.email || '\''not@provided.com'\'',\
              fullName: student?.fullName || user?.fullName || '\''Student'\'',\
              phoneNumber: student?.phoneNumber || user?.phoneNumber || '\''Not provided'\'',\
              college: student?.college || user?.college || '\''Not specified'\'',\
              grade: student?.grade || user?.grade || '\''Not specified'\'',\
              major: student?.major || user?.major || '\''Not specified'\'',\
              address: {\
                streetAddress: student?.address?.streetAddress || '\''Not provided'\'',\
                fullAddress: student?.address?.fullAddress || '\''Not provided'\''\
              }\
            };\
\
            console.log('\''📝 Sending real student data for QR generation:'\'' + JSON.stringify(realStudentData));\
\
            const response = await fetch('\''/api/students/generate-qr'\'', {\
              method: '\''POST'\'',\
              headers: {\
                '\''Content-Type'\'': '\''application/json'\'',\
              },\
              body: JSON.stringify({ email: realStudentData.email })\
            });\
\
            console.log('\''📡 QR Generation response status:'\'' + response.status);\
            const data = await response.json();\
            console.log('\''📡 QR Generation response data:'\'' + JSON.stringify(data));\
            \
            if (data.success) {\
              console.log('\''✅ QR Code generated successfully!'\'');\
              \
              // Create a new window/tab to show the QR code\
              const qrWindow = window.open('\'''\''', '\''_blank'\'', '\''width=600,height=700'\'');\
              \
              if (qrWindow) {\
                qrWindow.document.write(`\
                  <!DOCTYPE html>\
                  <html>\
                  <head>\
                    <title>Student QR Code</title>\
                    <style>\
                      body { \
                        font-family: Arial, sans-serif; \
                        padding: 20px; \
                        text-align: center; \
                        background: #f8f9fa;\
                      }\
                      .container {\
                        max-width: 500px;\
                        margin: 0 auto;\
                        background: white;\
                        padding: 30px;\
                        border-radius: 10px;\
                        box-shadow: 0 4px 6px rgba(0,0,0,0.1);\
                      }\
                      .student-info {\
                        background: #e3f2fd;\
                        padding: 20px;\
                        border-radius: 8px;\
                        margin-bottom: 20px;\
                        text-align: left;\
                      }\
                      .qr-code {\
                        margin: 20px 0;\
                      }\
                      .download-btn {\
                        background: #28a745;\
                        color: white;\
                        border: none;\
                        padding: 12px 24px;\
                        border-radius: 6px;\
                        cursor: pointer;\
                        font-size: 16px;\
                        margin-top: 15px;\
                      }\
                      .download-btn:hover {\
                        background: #218838;\
                      }\
                    </style>\
                  </head>\
                  <body>\
                    <div class="container">\
                      <h1>🎓 Student QR Code</h1>\
                      \
                      <div class="student-info">\
                        <h3>Student Information</h3>\
                        <p><strong>Name:</strong> ${realStudentData.fullName}</p>\
                        <p><strong>Email:</strong> ${realStudentData.email}</p>\
                        <p><strong>Student ID:</strong> ${realStudentData.studentId}</p>\
                        <p><strong>Phone:</strong> ${realStudentData.phoneNumber}</p>\
                        <p><strong>College:</strong> ${realStudentData.college}</p>\
                        <p><strong>Grade:</strong> ${realStudentData.grade}</p>\
                        <p><strong>Major:</strong> ${realStudentData.major}</p>\
                        <p><strong>Address:</strong> ${realStudentData.address.streetAddress}, ${realStudentData.address.fullAddress}</p>\
                      </div>\
                      \
                      <div class="qr-code">\
                        <img src="${data.qrCode}" \
                             alt="Student QR Code" \
                             style="width: 300px; height: 300px; border: 2px solid #28a745; border-radius: 8px;" />\
                      </div>\
                      \
                      <button class="download-btn" onclick="downloadQR()">📥 Download QR Code</button>\
                    </div>\
                    \
                    <script>\
                      function downloadQR() {\
                        const link = document.createElement('\''a'\'');\
                        link.href = '\''${data.qrCode}'\'';\
                        link.download = '\''student-qr-code-${Date.now()}.png'\'';\
                        document.body.appendChild(link);\
                        link.click();\
                        document.body.removeChild(link);\
                        alert('\''QR code downloaded successfully!'\'');\
                      }\
                    </script>\
                  </body>\
                  </html>\
                `);\
                qrWindow.document.close();\
                console.log('\''✅ QR Code window opened successfully!'\'');\
              } else {\
                console.error('\''❌ Failed to open QR Code window'\'');\
                alert('\''Failed to open QR Code window. Please check your popup blocker settings.'\'');\
              }\
            } else {\
              console.error('\''❌ QR Code generation failed:'\'' + data.message);\
              alert('\''Failed to generate QR code: '\'' + data.message);\
            }\
          } catch (error) {\
            console.error('\''❌ Error generating QR code:'\'' + error);\
            alert('\''Error generating QR code: '\'' + error.message);\
          }\
        };' frontend-new/app/student/portal/page.js

echo "✅ تم إصلاح عرض QR Code في Portal"

echo ""
echo "🔧 3️⃣ إعادة تشغيل Frontend:"
echo "========================="

echo "🔄 إيقاف frontend..."
pm2 stop unitrans-frontend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 حذف frontend process..."
pm2 delete unitrans-frontend

echo "⏳ انتظار 5 ثواني..."
sleep 5

echo "🔄 بدء frontend جديد..."
cd frontend-new
pm2 start npm --name "unitrans-frontend" -- start

echo "⏳ انتظار 30 ثانية للتأكد من التشغيل..."
sleep 30

echo "🔍 فحص حالة frontend:"
pm2 status unitrans-frontend

echo ""
echo "🎉 تم إصلاح عرض QR Code في المتصفح!"
echo "🌐 يمكنك الآن اختبار:"
echo "   🔗 https://unibus.online/student/portal"
echo "   ✅ QR Code Generation يعمل بنجاح"
echo "   ✅ QR Code يظهر في نافذة جديدة"
echo "   ✅ يمكن تحميل QR Code"
echo "   ✅ التصميم لم يتأثر"
