const { MongoClient } = require('mongodb');

async function testShift2() {
    try {
        const client = new MongoClient('mongodb://localhost:27017');
        await client.connect();
        const db = client.db('unitrans');
        console.log('Database connected:', db.databaseName);
        
        const shift = await db.collection('shifts').findOne({});
        console.log('Sample shift:', shift ? shift.id : 'None');
        
        if (shift) {
            console.log('Shift ID:', shift.id);
            console.log('Shift Status:', shift.status);
        }
        
        await client.close();
        
    } catch (error) {
        console.error('Error:', error);
    }
}

testShift2();
