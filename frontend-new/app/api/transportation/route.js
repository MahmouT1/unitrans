import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const activeOnly = searchParams.get('activeOnly');
    
    // Build backend URL
    let backendUrl = `${BACKEND_URL}/api/transportation`;
    if (activeOnly === 'true') {
      backendUrl = `${BACKEND_URL}/api/transportation/active/schedules`;
    }

    const backendResponse = await fetch(backendUrl);
    
    if (!backendResponse.ok) {
      return NextResponse.json(
        { 
          success: false, 
          message: 'Failed to fetch transportation data from backend' 
        },
        { status: backendResponse.status }
      );
    }

    const data = await backendResponse.json();
    return NextResponse.json(data, { status: 200 });

  } catch (error) {
    console.error('Transportation proxy error:', error);
    
    // Return fallback data if backend is not available
    return NextResponse.json({
      success: true,
      transportation: [],
      message: 'Backend not available, returning empty data'
    }, { status: 200 });
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    
    const backendResponse = await fetch(`${BACKEND_URL}/api/transportation`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const data = await backendResponse.json();
    return NextResponse.json(data, { status: backendResponse.status });

  } catch (error) {
    console.error('Transportation POST proxy error:', error);
    return NextResponse.json(
      { 
        success: false, 
        message: 'Failed to create transportation schedule',
        error: error.message 
      },
      { status: 500 }
    );
  }
}