#!/bin/bash

echo "🔧 Fixing students.js Syntax Error"
echo "================================="

cd /home/unitrans/backend-new

# Stop backend
pm2 stop unitrans-backend

# Create a clean students.js file
echo "🔧 Creating clean students.js file..."
cat > routes/students.js << 'EOF'
const express = require('express');
const router = express.Router();
const { ObjectId } = require('mongodb');

// Get student data by email
router.get('/data', async (req, res) => {
    try {
        const { email } = req.query;
        
        if (!email) {
            return res.status(400).json({
                success: false,
                message: 'Email parameter is required'
            });
        }

        const db = req.app.locals.db;
        if (!db) {
            return res.status(500).json({
                success: false,
                message: 'Database connection not available'
            });
        }

        const student = await db.collection('students').findOne({ 
            email: email.toLowerCase() 
        });

        if (!student) {
            return res.status(404).json({
                success: false,
                message: 'Student not found'
            });
        }

        res.json({
            success: true,
            student: student
        });

    } catch (error) {
        console.error('Get student data error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch student data',
            error: error.message
        });
    }
});

// Create student data (POST)
router.post('/data', async (req, res) => {
    try {
        const { 
            fullName, 
            email, 
            phoneNumber, 
            college, 
            grade, 
            major, 
            address, 
            profilePhoto,
            userId 
        } = req.body;

        if (!fullName || !email) {
            return res.status(400).json({
                success: false,
                message: 'Full name and email are required'
            });
        }

        const db = req.app.locals.db;
        if (!db) {
            return res.status(500).json({
                success: false,
                message: 'Database connection not available'
            });
        }

        // Check if student already exists
        const existingStudent = await db.collection('students').findOne({ 
            email: email.toLowerCase() 
        });

        if (existingStudent) {
            return res.status(409).json({
                success: false,
                message: 'Student with this email already exists'
            });
        }

        // Generate student ID
        const studentId = `STU${Date.now().toString().slice(-6)}`;

        // Create student document
        const studentData = {
            fullName,
            email: email.toLowerCase(),
            phoneNumber: phoneNumber || '',
            college: college || '',
            grade: grade || '',
            major: major || '',
            address: address || '',
            profilePhoto: profilePhoto || null,
            studentId,
            userId: userId || null,
            status: 'Active',
            createdAt: new Date(),
            updatedAt: new Date()
        };

        // Insert student into database
        const result = await db.collection('students').insertOne(studentData);

        if (result.insertedId) {
            res.json({
                success: true,
                message: 'Student data created successfully',
                student: {
                    _id: result.insertedId,
                    ...studentData
                }
            });
        } else {
            res.status(500).json({
                success: false,
                message: 'Failed to create student data'
            });
        }

    } catch (error) {
        console.error('Create student data error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create student data',
            error: error.message
        });
    }
});

// Update student data (PUT)
router.put('/data', async (req, res) => {
    try {
        const { 
            email,
            fullName, 
            phoneNumber, 
            college, 
            grade, 
            major, 
            address, 
            profilePhoto
        } = req.body;

        if (!email) {
            return res.status(400).json({
                success: false,
                message: 'Email is required'
            });
        }

        const db = req.app.locals.db;
        if (!db) {
            return res.status(500).json({
                success: false,
                message: 'Database connection not available'
            });
        }

        // Update student data
        const updateData = {
            updatedAt: new Date()
        };

        if (fullName) updateData.fullName = fullName;
        if (phoneNumber) updateData.phoneNumber = phoneNumber;
        if (college) updateData.college = college;
        if (grade) updateData.grade = grade;
        if (major) updateData.major = major;
        if (address) updateData.address = address;
        if (profilePhoto) updateData.profilePhoto = profilePhoto;

        const result = await db.collection('students').updateOne(
            { email: email.toLowerCase() },
            { $set: updateData }
        );

        if (result.matchedCount === 0) {
            return res.status(404).json({
                success: false,
                message: 'Student not found'
            });
        }

        // Get updated student data
        const updatedStudent = await db.collection('students').findOne({ 
            email: email.toLowerCase() 
        });

        res.json({
            success: true,
            message: 'Student data updated successfully',
            student: updatedStudent
        });

    } catch (error) {
        console.error('Update student data error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update student data',
            error: error.message
        });
    }
});

// Generate QR Code for student (No auth required)
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

module.exports = router;
EOF

# Check syntax
echo "🧪 Checking syntax..."
if node -c routes/students.js; then
    echo "✅ Syntax is valid"
else
    echo "❌ Syntax error still exists"
    exit 1
fi

# Start backend
echo "🚀 Starting backend..."
pm2 start unitrans-backend

# Wait for backend to start
sleep 5

# Test backend health
echo "🏥 Testing backend health..."
curl -s http://localhost:3001/api/health || echo "Backend not responding"

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
echo "✅ students.js syntax fix completed!"
echo "🌍 Test your project at: https://unibus.online"
