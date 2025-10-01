import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    const { email, studentData } = body;
    
    // Extract email
    const studentEmail = email || studentData?.email;
    
    console.log('[Generate QR] Request:', { email: studentEmail, hasStudentData: !!studentData });
    
    if (!studentEmail && !studentData) {
      return NextResponse.json(
        { success: false, message: 'Email or studentData is required' },
        { status: 400 }
      );
    }
    
    // Prepare request body for backend
    const requestBody = {};
    
    if (studentEmail) {
      requestBody.email = studentEmail;
    }
    
    if (studentData) {
      requestBody.studentData = studentData;
    }
    
    console.log('[Generate QR] Sending to backend:', requestBody);
    
    // Send to backend
    const backendUrl = 'http://localhost:3001';
    const response = await fetch(`${backendUrl}/api/students/generate-qr`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(requestBody)
    });
    
    const data = await response.json();
    
    if (data.success) {
      console.log('[Generate QR] Success!');
    } else {
      console.log('[Generate QR] Backend error:', data.message);
    }
    
    return NextResponse.json(data);
    
  } catch (error) {
    console.error('[Generate QR] Error:', error);
    return NextResponse.json(
      { success: false, message: 'Failed to generate QR code', error: error.message },
      { status: 500 }
    );
  }
}
