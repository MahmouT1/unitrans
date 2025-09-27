import { NextResponse } from 'next/server';
import QRCode from 'qrcode';
import { writeFile, mkdir } from 'fs/promises';
import { join } from 'path';

export async function POST(request) {
  try {
    // Get the request body to extract student data
    const body = await request.json();
    const { studentData: requestStudentData, email } = body;
    
    let studentData = requestStudentData;
    
    // If no student data provided, try to fetch from backend API
    if (!studentData && email) {
      try {
        const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';
        const response = await fetch(`${backendUrl}/api/students/data?email=${encodeURIComponent(email)}`);
        
        if (response.ok) {
          const result = await response.json();
          if (result.success && result.student) {
            studentData = {
              id: result.student._id,
              studentId: result.student.studentId,
              fullName: result.student.fullName,
              email: result.student.email,
              phoneNumber: result.student.phoneNumber,
              college: result.student.college,
              grade: result.student.grade,
              major: result.student.major,
              address: result.student.address,
              profilePhoto: result.student.profilePhoto
            };
            console.log('Found student data for QR generation:', result.student.fullName);
          }
        }
      } catch (error) {
        console.log('Error loading student data from backend:', error);
      }
    }
    
    // Return error if no student data found
    if (!studentData) {
      return NextResponse.json({
        success: false,
        message: 'Student not found'
      }, { status: 404 });
    }

    // Generate QR code data with complete student information
    const qrData = {
      id: studentData.id,
      studentId: studentData.studentId,
      fullName: studentData.fullName,
      email: studentData.email,
      phoneNumber: studentData.phoneNumber,
      college: studentData.college,
      grade: studentData.grade,
      major: studentData.major,
      address: studentData.address,
      profilePhoto: studentData.profilePhoto || null,
      timestamp: Date.now(),
      type: 'student_qr_code'
    };

    // Generate QR code
    const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData), {
      width: 300,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });

    // Create qr-codes directory if it doesn't exist
    const qrDir = join(process.cwd(), 'public', 'uploads', 'qr-codes');
    try {
      await mkdir(qrDir, { recursive: true });
    } catch (error) {
      // Directory might already exist
    }

    // Save QR code as PNG
    const filename = `qr_${studentData.studentId}_${Date.now()}.png`;
    const filepath = join(qrDir, filename);
    
    // Convert data URL to buffer and save
    const base64Data = qrCodeDataURL.replace(/^data:image\/png;base64,/, '');
    const buffer = Buffer.from(base64Data, 'base64');
    await writeFile(filepath, buffer);

    // Return QR code URL
    const qrCodeUrl = `/uploads/qr-codes/${filename}`;

    return NextResponse.json({
      success: true,
      message: 'QR code generated successfully',
      qrCodeUrl,
      qrCodeDataURL, // For immediate display
      qrCode: qrCodeDataURL, // Alternative field name for compatibility
      data: qrCodeDataURL // Another alternative field name
    });

  } catch (error) {
    console.error('QR code generation error:', error);
    return NextResponse.json(
      { success: false, message: 'Failed to generate QR code', error: error.message },
      { status: 500 }
    );
  }
}