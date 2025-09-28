const { MongoClient } = require('mongodb');

async function checkProductionDatabase() {
  console.log('🔍 فحص هيكل قاعدة البيانات على سيرفر الدومين');
  console.log('================================================');
  
  // استخدام نفس إعدادات السيرفر
  const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
  const mongoDbName = process.env.MONGODB_DB_NAME || 'student_portal';
  
  console.log(`📡 MongoDB URI: ${mongoUri}`);
  console.log(`📊 Database Name: ${mongoDbName}`);
  
  const client = new MongoClient(mongoUri);
  
  try {
    await client.connect();
    console.log('✅ متصل بـ MongoDB على السيرفر');
    
    const db = client.db(mongoDbName);
    
    // فحص جميع الكوليكشنس الموجودة
    const collections = await db.listCollections().toArray();
    console.log(`\n📁 إجمالي الكوليكشنس: ${collections.length}`);
    console.log('\n📋 قائمة الكوليكشنس:');
    
    for (const collection of collections) {
      const collectionName = collection.name;
      const count = await db.collection(collectionName).countDocuments();
      console.log(`  📂 ${collectionName}: ${count} وثيقة`);
    }
    
    // فحص تفصيلي للكوليكشنس المهمة
    console.log('\n🔍 فحص تفصيلي للكوليكشنس:');
    
    // فحص users collection
    if (collections.find(c => c.name === 'users')) {
      console.log('\n👥 Users Collection:');
      const users = await db.collection('users').find({}).limit(5).toArray();
      users.forEach(user => {
        console.log(`  📧 ${user.email} | 👤 ${user.role || 'no role'} | 📛 ${user.fullName || 'no name'}`);
      });
      
      // فحص الأدوار
      const roles = await db.collection('users').distinct('role');
      console.log(`  🎭 الأدوار الموجودة: [${roles.join(', ')}]`);
    }
    
    // فحص students collection
    if (collections.find(c => c.name === 'students')) {
      console.log('\n🎓 Students Collection:');
      const students = await db.collection('students').find({}).limit(3).toArray();
      students.forEach(student => {
        console.log(`  📧 ${student.email} | 🆔 ${student.studentId || 'no ID'} | 🏫 ${student.college || 'no college'}`);
      });
    }
    
    // فحص shifts collection  
    if (collections.find(c => c.name === 'shifts')) {
      console.log('\n📅 Shifts Collection:');
      const shiftsCount = await db.collection('shifts').countDocuments();
      const activeShifts = await db.collection('shifts').countDocuments({ status: 'active' });
      const closedShifts = await db.collection('shifts').countDocuments({ status: 'closed' });
      console.log(`  📊 إجمالي الورديات: ${shiftsCount}`);
      console.log(`  🟢 الورديات النشطة: ${activeShifts}`);
      console.log(`  🔴 الورديات المغلقة: ${closedShifts}`);
    }
    
    // فحص attendance collection
    if (collections.find(c => c.name === 'attendance')) {
      console.log('\n✅ Attendance Collection:');
      const attendanceCount = await db.collection('attendance').countDocuments();
      console.log(`  📊 إجمالي سجلات الحضور: ${attendanceCount}`);
      
      // آخر 3 سجلات حضور
      const recentAttendance = await db.collection('attendance')
        .find({})
        .sort({ scanTime: -1 })
        .limit(3)
        .toArray();
      
      recentAttendance.forEach(record => {
        console.log(`  ⏰ ${record.scanTime} | 📧 ${record.studentEmail} | 👨‍💼 ${record.supervisorName}`);
      });
    }
    
    // فحص subscriptions collection
    if (collections.find(c => c.name === 'subscriptions')) {
      console.log('\n💳 Subscriptions Collection:');
      const subscriptionsCount = await db.collection('subscriptions').countDocuments();
      console.log(`  📊 إجمالي الاشتراكات: ${subscriptionsCount}`);
    }
    
    console.log('\n🎯 ملخص هيكل قاعدة البيانات:');
    console.log('===============================');
    console.log(`📊 Database: ${mongoDbName}`);
    console.log(`📁 Collections: ${collections.length}`);
    console.log(`👥 Users: ${await db.collection('users').countDocuments()} حساب`);
    console.log(`🎓 Students: ${await db.collection('students').countDocuments()} طالب`);
    console.log(`📅 Shifts: ${await db.collection('shifts').countDocuments()} وردية`);
    console.log(`✅ Attendance: ${await db.collection('attendance').countDocuments()} سجل حضور`);
    
  } catch (error) {
    console.error('❌ خطأ في الاتصال:', error);
  } finally {
    await client.close();
    console.log('\n🔌 تم قطع الاتصال بقاعدة البيانات');
  }
}

// تشغيل الفحص
checkProductionDatabase().then(() => {
  console.log('\n✅ اكتمل فحص قاعدة البيانات على السيرفر!');
  process.exit(0);
}).catch(error => {
  console.error('❌ فشل فحص قاعدة البيانات:', error);
  process.exit(1);
});
