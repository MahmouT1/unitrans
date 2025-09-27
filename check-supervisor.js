const { MongoClient } = require('mongodb');

async function checkSupervisor() {
    const client = new MongoClient('mongodb://localhost:27017');
    
    try {
        await client.connect();
        const db = client.db('unibus');
        
        const user = await db.collection('users').findOne({email: 'supervisor@unibus.com'});
        
        if (user) {
            console.log('✅ Supervisor user found:');
            console.log('Email:', user.email);
            console.log('Role:', user.role);
            console.log('Status:', user.status);
            console.log('Full Name:', user.fullName);
        } else {
            console.log('❌ Supervisor user NOT found');
        }
        
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await client.close();
    }
}

checkSupervisor();
