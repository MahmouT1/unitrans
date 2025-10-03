import { NextResponse } from 'next/server';

export async function DELETE(request, { params }) {
  try {
    const { id } = params;
    const backendUrl = 'http://localhost:3001';
    
    const response = await fetch(`${backendUrl}/api/driver-salaries/${id}`, {
      method: 'DELETE'
    });
    
    const data = await response.json();
    return NextResponse.json(data);
    
  } catch (error) {
    return NextResponse.json(
      { success: false, message: error.message },
      { status: 500 }
    );
  }
}
