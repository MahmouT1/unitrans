#!/bin/bash

echo "🔧 Quick QR Code Fix"
echo "==================="

cd /home/unitrans

# Install qrcode package in backend
echo "📦 Installing qrcode package in backend..."
cd backend-new
npm install qrcode

# Add QR code route to backend
echo "🔧 Adding QR code route to backend..."
cat >> routes/students.js << 'EOF'

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

# Create frontend QR code route
echo "🔧 Creating frontend QR code route..."
cd ../frontend-new
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

# Restart services
echo "🔄 Restarting services..."
cd ../backend-new
pm2 restart unitrans-backend

sleep 5

cd ../frontend-new
pm2 restart unitrans-frontend

sleep 10

# Test QR code generation
echo "🧪 Testing QR code generation..."
curl -X POST http://localhost:3001/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentData":{"_id":"test","studentId":"STU123","fullName":"Test Student","email":"test@example.com"}}' \
  || echo "QR code test failed"

# Final status
echo "📊 Final PM2 status:"
pm2 status

echo ""
echo "✅ QR code fix completed!"
echo "🌍 Test at: https://unibus.online/student/portal"
