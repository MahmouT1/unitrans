#!/bin/bash

echo "🔧 Fix Shifts Close Route"
echo "========================="

cd /home/unitrans

# Stop frontend
echo "⏹️ Stopping frontend..."
pm2 stop unitrans-frontend

# Navigate to frontend directory
cd frontend-new

# Create the shifts close API route in frontend
echo "🔧 Creating shifts close API route in frontend..."

mkdir -p app/api/shifts/close

cat > app/api/shifts/close/route.js << 'EOF'
import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export async function POST(request) {
    try {
        const body = await request.json();
        console.log('Frontend shifts close API - POST request to:', `${BACKEND_URL}/api/shifts/close`);
        console.log('Frontend shifts close API - POST body:', body);
        
        const response = await fetch(`${BACKEND_URL}/api/shifts/close`, {
            method: 'POST',
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
        console.log('Frontend shifts close API - POST success:', data);
        return NextResponse.json(data);
    } catch (error) {
        console.error('Frontend shifts close API - POST error:', error);
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
        console.log('Frontend shifts close API - PUT request to:', `${BACKEND_URL}/api/shifts/close`);
        console.log('Frontend shifts close API - PUT body:', body);
        
        const response = await fetch(`${BACKEND_URL}/api/shifts/close`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body),
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error('Backend close PUT response error:', response.status, errorText);
            return NextResponse.json({ 
                success: false, 
                message: `Backend error: ${response.status} - ${errorText}` 
            }, { status: response.status });
        }

        const data = await response.json();
        console.log('Frontend shifts close API - PUT success:', data);
        return NextResponse.json(data);
    } catch (error) {
        console.error('Frontend shifts close API - PUT error:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error during PUT', 
            error: error.message 
        }, { status: 500 });
    }
}
EOF

# Navigate to backend directory
cd ../backend-new

# Add the close route to the existing shifts.js
echo "🔧 Adding close route to backend shifts.js..."

# Check if close route already exists
if ! grep -q "router.post('/close'" routes/shifts.js; then
    echo "Adding close route to shifts.js..."
    
    # Add the close route before the module.exports
    sed -i '/module.exports = router;/i\
// Close shift endpoint\
router.post("/close", async (req, res) => {\
    try {\
        console.log("Backend shifts API - POST close shift");\
        console.log("Backend shifts API - Close request body:", req.body);\
        \
        const { shiftId } = req.body;\
        const db = req.app.locals.db;\
        \
        if (!db) {\
            console.error("Database connection not available");\
            return res.status(500).json({ success: false, message: "Database connection not available" });\
        }\
\
        if (!shiftId) {\
            console.error("Shift ID is required");\
            return res.status(400).json({ success: false, message: "Shift ID is required" });\
        }\
\
        // Find and close the shift\
        const result = await db.collection("shifts").updateOne(\
            { id: shiftId, status: "open" },\
            { \
                $set: { \
                    status: "closed", \
                    endTime: new Date(),\
                    updatedAt: new Date() \
                } \
            }\
        );\
\
        if (result.matchedCount === 0) {\
            console.error("Backend shifts API - No open shift found with ID:", shiftId);\
            return res.status(404).json({ success: false, message: "No open shift found with this ID" });\
        }\
\
        console.log("Backend shifts API - Shift closed successfully:", shiftId);\
        res.json({ success: true, message: "Shift closed successfully" });\
    } catch (error) {\
        console.error("Backend shifts API - Close shift error:", error);\
        res.status(500).json({ success: false, message: "Failed to close shift", error: error.message });\
    }\
});\
' routes/shifts.js
else
    echo "✅ Close route already exists in shifts.js"
fi

# Build frontend
echo "🔧 Building frontend..."
cd ../frontend-new
npm run build

# Start frontend
echo "🚀 Starting frontend..."
pm2 start unitrans-frontend

# Wait for frontend to start
sleep 5

# Test the shifts close API
echo "🏥 Testing shifts close API..."
curl -s -X POST http://localhost:3000/api/shifts/close -H "Content-Type: application/json" -d '{"shiftId":"test"}' | head -20 || echo "Shifts close API not responding"

# Test backend directly
echo "🏥 Testing backend shifts close API directly..."
curl -s -X POST http://localhost:3001/api/shifts/close -H "Content-Type: application/json" -d '{"shiftId":"test"}' | head -20 || echo "Backend shifts close API not responding"

# Final status
echo "📊 Final PM2 status:"
pm2 status

echo ""
echo "✅ Shifts close route fix completed!"
echo "🌍 Test your project at: https://unibus.online/admin/supervisor-dashboard"
echo "📋 The 'CLOSE SHIFT' button should now work without the 'Route not found' error"
