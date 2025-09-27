#!/bin/bash

echo "🔧 Fix Shifts Route Complete"
echo "============================"

cd /home/unitrans

# Stop both frontend and backend
echo "⏹️ Stopping services..."
pm2 stop unitrans-frontend
pm2 stop unitrans-backend

# Navigate to frontend directory
cd frontend-new

# Create the shifts API route in frontend
echo "🔧 Creating shifts API route in frontend..."

mkdir -p app/api/shifts

cat > app/api/shifts/route.js << 'EOF'
import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export async function GET(request) {
    try {
        const { searchParams } = new URL(request.url);
        const queryString = searchParams.toString();
        const url = queryString ? `${BACKEND_URL}/api/shifts?${queryString}` : `${BACKEND_URL}/api/shifts`;
        
        console.log('Frontend shifts API - GET request to:', url);
        
        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error('Backend response error:', response.status, errorText);
            return NextResponse.json({ 
                success: false, 
                message: `Backend error: ${response.status} - ${errorText}` 
            }, { status: response.status });
        }

        const data = await response.json();
        console.log('Frontend shifts API - Success response:', data);
        return NextResponse.json(data);
    } catch (error) {
        console.error('Frontend shifts API - GET error:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error during GET', 
            error: error.message 
        }, { status: 500 });
    }
}

export async function POST(request) {
    try {
        const body = await request.json();
        console.log('Frontend shifts API - POST request to:', `${BACKEND_URL}/api/shifts`);
        console.log('Frontend shifts API - POST body:', body);
        
        const response = await fetch(`${BACKEND_URL}/api/shifts`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body),
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error('Backend POST response error:', response.status, errorText);
            return NextResponse.json({ 
                success: false, 
                message: `Backend error: ${response.status} - ${errorText}` 
            }, { status: response.status });
        }

        const data = await response.json();
        console.log('Frontend shifts API - POST success:', data);
        return NextResponse.json(data);
    } catch (error) {
        console.error('Frontend shifts API - POST error:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error during POST', 
            error: error.message 
        }, { status: 500 });
    }
}

export async function PUT(request) {
    try {
        const body = await request.json();
        console.log('Frontend shifts API - PUT request to:', `${BACKEND_URL}/api/shifts`);
        console.log('Frontend shifts API - PUT body:', body);
        
        const response = await fetch(`${BACKEND_URL}/api/shifts`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body),
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error('Backend PUT response error:', response.status, errorText);
            return NextResponse.json({ 
                success: false, 
                message: `Backend error: ${response.status} - ${errorText}` 
            }, { status: response.status });
        }

        const data = await response.json();
        console.log('Frontend shifts API - PUT success:', data);
        return NextResponse.json(data);
    } catch (error) {
        console.error('Frontend shifts API - PUT error:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error during PUT', 
            error: error.message 
        }, { status: 500 });
    }
}
EOF

# Create the [id] route
mkdir -p app/api/shifts/\[id\]

cat > app/api/shifts/\[id\]/route.js << 'EOF'
import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export async function GET(request, { params }) {
    try {
        const { id } = params;
        const url = `${BACKEND_URL}/api/shifts/${id}`;
        console.log('Frontend shifts API - GET [id] request to:', url);
        
        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error('Backend GET [id] response error:', response.status, errorText);
            return NextResponse.json({ 
                success: false, 
                message: `Backend error: ${response.status} - ${errorText}` 
            }, { status: response.status });
        }

        const data = await response.json();
        console.log('Frontend shifts API - GET [id] success:', data);
        return NextResponse.json(data);
    } catch (error) {
        console.error('Frontend shifts API - GET [id] error:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error during GET', 
            error: error.message 
        }, { status: 500 });
    }
}

export async function PUT(request, { params }) {
    try {
        const { id } = params;
        const body = await request.json();
        const url = `${BACKEND_URL}/api/shifts/${id}`;
        console.log('Frontend shifts API - PUT [id] request to:', url);
        console.log('Frontend shifts API - PUT [id] body:', body);
        
        const response = await fetch(url, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body),
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error('Backend PUT [id] response error:', response.status, errorText);
            return NextResponse.json({ 
                success: false, 
                message: `Backend error: ${response.status} - ${errorText}` 
            }, { status: response.status });
        }

        const data = await response.json();
        console.log('Frontend shifts API - PUT [id] success:', data);
        return NextResponse.json(data);
    } catch (error) {
        console.error('Frontend shifts API - PUT [id] error:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error during PUT', 
            error: error.message 
        }, { status: 500 });
    }
}

export async function DELETE(request, { params }) {
    try {
        const { id } = params;
        const url = `${BACKEND_URL}/api/shifts/${id}`;
        console.log('Frontend shifts API - DELETE [id] request to:', url);
        
        const response = await fetch(url, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error('Backend DELETE [id] response error:', response.status, errorText);
            return NextResponse.json({ 
                success: false, 
                message: `Backend error: ${response.status} - ${errorText}` 
            }, { status: response.status });
        }

        const data = await response.json();
        console.log('Frontend shifts API - DELETE [id] success:', data);
        return NextResponse.json(data);
    } catch (error) {
        console.error('Frontend shifts API - DELETE [id] error:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error during DELETE', 
            error: error.message 
        }, { status: 500 });
    }
}
EOF

# Navigate to backend directory
cd ../backend-new

# Create the shifts route in backend
echo "🔧 Creating shifts route in backend..."

cat > routes/shifts.js << 'EOF'
const express = require('express');
const { ObjectId } = require('mongodb');
const router = express.Router();

// Get all shifts
router.get('/', async (req, res) => {
    try {
        console.log('Backend shifts API - GET all shifts');
        const db = req.app.locals.db;
        if (!db) {
            console.error('Database connection not available');
            return res.status(500).json({ success: false, message: 'Database connection not available' });
        }

        const shifts = await db.collection('shifts').find({}).toArray();
        console.log('Backend shifts API - Found shifts:', shifts.length);
        res.json({ success: true, shifts });
    } catch (error) {
        console.error('Backend shifts API - Get shifts error:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch shifts', error: error.message });
    }
});

// Get active shifts
router.get('/active', async (req, res) => {
    try {
        console.log('Backend shifts API - GET active shifts');
        const db = req.app.locals.db;
        if (!db) {
            console.error('Database connection not available');
            return res.status(500).json({ success: false, message: 'Database connection not available' });
        }

        const activeShifts = await db.collection('shifts').find({ status: 'active' }).toArray();
        console.log('Backend shifts API - Found active shifts:', activeShifts.length);
        res.json({ success: true, shifts: activeShifts });
    } catch (error) {
        console.error('Backend shifts API - Get active shifts error:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch active shifts', error: error.message });
    }
});

// Create a new shift
router.post('/', async (req, res) => {
    try {
        console.log('Backend shifts API - POST create shift');
        console.log('Backend shifts API - Request body:', req.body);
        
        const { supervisorId, supervisorName, location, startTime } = req.body;
        const db = req.app.locals.db;
        
        if (!db) {
            console.error('Database connection not available');
            return res.status(500).json({ success: false, message: 'Database connection not available' });
        }

        const newShift = {
            supervisorId: supervisorId || 'default-supervisor',
            supervisorName: supervisorName || 'Default Supervisor',
            location: location || 'Main Station',
            startTime: startTime || new Date(),
            status: 'active',
            createdAt: new Date(),
            updatedAt: new Date()
        };

        console.log('Backend shifts API - Creating shift:', newShift);
        const result = await db.collection('shifts').insertOne(newShift);
        console.log('Backend shifts API - Shift created with ID:', result.insertedId);
        
        res.status(201).json({ 
            success: true, 
            message: 'Shift created successfully', 
            shift: { _id: result.insertedId, ...newShift } 
        });
    } catch (error) {
        console.error('Backend shifts API - Create shift error:', error);
        res.status(500).json({ success: false, message: 'Failed to create shift', error: error.message });
    }
});

// Update shift status
router.put('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { status, endTime } = req.body;
        console.log('Backend shifts API - PUT update shift:', id, { status, endTime });
        
        const db = req.app.locals.db;
        
        if (!db) {
            console.error('Database connection not available');
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
            console.error('Backend shifts API - Shift not found:', id);
            return res.status(404).json({ success: false, message: 'Shift not found' });
        }

        console.log('Backend shifts API - Shift updated successfully:', id);
        res.json({ success: true, message: 'Shift updated successfully' });
    } catch (error) {
        console.error('Backend shifts API - Update shift error:', error);
        res.status(500).json({ success: false, message: 'Failed to update shift', error: error.message });
    }
});

// Close shift
router.put('/:id/close', async (req, res) => {
    try {
        const { id } = req.params;
        console.log('Backend shifts API - PUT close shift:', id);
        
        const db = req.app.locals.db;
        
        if (!db) {
            console.error('Database connection not available');
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
            console.error('Backend shifts API - Shift not found for closing:', id);
            return res.status(404).json({ success: false, message: 'Shift not found' });
        }

        console.log('Backend shifts API - Shift closed successfully:', id);
        res.json({ success: true, message: 'Shift closed successfully' });
    } catch (error) {
        console.error('Backend shifts API - Close shift error:', error);
        res.status(500).json({ success: false, message: 'Failed to close shift', error: error.message });
    }
});

// QR Code scan endpoint
router.post('/scan', async (req, res) => {
    try {
        console.log('Backend shifts API - POST scan QR');
        console.log('Backend shifts API - Scan request body:', req.body);
        
        const { qrData, supervisorId, location } = req.body;
        const db = req.app.locals.db;
        
        if (!db) {
            console.error('Database connection not available');
            return res.status(500).json({ success: false, message: 'Database connection not available' });
        }

        if (!qrData) {
            console.error('QR data is required');
            return res.status(400).json({ success: false, message: 'QR data is required' });
        }

        let studentData;
        try {
            studentData = JSON.parse(qrData);
            console.log('Backend shifts API - Parsed QR data:', studentData);
        } catch (e) {
            console.error('Invalid QR data format:', e);
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
            console.error('Student not found for QR data:', studentData);
            return res.status(404).json({ success: false, message: 'Student not found' });
        }

        console.log('Backend shifts API - Found student:', student.fullName);

        // Create attendance record
        const attendanceRecord = {
            studentId: student._id,
            studentEmail: student.email,
            studentName: student.fullName,
            supervisorId: supervisorId || 'default-supervisor',
            location: location || 'Main Station',
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

        console.log('Backend shifts API - Creating attendance record:', attendanceRecord);

        // Insert attendance record
        await db.collection('attendance').insertOne(attendanceRecord);

        // Update student attendance count
        await db.collection('students').updateOne(
            { _id: student._id },
            { $inc: { attendanceCount: 1 } }
        );

        console.log('Backend shifts API - Attendance recorded successfully for:', student.fullName);

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
        console.error('Backend shifts API - QR scan error:', error);
        res.status(500).json({ success: false, message: 'Failed to process QR scan', error: error.message });
    }
});

module.exports = router;
EOF

# Check if shifts route is included in server.js
echo "🔧 Checking if shifts route is included in server.js..."

if ! grep -q "shifts" server.js; then
    echo "Adding shifts route to server.js..."
    
    # Add the shifts route after the existing routes
    sed -i '/app.use.*routes.*attendance/a app.use("/api/shifts", require("./routes/shifts"));' server.js
    echo "✅ Shifts route added to server.js"
else
    echo "✅ Shifts route already exists in server.js"
fi

# Build frontend
echo "🔧 Building frontend..."
cd ../frontend-new
npm run build

# Start backend first
echo "🚀 Starting backend..."
cd ../backend-new
pm2 start unitrans-backend

# Wait for backend to start
sleep 3

# Start frontend
echo "🚀 Starting frontend..."
cd ../frontend-new
pm2 start unitrans-frontend

# Wait for frontend to start
sleep 5

# Test the shifts API
echo "🏥 Testing shifts API..."
curl -s http://localhost:3000/api/shifts | head -20 || echo "Shifts API not responding"

# Test backend directly
echo "🏥 Testing backend shifts API directly..."
curl -s http://localhost:3001/api/shifts | head -20 || echo "Backend shifts API not responding"

# Final status
echo "📊 Final PM2 status:"
pm2 status

echo ""
echo "✅ Shifts route fix completed!"
echo "🌍 Test your project at: https://unibus.online/admin/supervisor-dashboard"
echo "📋 The 'Open Shift' button should now work without the 'Route not found' error"
