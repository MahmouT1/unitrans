import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export async function GET(request, { params }) {
  try {
    const { id } = params;
    
    const backendResponse = await fetch(`${BACKEND_URL}/api/transportation/${id}`);
    
    if (!backendResponse.ok) {
      return NextResponse.json(
        { 
          success: false, 
          message: 'Failed to fetch transportation schedule from backend' 
        },
        { status: backendResponse.status }
      );
    }

    const data = await backendResponse.json();
    return NextResponse.json(data, { status: 200 });

  } catch (error) {
    console.error('Transportation GET by ID proxy error:', error);
    return NextResponse.json(
      { 
        success: false, 
        message: 'Failed to fetch transportation schedule',
        error: error.message 
      },
      { status: 500 }
    );
  }
}

export async function PUT(request, { params }) {
  try {
    const { id } = params;
    const body = await request.json();
    
    const backendResponse = await fetch(`${BACKEND_URL}/api/transportation/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const data = await backendResponse.json();
    return NextResponse.json(data, { status: backendResponse.status });

  } catch (error) {
    console.error('Transportation PUT proxy error:', error);
    return NextResponse.json(
      { 
        success: false, 
        message: 'Failed to update transportation schedule',
        error: error.message 
      },
      { status: 500 }
    );
  }
}

export async function DELETE(request, { params }) {
  try {
    const { id } = params;
    
    const backendResponse = await fetch(`${BACKEND_URL}/api/transportation/${id}`, {
      method: 'DELETE',
    });

    const data = await backendResponse.json();
    return NextResponse.json(data, { status: backendResponse.status });

  } catch (error) {
    console.error('Transportation DELETE proxy error:', error);
    return NextResponse.json(
      { 
        success: false, 
        message: 'Failed to delete transportation schedule',
        error: error.message 
      },
      { status: 500 }
    );
  }
}