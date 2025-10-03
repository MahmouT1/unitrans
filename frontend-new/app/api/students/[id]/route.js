import { NextResponse } from 'next/server';

export async function DELETE(request, { params }) {
  try {
    const { id } = params;
    
    if (!id || id === 'undefined') {
      return NextResponse.json(
        { success: false, message: 'Invalid student ID' },
        { status: 400 }
      );
    }
    
    const backendUrl = 'http://localhost:3001';
    
    // Forward DELETE request to backend
    const response = await fetch(`${backendUrl}/api/students/${id}`, {
      method: 'DELETE'
    });
    
    const data = await response.json();
    return NextResponse.json(data);
    
  } catch (error) {
    console.error('Error deleting student:', error);
    return NextResponse.json(
      { success: false, message: error.message },
      { status: 500 }
    );
  }
}
