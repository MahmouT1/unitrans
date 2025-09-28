const { MongoClient } = require('mongodb');

async function createProductionUsers() {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
    const dbName = process.env.MONGODB_DB_NAME || 'student_portal';
    
    const client = new MongoClient(mongoUri);
    await client.connect();
    const db = client.db(dbName);
    
    console.log('🔗 Connected to database:', dbName);
    
    // Production users with simple passwords
    const users = [
      {
        email: 'admin@unibus.com',
        password: 'admin123',
        fullName: 'System Administrator',
        role: 'admin',
        isActive: true,
        createdAt: new Date()
      },
      {
        email: 'supervisor@unibus.com', 
        password: 'supervisor123',
        fullName: 'System Supervisor',
        role: 'supervisor',
        isActive: true,
        createdAt: new Date()
      },
      {
        email: 'student@unibus.com',
        password: 'student123', 
        fullName: 'Test Student',
        role: 'student',
        isActive: true,
        createdAt: new Date()
      },
      {
        email: 'test@test.com',
        password: '123456',
        fullName: 'Test User',
        role: 'student', 
        isActive: true,
        createdAt: new Date()
      },
      {
        email: 'rozan@gmail.com',
        password: 'roz123',
        fullName: 'Rozan User',
        role: 'student', 
        isActive: true,
        createdAt: new Date()
      }
    ];
    
    // Clear existing test users first
    console.log('🗑️  Clearing existing test users...');
    await db.collection('users').deleteMany({
      email: { $in: users.map(u => u.email) }
    });
    
    // Insert new users
    console.log('👤 Creating production users...');
    const result = await db.collection('users').insertMany(users);
    console.log('✅ Created', result.insertedCount, 'production users');
    
    // Create student records for student users
    console.log('🎓 Creating student records...');
    for (const user of users) {
      if (user.role === 'student') {
        await db.collection('students').deleteOne({ email: user.email });
        await db.collection('students').insertOne({
          fullName: user.fullName,
          email: user.email,
          phoneNumber: '',
          college: 'University College',
          grade: 'Bachelor',
          major: 'Computer Science',
          address: {
            city: '',
            street: '',
            building: ''
          },
          attendanceCount: 0,
          isActive: true,
          userId: user._id,
          createdAt: new Date(),
          updatedAt: new Date()
        });
      }
    }
    
    // Display created users
    console.log('\n📋 Production users created:');
    users.forEach(user => {
      console.log(`  • ${user.email} / ${user.password} (${user.role})`);
    });
    
    // Test user search
    console.log('\n🔍 Testing user search...');
    const testUser = await db.collection('users').findOne({ 
      email: 'test@test.com' 
    });
    
    if (testUser) {
      console.log('✅ Test user found:', {
        email: testUser.email,
        role: testUser.role,
        password: testUser.password
      });
    } else {
      console.log('❌ Test user not found!');
    }
    
    await client.close();
    console.log('\n🎉 Production users setup complete!');
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

createProductionUsers();
