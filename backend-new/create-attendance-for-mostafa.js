const { MongoClient } = require('mongodb');

const MONGODB_URI = 'mongodb://localhost:27017';
const DB_NAME = 'student-portal';

async function createAttendanceForMostafa() {
    const client = new MongoClient(MONGODB_URI);
    
    try {
        await client.connect();
        console.log('Connected to MongoDB');
        
        const db = client.db(DB_NAME);
        
        // Find Mostafa
        const student = await db.collection('students').findOne({ 
            email: 'mostafamohamed@gmail.com' 
        });
        
        if (!student) {
            console.log('Mostafa not found');
            return;
        }
        
        console.log('Found student:', student.fullName, student.email);
        console.log('Student ID:', student._id);
        
        // Create attendance records
        const attendanceRecords = [
            {
                studentId: student._id,
                studentEmail: student.email.toLowerCase(),
                status: 'Present',
                date: new Date('2025-09-26'),
                checkInTime: new Date('2025-09-26T08:00:00Z'),
                appointmentSlot: 'first',
                station: {
                    name: 'محطة الجامعة',
                    location: 'المدخل الرئيسي'
                },
                qrScanned: true,
                createdAt: new Date(),
                updatedAt: new Date()
            },
            {
                studentId: student._id,
                studentEmail: student.email.toLowerCase(),
                status: 'Present',
                date: new Date('2025-09-25'),
                checkInTime: new Date('2025-09-25T08:15:00Z'),
                appointmentSlot: 'first',
                station: {
                    name: 'محطة الجامعة',
                    location: 'المدخل الرئيسي'
                },
                qrScanned: true,
                createdAt: new Date(),
                updatedAt: new Date()
            },
            {
                studentId: student._id,
                studentEmail: student.email.toLowerCase(),
                status: 'Late',
                date: new Date('2025-09-24'),
                checkInTime: new Date('2025-09-24T08:25:00Z'),
                appointmentSlot: 'first',
                station: {
                    name: 'محطة الجامعة',
                    location: 'المدخل الرئيسي'
                },
                qrScanned: true,
                createdAt: new Date(),
                updatedAt: new Date()
            }
        ];
        
        // Insert records
        const result = await db.collection('attendances').insertMany(attendanceRecords);
        console.log(`Created ${result.insertedCount} attendance records for Mostafa`);
        
        // Test the exact query from our API
        const attendanceCount = await db.collection('attendances').countDocuments({
            $or: [
                { studentId: student._id },
                { studentEmail: student.email.toLowerCase() }
            ]
        });
        
        const presentCount = await db.collection('attendances').countDocuments({
            $or: [
                { studentId: student._id },
                { studentEmail: student.email.toLowerCase() }
            ],
            status: { $in: ['Present', 'Late'] }
        });
        
        console.log('API Query Test Results:');
        console.log(`  Total Attendance: ${attendanceCount}`);
        console.log(`  Present Count: ${presentCount}`);
        console.log(`  Attendance Rate: ${attendanceCount > 0 ? Math.round((presentCount / attendanceCount) * 100) : 0}%`);
        
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await client.close();
    }
}

createAttendanceForMostafa().catch(console.error);
