import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    const authHeader = request.headers.get('authorization');
    
    const backendUrl = process.env.BACKEND_URL || 'http://localhost:3001';
    
    const backendResponse = await fetch(`${backendUrl}/api/shifts/scan`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(authHeader && { 'Authorization': authHeader }),
      },
      body: JSON.stringify(body),
    });
    
    const data = await backendResponse.json();
    return NextResponse.json(data, { status: backendResponse.status });
    
  } catch (error) {
    console.error('❌ Shifts scan proxy error:', error);
    return NextResponse.json(
      { success: false, message: 'Failed to process scan', error: error.message },
      { status: 500 }
    );
  }
}
