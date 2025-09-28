import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    console.log('🔄 Login Proxy: Request received');
    const body = await request.json();
    console.log('📥 Request data:', { email: body.email, hasPassword: !!body.password });
    
    // Forward to backend on same machine
    const backendUrl = 'http://localhost:3001/api/auth-pro/login';
    
    const response = await fetch(backendUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();
    console.log('📤 Backend response:', data);
    
    return NextResponse.json(data, {
      status: response.status,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      }
    });

  } catch (error) {
    console.error('❌ Login Proxy Error:', error);
    return NextResponse.json({
      success: false,
      message: 'خطأ في الاتصال بالخادم'
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
