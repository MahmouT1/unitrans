import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    const backendUrl = 'http://localhost:3001';
    
    // Forward request to backend
    const response = await fetch(`${backendUrl}/api/subscriptions`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    const data = await response.json();
    return NextResponse.json(data);
    
  } catch (error) {
    console.error('Error fetching subscriptions:', error);
    return NextResponse.json(
      { success: false, message: 'Failed to fetch subscriptions', error: error.message },
      { status: 500 }
    );
  }
}

export async function POST(request) {
  try {
    const backendUrl = 'http://localhost:3001';
    const body = await request.json();
    
    // Forward request to backend
    const response = await fetch(`${backendUrl}/api/subscriptions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body)
    });
    
    const data = await response.json();
    return NextResponse.json(data);
    
  } catch (error) {
    console.error('Error creating subscription:', error);
    return NextResponse.json(
      { success: false, message: 'Failed to create subscription', error: error.message },
      { status: 500 }
    );
  }
}
