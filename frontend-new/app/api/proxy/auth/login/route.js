import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    console.log('🔄 Proxy: Login request received');
    const body = await request.json();
    console.log('📥 Proxy: Request body:', body);
    
    // Forward to backend server (localhost since we're on the same machine)
    const backendUrl = 'http://localhost:3001';
    const targetUrl = `${backendUrl}/api/auth/login`;
    
    console.log('🎯 Proxy: Forwarding to:', targetUrl);
    
    const response = await fetch(targetUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();
    console.log('📤 Proxy: Backend response:', data);
    
    return NextResponse.json(data, {
      status: response.status,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      }
    });

  } catch (error) {
    console.error('❌ Proxy: Login error:', error);
    return NextResponse.json({
      success: false,
      message: 'Proxy connection error'
    }, { status: 500 });
  }
}

export async function OPTIONS(request) {
  return new NextResponse(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}