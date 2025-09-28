// فحص هيكل قاعدة البيانات
require('dotenv').config({ path: 'backend-new/.env' });
const { MongoClient } = require('mongodb');

async function checkDatabaseStructure() {
    console.log('🔍 فحص هيكل قاعدة البيانات...\n');
    
    try {
        const client = new MongoClient(process.env.MONGODB_URI);
        await client.connect();
        console.log('✅ تم الاتصال بقاعدة البيانات\n');
        
        const db = client.db(process.env.MONGODB_DB_NAME);
        console.log(`📊 اسم قاعدة البيانات: ${process.env.MONGODB_DB_NAME}\n`);
        
        // 1️⃣ عرض جميع المجموعات
        const collections = await db.listCollections().toArray();
        console.log('📋 المجموعات الموجودة:');
        console.log('='.repeat(50));
        collections.forEach((col, index) => {
            console.log(`${index + 1}. ${col.name}`);
        });
        console.log('\n');
        
        // 2️⃣ فحص كل مجموعة
        for (const collection of collections) {
            const collectionName = collection.name;
            const coll = db.collection(collectionName);
            
            // عدد الوثائق
            const count = await coll.countDocuments();
            
            // عينة من الوثائق
            const sample = await coll.findOne();
            
            console.log(`📁 مجموعة: ${collectionName}`);
            console.log(`   📊 عدد الوثائق: ${count}`);
            
            if (sample) {
                console.log(`   🔍 هيكل الوثيقة:`);
                console.log(`   ${JSON.stringify(sample, null, 6).replace(/\n/g, '\n   ')}`);
            } else {
                console.log(`   ⚠️  المجموعة فارغة`);
            }
            console.log('-'.repeat(80));
        }
        
        // 3️⃣ فحص الفهارس
        console.log('\n🔑 الفهارس (Indexes):');
        console.log('='.repeat(50));
        for (const collection of collections) {
            const collectionName = collection.name;
            const coll = db.collection(collectionName);
            const indexes = await coll.indexes();
            
            console.log(`📁 ${collectionName}:`);
            indexes.forEach(index => {
                console.log(`   - ${JSON.stringify(index.key)} ${index.unique ? '(فريد)' : ''}`);
            });
            console.log('');
        }
        
        await client.close();
        console.log('✅ تم إغلاق الاتصال');
        
    } catch (error) {
        console.error('❌ خطأ:', error.message);
    }
}

checkDatabaseStructure();
