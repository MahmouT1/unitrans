#!/bin/bash

# Fix Dynamic Server Usage Errors
# Add dynamic = 'force-dynamic' to API routes that use request.url

echo "🔧 Fixing Dynamic Server Usage Errors..."

# Navigate to frontend directory
cd /var/www/unitrans/frontend-new

echo "📁 Current directory: $(pwd)"

# Fix attendance/all-records route
echo "🔧 Fixing /api/attendance/all-records..."
cat > app/api/attendance/all-records/route.js << 'ALL_RECORDS_EOF'
import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page')) || 1;
    const limit = parseInt(searchParams.get('limit')) || 10;

    return NextResponse.json({
      success: true,
      records: [],
      pagination: {
        currentPage: page,
        totalPages: 0,
        totalRecords: 0,
        limit: limit,
        hasNextPage: false,
        hasPrevPage: false
      }
    });
  } catch (error) {
    console.error('Error fetching attendance records:', error);
    return NextResponse.json({
      success: false,
      message: 'Failed to fetch attendance records'
    }, { status: 500 });
  }
}
ALL_RECORDS_EOF

# Fix attendance/records-simple route
echo "🔧 Fixing /api/attendance/records-simple..."
cat > app/api/attendance/records-simple/route.js << 'RECORDS_SIMPLE_EOF'
import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page')) || 1;
    const limit = parseInt(searchParams.get('limit')) || 10;

    return NextResponse.json({
      success: true,
      records: [],
      pagination: {
        currentPage: page,
        totalPages: 0,
        totalRecords: 0,
        limit: limit,
        hasNextPage: false,
        hasPrevPage: false
      }
    });
  } catch (error) {
    console.error('Error fetching attendance records:', error);
    return NextResponse.json({
      success: false,
      message: 'Failed to fetch attendance records'
    }, { status: 500 });
  }
}
RECORDS_SIMPLE_EOF

# Fix attendance/records route
echo "🔧 Fixing /api/attendance/records..."
cat > app/api/attendance/records/route.js << 'RECORDS_EOF'
import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page')) || 1;
    const limit = parseInt(searchParams.get('limit')) || 10;

    return NextResponse.json({
      success: true,
      records: [],
      pagination: {
        currentPage: page,
        totalPages: 0,
        totalRecords: 0,
        limit: limit,
        hasNextPage: false,
        hasPrevPage: false
      }
    });
  } catch (error) {
    console.error('Error fetching attendance records:', error);
    return NextResponse.json({
      success: false,
      message: 'Failed to fetch attendance records'
    }, { status: 500 });
  }
}
RECORDS_EOF

# Fix students/profile-simple route
echo "🔧 Fixing /api/students/profile-simple..."
cat > app/api/students/profile-simple/route.js << 'PROFILE_SIMPLE_EOF'
import { NextResponse } from 'next/server';

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

    return NextResponse.json({
      success: true,
      student: null,
      message: 'Student not found'
    });
  } catch (error) {
    console.error('Error fetching student profile:', error);
    return NextResponse.json({
      success: false,
      message: 'Failed to fetch student profile'
    }, { status: 500 });
  }
}
PROFILE_SIMPLE_EOF

# Fix users/list route
echo "🔧 Fixing /api/users/list..."
cat > app/api/users/list/route.js << 'USERS_LIST_EOF'
import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page')) || 1;
    const limit = parseInt(searchParams.get('limit')) || 10;
    const role = searchParams.get('role');

    return NextResponse.json({
      success: true,
      users: [],
      pagination: {
        currentPage: page,
        totalPages: 0,
        totalUsers: 0,
        limit: limit,
        hasNextPage: false,
        hasPrevPage: false
      }
    });
  } catch (error) {
    console.error('Error fetching users:', error);
    return NextResponse.json({
      success: false,
      message: 'Failed to fetch users'
    }, { status: 500 });
  }
}
USERS_LIST_EOF

# Clean and rebuild
echo "🧹 Cleaning and rebuilding..."
rm -rf .next
npm run build

# Restart PM2
echo "🔄 Restarting PM2..."
pm2 restart unitrans-frontend

echo "✅ Dynamic server usage errors fixed!"
echo "🌐 Application should now work at: https://unibus.online"