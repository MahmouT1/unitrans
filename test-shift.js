const { getDatabase } = require('./lib/mongodb-simple-connection');

async function testShift() {
    try {
        const db = await getDatabase();
        console.log('Database connected:', db.databaseName);
        
        const shift = await db.collection('shifts').findOne({id: '1758992360613'});
        console.log('Shift found:', shift ? 'YES' : 'NO');
        
        if (shift) {
            console.log('Shift ID:', shift.id);
            console.log('Shift Status:', shift.status);
        }
        
        const attendance = await db.collection('attendance').find({shiftId: '1758992360613'}).toArray();
        console.log('Attendance records found:', attendance.length);
        
    } catch (error) {
        console.error('Error:', error);
    }
}

testShift();
