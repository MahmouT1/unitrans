import { NextResponse } from 'next/server';

export async function DELETE(request, { params }) {
  try {
    const { id } = params;
    const backendUrl = 'http://localhost:3001';
    
    // Forward DELETE request to backend
    const response = await fetch(`${backendUrl}/api/subscriptions/${id}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    const data = await response.json();
    return NextResponse.json(data);
    
  } catch (error) {
    console.error('Error deleting subscription:', error);
    return NextResponse.json(
      { success: false, message: 'Failed to delete subscription', error: error.message },
      { status: 500 }
    );
  }
}
