// فحص تفاصيل الاتصال بقاعدة البيانات
require('dotenv').config({ path: 'backend-new/.env' });
const { MongoClient } = require('mongodb');

async function checkConnectionDetails() {
    console.log('🔍 فحص تفاصيل الاتصال بقاعدة البيانات...\n');
    
    try {
        // عرض متغيرات البيئة
        console.log('📋 إعدادات قاعدة البيانات من .env:');
        console.log('='.repeat(60));
        console.log('MONGODB_URI:', process.env.MONGODB_URI);
        console.log('MONGODB_DB_NAME:', process.env.MONGODB_DB_NAME);
        console.log('\n');
        
        const client = new MongoClient(process.env.MONGODB_URI);
        await client.connect();
        console.log('✅ تم الاتصال بقاعدة البيانات\n');
        
        // فحص قواعد البيانات المتاحة
        const adminDb = client.db().admin();
        const databases = await adminDb.listDatabases();
        
        console.log('🗄️ جميع قواعد البيانات المتاحة:');
        console.log('='.repeat(60));
        databases.databases.forEach((db, index) => {
            console.log(`${index + 1}. ${db.name} (${(db.sizeOnDisk / 1024 / 1024).toFixed(2)} MB)`);
        });
        console.log('\n');
        
        // فحص قاعدة البيانات المحددة
        const db = client.db(process.env.MONGODB_DB_NAME);
        const collections = await db.listCollections().toArray();
        
        console.log(`📊 مجموعات في قاعدة البيانات "${process.env.MONGODB_DB_NAME}":`);
        console.log('='.repeat(60));
        
        if (collections.length === 0) {
            console.log('⚠️ لا توجد مجموعات في هذه قاعدة البيانات!');
            console.log('📍 هذا يعني أن النظام يتصل بقاعدة بيانات فارغة أو جديدة\n');
        } else {
            for (const collection of collections) {
                const coll = db.collection(collection.name);
                const count = await coll.countDocuments();
                console.log(`📁 ${collection.name}: ${count} وثيقة`);
            }
        }
        
        // فحص قاعدة البيانات التي تظهر في MongoDB Compass
        console.log('\n🔍 فحص قاعدة البيانات "student-portal" (من MongoDB Compass):');
        console.log('='.repeat(60));
        
        const compassDb = client.db('student-portal');
        const compassCollections = await compassDb.listCollections().toArray();
        
        if (compassCollections.length > 0) {
            console.log('✅ تم العثور على قاعدة البيانات "student-portal":');
            for (const collection of compassCollections) {
                const coll = compassDb.collection(collection.name);
                const count = await coll.countDocuments();
                console.log(`📁 ${collection.name}: ${count} وثيقة`);
                
                // عرض عينة من مجموعة users إذا وجدت
                if (collection.name === 'users' && count > 0) {
                    console.log('\n👤 عينة من مجموعة users:');
                    const userSample = await coll.findOne();
                    console.log(JSON.stringify(userSample, null, 2));
                }
            }
        } else {
            console.log('❌ لم يتم العثور على قاعدة البيانات "student-portal"');
        }
        
        await client.close();
        console.log('\n✅ تم إغلاق الاتصال');
        
    } catch (error) {
        console.error('❌ خطأ:', error.message);
    }
}

checkConnectionDetails();
