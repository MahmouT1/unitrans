// Test script to create sample attendance records
const { MongoClient, ObjectId } = require('mongodb');

const MONGODB_URI = 'mongodb://localhost:27017';
const DB_NAME = 'student-portal';

async function createSampleAttendance() {
    const client = new MongoClient(MONGODB_URI);
    
    try {
        await client.connect();
        console.log('Connected to MongoDB');
        
        const db = client.db(DB_NAME);
        const studentsCollection = db.collection('students');
        const attendanceCollection = db.collection('attendances');
        
        // Get first student
        const student = await studentsCollection.findOne({});
        if (!student) {
            console.log('No students found in database');
            return;
        }
        
        console.log('Found student:', student.fullName, student.email);
        
        // Create sample attendance records
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
                    location: 'المدخل الرئيسي',
                    coordinates: { lat: 30.0444, lng: 31.2357 }
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
                    location: 'المدخل الرئيسي',
                    coordinates: { lat: 30.0444, lng: 31.2357 }
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
                    location: 'المدخل الرئيسي',
                    coordinates: { lat: 30.0444, lng: 31.2357 }
                },
                qrScanned: true,
                createdAt: new Date(),
                updatedAt: new Date()
            }
        ];
        
        // Insert attendance records
        const result = await attendanceCollection.insertMany(attendanceRecords);
        console.log(`Created ${result.insertedCount} attendance records`);
        
        // Verify count
        const count = await attendanceCollection.countDocuments({ studentId: student._id });
        console.log(`Total attendance records for student: ${count}`);
        
        // Test the admin API query
        const attendanceCount = await attendanceCollection.countDocuments({
            $or: [
                { studentId: student._id },
                { studentEmail: student.email.toLowerCase() }
            ]
        });
        
        const presentCount = await attendanceCollection.countDocuments({
            $or: [
                { studentId: student._id },
                { studentEmail: student.email.toLowerCase() }
            ],
            status: { $in: ['Present', 'Late'] }
        });
        
        console.log('API Query Results:');
        console.log(`  Attendance Count: ${attendanceCount}`);
        console.log(`  Present Count: ${presentCount}`);
        console.log(`  Attendance Rate: ${attendanceCount > 0 ? Math.round((presentCount / attendanceCount) * 100) : 0}%`);
        
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await client.close();
    }
}

// Run the test
createSampleAttendance().catch(console.error);
