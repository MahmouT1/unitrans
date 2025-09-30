import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = searchParams.get('page') || '1';
    const limit = searchParams.get('limit') || '20';
    const search = searchParams.get('search') || '';
    
    // Build backend URL with query parameters
    const backendUrl = process.env.BACKEND_URL || 'http://localhost:3001';
    const params = new URLSearchParams({
      page,
      limit,
      ...(search && { search })
    });
    
    console.log(`📡 Proxying request to backend: ${backendUrl}/api/students/all?${params}`);
    
    // Proxy request to backend
    const backendResponse = await fetch(`${backendUrl}/api/students/all?${params}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    const data = await backendResponse.json();
    
    if (!backendResponse.ok) {
      console.error('❌ Backend error:', data);
      return NextResponse.json(data, { status: backendResponse.status });
    }
    
    console.log(`✅ Successfully fetched ${data.students?.length || 0} students`);
    
    return NextResponse.json(data, { status: 200 });
    
  } catch (error) {
    console.error('❌ Error fetching students:', error);
    return NextResponse.json(
      { 
        success: false, 
        message: 'Failed to fetch students', 
        error: error.message 
      },
      { status: 500 }
    );
  }
}
