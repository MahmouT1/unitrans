const bcrypt = require('bcryptjs');
const { MongoClient } = require('mongodb');

const MONGO_URI = 'mongodb://localhost:27017';
const DB_NAME = 'student_portal';

const supervisors = [
  { fullName: 'Mostafa sona', email: 'sasasona@gmail.com', password: 'Sons123' },
  { fullName: 'Vodo joe', email: 'Vodojoe123@gmail.com', password: 'Vodx123' },
  { fullName: 'Mazen Zoma', email: 'Zoma144@gmail.com', password: 'Mezo001' },
  { fullName: 'islamuni', email: 'Islam123@gmail.com', password: 'islamzero123' },
  { fullName: 'Mohamed Abuzaid', email: 'Abuzaid123@gmail.com', password: 'Abuz002' },
  { fullName: 'Omar Reda', email: 'omarRedatuning@gmail.com', password: 'omarReda123' }
];

const admins = [
  { fullName: 'AzabunibusAdmin', email: 'Azabuni123@gmail.com', password: 'Unibus00444' },
  { fullName: 'SonaunibusAdmin', email: 'SonaUni333@gmail.com', password: 'Mostafuni0707' }
];

async function addAccounts() {
  const client = new MongoClient(MONGO_URI);
  
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB');
    
    const db = client.db(DB_NAME);
    const usersCollection = db.collection('users');
    
    // Add Supervisors
    console.log('\n📋 Adding Supervisors...');
    console.log('========================');
    
    for (const supervisor of supervisors) {
      // Check if user exists
      const existing = await usersCollection.findOne({ email: supervisor.email });
      
      if (existing) {
        console.log(`⚠️  ${supervisor.fullName} (${supervisor.email}) already exists - updating...`);
        
        const hashedPassword = await bcrypt.hash(supervisor.password, 10);
        await usersCollection.updateOne(
          { email: supervisor.email },
          { 
            $set: { 
              fullName: supervisor.fullName,
              password: hashedPassword,
              role: 'supervisor',
              updatedAt: new Date()
            }
          }
        );
        console.log(`   ✅ Updated successfully`);
      } else {
        const hashedPassword = await bcrypt.hash(supervisor.password, 10);
        
        await usersCollection.insertOne({
          fullName: supervisor.fullName,
          email: supervisor.email,
          password: hashedPassword,
          role: 'supervisor',
          createdAt: new Date(),
          updatedAt: new Date()
        });
        
        console.log(`✅ Added: ${supervisor.fullName} (${supervisor.email})`);
      }
    }
    
    // Add Admins
    console.log('\n👑 Adding Admins...');
    console.log('===================');
    
    for (const admin of admins) {
      // Check if user exists
      const existing = await usersCollection.findOne({ email: admin.email });
      
      if (existing) {
        console.log(`⚠️  ${admin.fullName} (${admin.email}) already exists - updating...`);
        
        const hashedPassword = await bcrypt.hash(admin.password, 10);
        await usersCollection.updateOne(
          { email: admin.email },
          { 
            $set: { 
              fullName: admin.fullName,
              password: hashedPassword,
              role: 'admin',
              updatedAt: new Date()
            }
          }
        );
        console.log(`   ✅ Updated successfully`);
      } else {
        const hashedPassword = await bcrypt.hash(admin.password, 10);
        
        await usersCollection.insertOne({
          fullName: admin.fullName,
          email: admin.email,
          password: hashedPassword,
          role: 'admin',
          createdAt: new Date(),
          updatedAt: new Date()
        });
        
        console.log(`✅ Added: ${admin.fullName} (${admin.email})`);
      }
    }
    
    // Summary
    console.log('\n📊 Summary:');
    console.log('============');
    const supervisorCount = await usersCollection.countDocuments({ role: 'supervisor' });
    const adminCount = await usersCollection.countDocuments({ role: 'admin' });
    
    console.log(`👥 Total Supervisors: ${supervisorCount}`);
    console.log(`👑 Total Admins: ${adminCount}`);
    console.log(`📈 Total Users: ${supervisorCount + adminCount}`);
    
    console.log('\n✅ All accounts added/updated successfully!');
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
  }
}

addAccounts();
