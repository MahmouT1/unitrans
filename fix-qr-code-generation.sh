#!/bin/bash

echo "🔧 Fixing QR Code Generation - Invalid Token Error"
echo "================================================="

cd /home/unitrans

# Check current status
echo "📊 Current PM2 status:"
pm2 status

# Check backend logs for QR code issues
echo "📋 Checking backend logs for QR code issues..."
pm2 logs unitrans-backend --lines 20 | grep -i -E "(qr|token|auth|error)" || echo "No QR-related logs found"

# Check if QR code route exists in backend
echo "🔍 Checking QR code route in backend..."
if [ -f "backend-new/routes/students.js" ]; then
    if grep -q "generate-qr" backend-new/routes/students.js; then
        echo "✅ QR code route exists in backend"
    else
        echo "❌ QR code route missing - adding it..."
        
        # Add QR code generation route
        cat >> backend-new/routes/students.js << 'EOF'

// Generate QR Code for student
router.post('/generate-qr', async (req, res) => {
    try {
        const { studentData } = req.body;
        
        if (!studentData) {
            return res.status(400).json({
                success: false,
                message: 'Student data is required'
            });
        }

        // Create QR code data
        const qrData = {
            studentId: studentData.studentId || studentData.id,
            id: studentData._id || studentData.id,
            name: studentData.fullName || studentData.name,
            email: studentData.email,
            college: studentData.college,
            grade: studentData.grade,
            major: studentData.major,
            timestamp: new Date().toISOString()
        };

        // Generate QR code using qrcode library
        const QRCode = require('qrcode');
        const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData));

        res.json({
            success: true,
            message: 'QR code generated successfully',
            qrCode: qrCodeDataURL,
            qrData: qrData
        });

    } catch (error) {
        console.error('QR code generation error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to generate QR code',
            error: error.message
        });
    }
});
EOF
    fi
else
    echo "❌ students.js route file not found"
fi

# Check if qrcode package is installed in backend
echo "📦 Checking qrcode package in backend..."
cd backend-new
if npm list qrcode > /dev/null 2>&1; then
    echo "✅ qrcode package is installed"
else
    echo "❌ qrcode package missing - installing..."
    npm install qrcode
fi

# Check frontend QR code generation
echo "🔍 Checking frontend QR code generation..."
cd ../frontend-new

# Check if QR code API route exists in frontend
if [ -f "app/api/students/generate-qr/route.js" ]; then
    echo "✅ Frontend QR code route exists"
    
    # Update the route to handle token issues
    cat > app/api/students/generate-qr/route.js << 'EOF'
import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export async function POST(request) {
    try {
        const body = await request.json();
        
        // Forward request to backend
        const response = await fetch(`${BACKEND_URL}/api/students/generate-qr`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body),
        });

        if (!response.ok) {
            const errorData = await response.json();
            return NextResponse.json({ 
                success: false, 
                message: errorData.message || 'Failed to generate QR code' 
            }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);

    } catch (error) {
        console.error('QR code generation error:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error during QR code generation',
            error: error.message 
        }, { status: 500 });
    }
}
EOF
else
    echo "❌ Frontend QR code route missing - creating it..."
    mkdir -p app/api/students/generate-qr
    cat > app/api/students/generate-qr/route.js << 'EOF'
import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export async function POST(request) {
    try {
        const body = await request.json();
        
        // Forward request to backend
        const response = await fetch(`${BACKEND_URL}/api/students/generate-qr`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body),
        });

        if (!response.ok) {
            const errorData = await response.json();
            return NextResponse.json({ 
                success: false, 
                message: errorData.message || 'Failed to generate QR code' 
            }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);

    } catch (error) {
        console.error('QR code generation error:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error during QR code generation',
            error: error.message 
        }, { status: 500 });
    }
}
EOF
fi

# Check student portal QR code generation
echo "🔍 Checking student portal QR code generation..."
if [ -f "app/student/portal/page.js" ]; then
    echo "✅ Student portal exists"
    
    # Check if QR code generation function exists
    if grep -q "generateQRCode" app/student/portal/page.js; then
        echo "✅ QR code generation function exists"
    else
        echo "❌ QR code generation function missing - adding it..."
        
        # Add QR code generation function to student portal
        cat >> app/student/portal/page.js << 'EOF'

  const generateQRCode = async () => {
    try {
      if (!student || !user) {
        alert('Student data not loaded');
        return;
      }

      const studentData = {
        _id: student._id,
        studentId: student.studentId,
        fullName: student.fullName,
        email: student.email,
        college: student.college,
        grade: student.grade,
        major: student.major
      };

      const response = await fetch('/api/students/generate-qr', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ studentData }),
      });

      const result = await response.json();

      if (result.success) {
        // Display QR code
        const qrCodeImg = document.createElement('img');
        qrCodeImg.src = result.qrCode;
        qrCodeImg.style.maxWidth = '300px';
        qrCodeImg.style.margin = '20px auto';
        qrCodeImg.style.display = 'block';
        
        // Create modal to display QR code
        const modal = document.createElement('div');
        modal.style.position = 'fixed';
        modal.style.top = '0';
        modal.style.left = '0';
        modal.style.width = '100%';
        modal.style.height = '100%';
        modal.style.backgroundColor = 'rgba(0,0,0,0.8)';
        modal.style.display = 'flex';
        modal.style.alignItems = 'center';
        modal.style.justifyContent = 'center';
        modal.style.zIndex = '9999';
        
        const modalContent = document.createElement('div');
        modalContent.style.backgroundColor = 'white';
        modalContent.style.padding = '20px';
        modalContent.style.borderRadius = '10px';
        modalContent.style.textAlign = 'center';
        
        const closeBtn = document.createElement('button');
        closeBtn.textContent = 'Close';
        closeBtn.style.marginTop = '10px';
        closeBtn.style.padding = '10px 20px';
        closeBtn.style.backgroundColor = '#667eea';
        closeBtn.style.color = 'white';
        closeBtn.style.border = 'none';
        closeBtn.style.borderRadius = '5px';
        closeBtn.style.cursor = 'pointer';
        
        closeBtn.onclick = () => {
          document.body.removeChild(modal);
        };
        
        modalContent.appendChild(qrCodeImg);
        modalContent.appendChild(closeBtn);
        modal.appendChild(modalContent);
        document.body.appendChild(modal);
        
      } else {
        alert('Error generating QR code: ' + result.message);
      }
    } catch (error) {
      console.error('QR code generation error:', error);
      alert('Error generating QR code: ' + error.message);
    }
  };
EOF
    fi
else
    echo "❌ Student portal not found"
fi

# Restart backend to apply changes
echo "🔄 Restarting backend to apply changes..."
cd ../backend-new
pm2 restart unitrans-backend

# Wait for backend to restart
sleep 5

# Test QR code generation
echo "🧪 Testing QR code generation..."
curl -X POST http://localhost:3001/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentData":{"_id":"test","studentId":"STU123","fullName":"Test Student","email":"test@example.com"}}' \
  || echo "QR code test failed"

# Restart frontend
echo "🔄 Restarting frontend..."
cd ../frontend-new
pm2 restart unitrans-frontend

# Wait for frontend to restart
sleep 10

# Final status
echo "📊 Final PM2 status:"
pm2 status

echo ""
echo "✅ QR code generation fix completed!"
echo "🌍 Test QR code generation at: https://unibus.online/student/portal"
echo "📋 Check logs with: pm2 logs"
