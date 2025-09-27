#!/bin/bash

echo "🔧 Fix Dynamic Routes"
echo "===================="

cd /home/unitrans

# Stop frontend
echo "⏹️ Stopping frontend..."
pm2 stop unitrans-frontend

# Navigate to frontend directory
cd frontend-new

# Fix attendance routes
echo "🔧 Fixing attendance routes..."

cat > app/api/attendance/all-records/route.js << 'EOF'
import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export const dynamic = 'force-dynamic';

export async function GET() {
    try {
        const response = await fetch(`${BACKEND_URL}/api/attendance/all-records`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (!response.ok) {
            return NextResponse.json({ 
                success: false, 
                message: 'Failed to fetch attendance records' 
            }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);
    } catch (error) {
        console.error('Error fetching attendance records:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error', 
            error: error.message 
        }, { status: 500 });
    }
}
EOF

cat > app/api/attendance/records-simple/route.js << 'EOF'
import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export const dynamic = 'force-dynamic';

export async function GET() {
    try {
        const response = await fetch(`${BACKEND_URL}/api/attendance/records-simple`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (!response.ok) {
            return NextResponse.json({ 
                success: false, 
                message: 'Failed to fetch attendance records' 
            }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);
    } catch (error) {
        console.error('Error fetching attendance records:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error', 
            error: error.message 
        }, { status: 500 });
    }
}
EOF

cat > app/api/attendance/records/route.js << 'EOF'
import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export const dynamic = 'force-dynamic';

export async function GET() {
    try {
        const response = await fetch(`${BACKEND_URL}/api/attendance/records`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (!response.ok) {
            return NextResponse.json({ 
                success: false, 
                message: 'Failed to fetch attendance records' 
            }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);
    } catch (error) {
        console.error('Error fetching attendance records:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error', 
            error: error.message 
        }, { status: 500 });
    }
}
EOF

# Fix student routes
echo "🔧 Fixing student routes..."

cat > app/api/students/profile-simple/route.js << 'EOF'
import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export const dynamic = 'force-dynamic';

export async function GET(request) {
    try {
        const { searchParams } = new URL(request.url);
        const email = searchParams.get('email');

        if (!email) {
            return NextResponse.json({ 
                success: false, 
                message: 'Email parameter is required' 
            }, { status: 400 });
        }

        const response = await fetch(`${BACKEND_URL}/api/students/data?email=${encodeURIComponent(email)}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (!response.ok) {
            return NextResponse.json({ 
                success: false, 
                message: 'Failed to fetch student profile' 
            }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);
    } catch (error) {
        console.error('Error fetching student profile:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error', 
            error: error.message 
        }, { status: 500 });
    }
}
EOF

# Fix user routes
echo "🔧 Fixing user routes..."

cat > app/api/users/list/route.js << 'EOF'
import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export const dynamic = 'force-dynamic';

export async function GET() {
    try {
        const response = await fetch(`${BACKEND_URL}/api/users/list`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (!response.ok) {
            return NextResponse.json({ 
                success: false, 
                message: 'Failed to fetch users' 
            }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json(data);
    } catch (error) {
        console.error('Error fetching users:', error);
        return NextResponse.json({ 
            success: false, 
            message: 'Internal server error', 
            error: error.message 
        }, { status: 500 });
    }
}
EOF

# Update next.config.js to handle dynamic routes
echo "🔧 Updating Next.js configuration..."

cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
    async headers() {
        return [
            {
                source: '/api/:path*',
                headers: [
                    { key: 'Access-Control-Allow-Credentials', value: 'true' },
                    { key: 'Access-Control-Allow-Origin', value: '*' },
                    { key: 'Access-Control-Allow-Methods', value: 'GET,DELETE,PATCH,POST,PUT' },
                    { key: 'Access-Control-Allow-Headers', value: 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version' },
                ]
            }
        ]
    },
    experimental: {
        serverActions: true
    }
}

module.exports = nextConfig
EOF

# Build frontend
echo "🔧 Building frontend..."
npm run build

# Start frontend
echo "🚀 Starting frontend..."
pm2 start unitrans-frontend

# Wait for frontend to start
sleep 5

# Final status
echo "📊 Final PM2 status:"
pm2 status

echo ""
echo "✅ Dynamic routes fix completed!"
echo "🌍 Test your project at: https://unibus.online/admin/supervisor-dashboard"
echo "📋 All dynamic routes should now work correctly"
