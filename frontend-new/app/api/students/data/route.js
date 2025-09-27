import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const email = searchParams.get('email');
    
    if (!email) {
      return NextResponse.json(
        { success: false, message: 'Email parameter is required' },
        { status: 400 }
      );
    }

    // Proxy to backend
    const backendUrl = `http://localhost:3001/api/students/data?email=${encodeURIComponent(email)}`;
    const backendResponse = await fetch(backendUrl);
    const data = await backendResponse.json();
    
    return NextResponse.json(data, { status: backendResponse.status });

  } catch (error) {
    console.error('Get student data proxy error:', error);
    return NextResponse.json(
      { success: false, message: 'Failed to get student data', error: error.message },
      { status: 500 }
    );
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    const { email, studentData } = body;

    if (!email || !studentData) {
      return NextResponse.json(
        { success: false, message: 'Email and student data are required' },
        { status: 400 }
      );
    }

    // Connect to MongoDB
    await connectDB();

    // Create or update student data
    const student = await Student.findOneAndUpdate(
      { email: email.toLowerCase() },
      {
        ...studentData,
        email: email.toLowerCase(),
        updatedAt: new Date()
      },
      { 
        upsert: true, 
        new: true,
        setDefaultsOnInsert: true
      }
    );

    return NextResponse.json({
      success: true,
      message: 'Student data saved successfully',
      student
    });

  } catch (error) {
    console.error('Save student data error:', error);
    return NextResponse.json(
      { success: false, message: 'Failed to save student data', error: error.message },
      { status: 500 }
    );
  }
}

export async function PUT(request) {
  try {
    const body = await request.json();
    const { email, studentData } = body;

    if (!email || !studentData) {
      return NextResponse.json(
        { success: false, message: 'Email and student data are required' },
        { status: 400 }
      );
    }

    // Connect to MongoDB
    await connectDB();

    // Update existing student data
    const student = await Student.findOneAndUpdate(
      { email: email.toLowerCase() },
      {
        ...studentData,
        email: email.toLowerCase(),
        updatedAt: new Date()
      },
      { new: true }
    );

    if (!student) {
      return NextResponse.json(
        { success: false, message: 'Student not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({
      success: true,
      message: 'Student data updated successfully',
      student
    });

  } catch (error) {
    console.error('Update student data error:', error);
    return NextResponse.json(
      { success: false, message: 'Failed to update student data', error: error.message },
      { status: 500 }
    );
  }
}
