const { MongoClient } = require('mongodb');
const bcrypt = require('bcrypt');

async function addUsersDirectly() {
  console.log('👥 إضافة مستخدمين مباشرة لقاعدة البيانات...');
  
  const client = new MongoClient('mongodb://localhost:27017');
  
  try {
    await client.connect();
    console.log('✅ متصل بـ MongoDB');
    
    const db = client.db('student_portal');
    const usersCollection = db.collection('users');
    
    // حذف المستخدمين الموجودين
    await usersCollection.deleteMany({});
    console.log('🧹 تم حذف المستخدمين السابقين');
    
    // إضافة مستخدمين جدد
    const users = [
      {
        email: 'test@test.com',
        password: await bcrypt.hash('123456', 12),
        fullName: 'Test Student',
        role: 'student',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        email: 'roo2admin@gmail.com',
        password: await bcrypt.hash('admin123', 12),
        fullName: 'Root Administrator',
        role: 'admin',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        email: 'ahmedazab@gmail.com',
        password: await bcrypt.hash('supervisor123', 12),
        fullName: 'Ahmed Azab',
        role: 'supervisor',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        email: 'mostafamohamed@gmail.com',
        password: await bcrypt.hash('student123', 12),
        fullName: 'Mostafa Mohamed',
        role: 'student',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
      }
    ];
    
    const result = await usersCollection.insertMany(users);
    console.log(`✅ تم إضافة ${result.insertedCount} مستخدمين`);
    
    // طباعة المستخدمين المضافين
    const allUsers = await usersCollection.find({}).toArray();
    console.log('\n👥 المستخدمين في قاعدة البيانات:');
    allUsers.forEach(user => {
      console.log(`  📧 ${user.email} | 👤 ${user.role} | 👤 ${user.fullName}`);
    });
    
    console.log('\n🎯 حسابات الاختبار:');
    console.log('  📧 test@test.com | 🔑 123456 | 👤 student');
    console.log('  📧 roo2admin@gmail.com | 🔑 admin123 | 👤 admin');
    console.log('  📧 ahmedazab@gmail.com | 🔑 supervisor123 | 👤 supervisor');
    console.log('  📧 mostafamohamed@gmail.com | 🔑 student123 | 👤 student');
    
  } catch (error) {
    console.error('❌ خطأ:', error);
  } finally {
    await client.close();
    console.log('🔌 تم قطع الاتصال بـ MongoDB');
  }
}

// تشغيل الدالة
addUsersDirectly().then(() => {
  console.log('\n✅ اكتمل إضافة المستخدمين!');
  process.exit(0);
}).catch(error => {
  console.error('❌ فشل في إضافة المستخدمين:', error);
  process.exit(1);
});
