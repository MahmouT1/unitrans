// فحص إعدادات البيئة
const fs = require('fs');
const path = require('path');

function checkEnvSettings() {
    console.log('🔍 فحص ملفات إعدادات البيئة...\n');
    
    const envFiles = [
        'backend-new/.env',
        'frontend-new/.env.local',
        '.env'
    ];
    
    envFiles.forEach(envFile => {
        console.log(`📁 فحص ملف: ${envFile}`);
        console.log('='.repeat(50));
        
        if (fs.existsSync(envFile)) {
            try {
                const content = fs.readFileSync(envFile, 'utf8');
                console.log('✅ الملف موجود');
                console.log('📋 المحتوى:');
                
                // عرض المحتوى مع إخفاء كلمات المرور الحساسة
                const lines = content.split('\n');
                lines.forEach(line => {
                    if (line.trim() && !line.startsWith('#')) {
                        if (line.includes('PASSWORD') || line.includes('SECRET') || line.includes('TOKEN')) {
                            const [key] = line.split('=');
                            console.log(`${key}=***HIDDEN***`);
                        } else {
                            console.log(line);
                        }
                    }
                });
                
            } catch (error) {
                console.log(`❌ خطأ في قراءة الملف: ${error.message}`);
            }
        } else {
            console.log('❌ الملف غير موجود');
        }
        
        console.log('\n');
    });
}

checkEnvSettings();
