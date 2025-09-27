#!/bin/bash

echo "🔧 Complete Fix for Student Registration - 500 Error"

cd /home/unitrans

# Stop all services
echo "⏹️ Stopping all services..."
pm2 stop all

# Check if backend routes exist
echo "🔍 Checking backend routes..."
if [ -f "backend-new/routes/students.js" ]; then
    echo "✅ students.js exists"
    # Check if POST route exists
    if grep -q "router.post('/data'" backend-new/routes/students.js; then
        echo "✅ POST route exists"
    else
        echo "❌ POST route missing - adding it..."
        
        # Add the missing POST route
        cat >> backend-new/routes/students.js << 'EOF'

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
    fi
else
    echo "❌ students.js not found"
fi

# Check MongoDB connection
echo "🔍 Checking MongoDB..."
systemctl status mongod

# Start backend
echo "🚀 Starting backend..."
cd backend-new
pm2 start "npm run start" --name "unitrans-backend"

# Wait for backend to start
sleep 5

# Test backend health
echo "🏥 Testing backend health..."
curl -s http://localhost:3001/api/health || echo "Backend not responding"

# Test the specific route
echo "🧪 Testing /api/students/data POST route..."
curl -X POST http://localhost:3001/api/students/data \
  -H "Content-Type: application/json" \
  -d '{"fullName":"Test Student","email":"test@example.com"}' \
  || echo "POST route test failed"

# Start frontend
echo "🚀 Starting frontend..."
cd ../frontend-new
pm2 start "npm run start" --name "unitrans-frontend"

# Wait for frontend to start
sleep 10

# Test frontend
echo "🌐 Testing frontend..."
curl -s http://localhost:3000 | head -20 || echo "Frontend not responding"

# Show PM2 status
echo "📊 PM2 Status:"
pm2 status

echo "✅ Complete fix applied!"
echo "🌍 Test at: https://unibus.online/student/registration"
