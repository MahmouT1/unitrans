#!/bin/bash

echo "🔧 Adding missing POST route for /api/students/data in backend"

cd /home/unitrans/backend-new

# Backup current file
cp routes/students.js routes/students.js.backup

# Add POST route for creating student data
cat >> routes/students.js << 'EOF'

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
EOF

# Restart backend
echo "🔄 Restarting backend..."
pm2 stop unitrans-backend
pm2 start "npm run start" --name "unitrans-backend"

echo "✅ Backend student data routes added!"
echo "🌍 Test at: https://unibus.online/student/registration"
