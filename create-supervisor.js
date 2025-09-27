const { MongoClient } = require('mongodb');
const bcrypt = require('bcrypt');

async function createSupervisor() {
    const client = new MongoClient('mongodb://localhost:27017');
    
    try {
        await client.connect();
        const db = client.db('unibus');
        
        // Check if supervisor already exists
        const existingUser = await db.collection('users').findOne({email: 'supervisor@unibus.com'});
        
        if (existingUser) {
            console.log('✅ Supervisor user already exists');
            return;
        }
        
        // Hash password
        const hashedPassword = await bcrypt.hash('supervisor123', 10);
        
        // Create supervisor user
        const supervisorUser = {
            email: 'supervisor@unibus.com',
            password: hashedPassword,
            role: 'supervisor',
            fullName: 'Supervisor User',
            status: 'active',
            createdAt: new Date(),
            updatedAt: new Date()
        };
        
        const result = await db.collection('users').insertOne(supervisorUser);
        
        if (result.insertedId) {
            console.log('✅ Supervisor user created successfully');
            console.log('Email: supervisor@unibus.com');
            console.log('Password: supervisor123');
            console.log('Role: supervisor');
        }
        
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await client.close();
    }
}

createSupervisor();
