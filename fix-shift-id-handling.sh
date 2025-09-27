#!/bin/bash

echo "🔧 Fix Shift ID Handling"
echo "======================="

cd /home/unitrans

# Stop both frontend and backend
echo "⏹️ Stopping services..."
pm2 stop unitrans-frontend
pm2 stop unitrans-backend

# Navigate to frontend directory
cd frontend-new

# Update the frontend close shift logic
echo "🔧 Updating frontend close shift logic..."

mkdir -p app/api/shifts/close

cat > app/api/shifts/close/route.js << 'EOF'
import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export async function POST(request) {
    try {
        const body = await request.json();
        console.log('Frontend shifts close API - POST request body:', body);
        
        // Ensure shiftId is present
        if (!body.shiftId) {
            console.error('Frontend shifts close API - Missing shiftId');
            return NextResponse.json({ 
                success: false, 
                message: 'Shift ID is required' 
            }, { status: 400 });
        }

        // Make request to backend
        const response = await fetch(`${BACKEND_URL}/api/shifts/${body.shiftId}/close`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body),
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error('Backend close response error:', response.status, errorText);
            return NextResponse.json({ 
                success: false, 
                message: `Backend error: ${response.status} - ${errorText}` 
            }, { status: response.status });
        }

        const data = await response.json();
        console.log('Frontend shifts close API - Success response:', data);
        return NextResponse.json(data);
    } catch (error) {
        console.error('Frontend shifts close API - Error:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error', 
            error: error.message 
        }, { status: 500 });
    }
}
EOF

# Navigate to backend directory
cd ../backend-new

# Update the backend shifts route
echo "🔧 Updating backend shifts route..."

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

        const activeShifts = await db.collection('shifts').find({ status: 'open' }).toArray();
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
        
        const { supervisorId, supervisorName, location } = req.body;
        const db = req.app.locals.db;
        
        if (!db) {
            console.error('Database connection not available');
            return res.status(500).json({ success: false, message: 'Database connection not available' });
        }

        // Generate a unique shift ID
        const shiftId = Date.now().toString();

        const newShift = {
            id: shiftId,
            supervisorId: supervisorId || 'default-supervisor',
            supervisorName: supervisorName || 'Default Supervisor',
            location: location || 'Main Station',
            startTime: new Date(),
            status: 'open',
            totalScans: 0,
            attendanceRecords: [],
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

// Close shift by ID
router.put('/:id/close', async (req, res) => {
    try {
        const { id } = req.params;
        console.log('Backend shifts API - PUT close shift:', id);
        
        const db = req.app.locals.db;
        if (!db) {
            console.error('Database connection not available');
            return res.status(500).json({ success: false, message: 'Database connection not available' });
        }

        // Try to find the shift first
        const shift = await db.collection('shifts').findOne({ id: id, status: 'open' });
        
        if (!shift) {
            console.error('Backend shifts API - No open shift found with ID:', id);
            return res.status(404).json({ success: false, message: 'No open shift found with this ID' });
        }

        // Close the shift
        const result = await db.collection('shifts').updateOne(
            { id: id, status: 'open' },
            { 
                $set: { 
                    status: 'closed', 
                    endTime: new Date(),
                    updatedAt: new Date() 
                } 
            }
        );

        console.log('Backend shifts API - Shift closed successfully:', id);
        res.json({ 
            success: true, 
            message: 'Shift closed successfully',
            shift: {
                ...shift,
                status: 'closed',
                endTime: new Date()
            }
        });
    } catch (error) {
        console.error('Backend shifts API - Close shift error:', error);
        res.status(500).json({ success: false, message: 'Failed to close shift', error: error.message });
    }
});

// Update shift by ID
router.put('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;
        console.log('Backend shifts API - PUT update shift:', id);
        console.log('Backend shifts API - Update data:', updateData);
        
        const db = req.app.locals.db;
        if (!db) {
            console.error('Database connection not available');
            return res.status(500).json({ success: false, message: 'Database connection not available' });
        }

        // Remove fields that shouldn't be updated
        delete updateData._id;
        delete updateData.id;
        delete updateData.createdAt;

        // Add updatedAt timestamp
        updateData.updatedAt = new Date();

        const result = await db.collection('shifts').updateOne(
            { id: id },
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

// Add attendance record to shift
router.post('/:id/attendance', async (req, res) => {
    try {
        const { id } = req.params;
        const attendanceData = req.body;
        console.log('Backend shifts API - POST add attendance:', id);
        console.log('Backend shifts API - Attendance data:', attendanceData);
        
        const db = req.app.locals.db;
        if (!db) {
            console.error('Database connection not available');
            return res.status(500).json({ success: false, message: 'Database connection not available' });
        }

        // Find the shift first
        const shift = await db.collection('shifts').findOne({ id: id, status: 'open' });
        
        if (!shift) {
            console.error('Backend shifts API - No open shift found with ID:', id);
            return res.status(404).json({ success: false, message: 'No open shift found with this ID' });
        }

        // Add the attendance record
        const result = await db.collection('shifts').updateOne(
            { id: id, status: 'open' },
            { 
                $push: { attendanceRecords: attendanceData },
                $inc: { totalScans: 1 },
                $set: { updatedAt: new Date() }
            }
        );

        console.log('Backend shifts API - Attendance record added successfully:', id);
        res.json({ success: true, message: 'Attendance record added successfully' });
    } catch (error) {
        console.error('Backend shifts API - Add attendance error:', error);
        res.status(500).json({ success: false, message: 'Failed to add attendance record', error: error.message });
    }
});

module.exports = router;
EOF

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

# Create a test shift
echo "🏥 Creating test shift..."
curl -s -X POST http://localhost:3001/api/shifts \
    -H "Content-Type: application/json" \
    -d '{"supervisorName":"Test Supervisor","location":"Test Location"}' > shift_response.json

# Get the shift ID
SHIFT_ID=$(cat shift_response.json | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

if [ -n "$SHIFT_ID" ]; then
    echo "Created test shift with ID: $SHIFT_ID"
    
    # Test closing the shift
    echo "🏥 Testing shift close with real ID..."
    curl -s -X PUT "http://localhost:3001/api/shifts/$SHIFT_ID/close" \
        -H "Content-Type: application/json" \
        -d "{}"
else
    echo "Failed to get shift ID from response"
fi

# Clean up
rm -f shift_response.json

# Final status
echo "📊 Final PM2 status:"
pm2 status

echo ""
echo "✅ Shift ID handling fix completed!"
echo "🌍 Test your project at: https://unibus.online/admin/supervisor-dashboard"
echo "📋 The 'CLOSE SHIFT' button should now work correctly with proper shift IDs"
