#!/bin/bash

echo "🔧 Fix Shifts API Route"
echo "======================="

cd /home/unitrans

# Stop frontend
echo "⏹️ Stopping frontend..."
pm2 stop unitrans-frontend

# Navigate to frontend directory
cd frontend-new

# Check if the shifts API route exists in the backend
echo "🔍 Checking backend shifts route..."

# Check backend routes
if [ -f "../backend-new/routes/shifts.js" ]; then
    echo "✅ Backend shifts route exists"
else
    echo "❌ Backend shifts route missing"
fi

# Create the missing API proxy route for shifts
echo "🔧 Creating API proxy route for shifts..."

mkdir -p app/api/shifts

cat > app/api/shifts/route.js << 'EOF'
import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export async function GET(request) {
    try {
        const { searchParams } = new URL(request.url);
        const queryString = searchParams.toString();
        const url = queryString ? `${BACKEND_URL}/api/shifts?${queryString}` : `${BACKEND_URL}/api/shifts`;
        
        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (!response.ok) {
            const errorData = await response.json();
            return NextResponse.json({ success: false, message: errorData.message || 'Failed to fetch shifts from backend' }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);
    } catch (error) {
        console.error('Proxy GET /api/shifts error:', error);
        return NextResponse.json({ success: false, message: 'Internal server error during GET', error: error.message }, { status: 500 });
    }
}

export async function POST(request) {
    try {
        const body = await request.json();
        const response = await fetch(`${BACKEND_URL}/api/shifts`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body),
        });

        if (!response.ok) {
            const errorData = await response.json();
            return NextResponse.json({ success: false, message: errorData.message || 'Failed to create shift in backend' }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);
    } catch (error) {
        console.error('Proxy POST /api/shifts error:', error);
        return NextResponse.json({ success: false, message: 'Internal server error during POST', error: error.message }, { status: 500 });
    }
}

export async function PUT(request) {
    try {
        const body = await request.json();
        const response = await fetch(`${BACKEND_URL}/api/shifts`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body),
        });

        if (!response.ok) {
            const errorData = await response.json();
            return NextResponse.json({ success: false, message: errorData.message || 'Failed to update shift in backend' }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);
    } catch (error) {
        console.error('Proxy PUT /api/shifts error:', error);
        return NextResponse.json({ success: false, message: 'Internal server error during PUT', error: error.message }, { status: 500 });
    }
}
EOF

# Also create the [id] route for individual shift operations
cat > app/api/shifts/[id]/route.js << 'EOF'
import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export async function GET(request, { params }) {
    try {
        const { id } = params;
        const response = await fetch(`${BACKEND_URL}/api/shifts/${id}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (!response.ok) {
            const errorData = await response.json();
            return NextResponse.json({ success: false, message: errorData.message || 'Failed to fetch shift from backend' }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);
    } catch (error) {
        console.error('Proxy GET /api/shifts/[id] error:', error);
        return NextResponse.json({ success: false, message: 'Internal server error during GET', error: error.message }, { status: 500 });
    }
}

export async function PUT(request, { params }) {
    try {
        const { id } = params;
        const body = await request.json();
        const response = await fetch(`${BACKEND_URL}/api/shifts/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body),
        });

        if (!response.ok) {
            const errorData = await response.json();
            return NextResponse.json({ success: false, message: errorData.message || 'Failed to update shift in backend' }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);
    } catch (error) {
        console.error('Proxy PUT /api/shifts/[id] error:', error);
        return NextResponse.json({ success: false, message: 'Internal server error during PUT', error: error.message }, { status: 500 });
    }
}

export async function DELETE(request, { params }) {
    try {
        const { id } = params;
        const response = await fetch(`${BACKEND_URL}/api/shifts/${id}`, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (!response.ok) {
            const errorData = await response.json();
            return NextResponse.json({ success: false, message: errorData.message || 'Failed to delete shift in backend' }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);
    } catch (error) {
        console.error('Proxy DELETE /api/shifts/[id] error:', error);
        return NextResponse.json({ success: false, message: 'Internal server error during DELETE', error: error.message }, { status: 500 });
    }
}
EOF

# Check if backend shifts route exists and create if missing
echo "🔧 Checking and creating backend shifts route..."

if [ ! -f "../backend-new/routes/shifts.js" ]; then
    echo "Creating backend shifts route..."
    
    cat > ../backend-new/routes/shifts.js << 'EOF'
const express = require('express');
const { ObjectId } = require('mongodb');
const router = express.Router();

// Get all shifts
router.get('/', async (req, res) => {
    try {
        const db = req.app.locals.db;
        if (!db) {
            return res.status(500).json({ success: false, message: 'Database connection not available' });
        }

        const shifts = await db.collection('shifts').find({}).toArray();
        res.json({ success: true, shifts });
    } catch (error) {
        console.error('Get shifts error:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch shifts', error: error.message });
    }
});

// Get active shifts
router.get('/active', async (req, res) => {
    try {
        const db = req.app.locals.db;
        if (!db) {
            return res.status(500).json({ success: false, message: 'Database connection not available' });
        }

        const activeShifts = await db.collection('shifts').find({ status: 'active' }).toArray();
        res.json({ success: true, shifts: activeShifts });
    } catch (error) {
        console.error('Get active shifts error:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch active shifts', error: error.message });
    }
});

// Create a new shift
router.post('/', async (req, res) => {
    try {
        const { supervisorId, supervisorName, location, startTime } = req.body;
        const db = req.app.locals.db;
        
        if (!db) {
            return res.status(500).json({ success: false, message: 'Database connection not available' });
        }

        const newShift = {
            supervisorId,
            supervisorName,
            location,
            startTime: startTime || new Date(),
            status: 'active',
            createdAt: new Date(),
            updatedAt: new Date()
        };

        const result = await db.collection('shifts').insertOne(newShift);
        res.status(201).json({ success: true, message: 'Shift created successfully', shift: { _id: result.insertedId, ...newShift } });
    } catch (error) {
        console.error('Create shift error:', error);
        res.status(500).json({ success: false, message: 'Failed to create shift', error: error.message });
    }
});

// Update shift status
router.put('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { status, endTime } = req.body;
        const db = req.app.locals.db;
        
        if (!db) {
            return res.status(500).json({ success: false, message: 'Database connection not available' });
        }

        const updateData = { 
            status, 
            updatedAt: new Date() 
        };
        
        if (endTime) {
            updateData.endTime = endTime;
        }

        const result = await db.collection('shifts').updateOne(
            { _id: new ObjectId(id) },
            { $set: updateData }
        );

        if (result.matchedCount === 0) {
            return res.status(404).json({ success: false, message: 'Shift not found' });
        }

        res.json({ success: true, message: 'Shift updated successfully' });
    } catch (error) {
        console.error('Update shift error:', error);
        res.status(500).json({ success: false, message: 'Failed to update shift', error: error.message });
    }
});

// Close shift
router.put('/:id/close', async (req, res) => {
    try {
        const { id } = req.params;
        const db = req.app.locals.db;
        
        if (!db) {
            return res.status(500).json({ success: false, message: 'Database connection not available' });
        }

        const result = await db.collection('shifts').updateOne(
            { _id: new ObjectId(id) },
            { 
                $set: { 
                    status: 'closed', 
                    endTime: new Date(),
                    updatedAt: new Date() 
                } 
            }
        );

        if (result.matchedCount === 0) {
            return res.status(404).json({ success: false, message: 'Shift not found' });
        }

        res.json({ success: true, message: 'Shift closed successfully' });
    } catch (error) {
        console.error('Close shift error:', error);
        res.status(500).json({ success: false, message: 'Failed to close shift', error: error.message });
    }
});

// QR Code scan endpoint
router.post('/scan', async (req, res) => {
    try {
        const { qrData, supervisorId, location } = req.body;
        const db = req.app.locals.db;
        
        if (!db) {
            return res.status(500).json({ success: false, message: 'Database connection not available' });
        }

        if (!qrData) {
            return res.status(400).json({ success: false, message: 'QR data is required' });
        }

        let studentData;
        try {
            studentData = JSON.parse(qrData);
        } catch (e) {
            return res.status(400).json({ success: false, message: 'Invalid QR data format' });
        }

        // Find student by ID or email
        const student = await db.collection('students').findOne({
            $or: [
                { _id: new ObjectId(studentData.id) },
                { studentId: studentData.studentId },
                { email: studentData.email }
            ]
        });

        if (!student) {
            return res.status(404).json({ success: false, message: 'Student not found' });
        }

        // Create attendance record
        const attendanceRecord = {
            studentId: student._id,
            studentEmail: student.email,
            studentName: student.fullName,
            supervisorId,
            location,
            scanTime: new Date(),
            status: 'present',
            qrData: studentData,
            // Include additional student data
            college: student.college,
            major: student.major,
            grade: student.grade,
            phoneNumber: student.phoneNumber,
            address: student.address,
            academicYear: student.academicYear,
            createdAt: new Date()
        };

        // Insert attendance record
        await db.collection('attendance').insertOne(attendanceRecord);

        // Update student attendance count
        await db.collection('students').updateOne(
            { _id: student._id },
            { $inc: { attendanceCount: 1 } }
        );

        res.json({ 
            success: true, 
            message: 'Attendance recorded successfully',
            student: {
                name: student.fullName,
                email: student.email,
                studentId: student.studentId,
                college: student.college,
                major: student.major,
                grade: student.grade
            }
        });

    } catch (error) {
        console.error('QR scan error:', error);
        res.status(500).json({ success: false, message: 'Failed to process QR scan', error: error.message });
    }
});

module.exports = router;
EOF
fi

# Check if shifts route is included in server.js
echo "🔧 Checking if shifts route is included in server.js..."

if ! grep -q "shifts" ../backend-new/server.js; then
    echo "Adding shifts route to server.js..."
    
    # Add the shifts route after the existing routes
    sed -i '/app.use.*routes.*attendance/a app.use("/api/shifts", require("./routes/shifts"));' ../backend-new/server.js
fi

# Build frontend
echo "🔧 Building frontend..."
npm run build

# Start frontend
echo "🚀 Starting frontend..."
pm2 start unitrans-frontend

# Wait for frontend to start
sleep 5

# Test the shifts API
echo "🏥 Testing shifts API..."
curl -s http://localhost:3000/api/shifts | head -20 || echo "Shifts API not responding"

# Final status
echo "📊 Final PM2 status:"
pm2 status

echo ""
echo "✅ Shifts API route fix completed!"
echo "🌍 Test your project at: https://unibus.online/admin/supervisor-dashboard"
echo "📋 The 'Open Shift' button should now work without the 'Route not found' error"
