import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    
    // Forward to backend with HTTPS
    const backendUrl = 'https://unibus.online:3001';
    const response = await fetch(`${backendUrl}/api/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();
    
    return NextResponse.json(data, {
      status: response.status
    });

  } catch (error) {
    console.error('Register proxy error:', error);
    return NextResponse.json({
      success: false,
      message: 'Connection error'
    }, { status: 500 });
  }
}