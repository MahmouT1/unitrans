# دليل إصلاح المصادقة في الإنتاج 🔧

## المشكلة المحددة
```
خطأ 404: Route /api/proxy/auth/login not found
خطأ bcrypt: Cannot find module 'bcrypt'
```

## الحل الشامل

### 1. رفع الملفات المُحدثة إلى السيرفر
```bash
# انسخ هذه الملفات إلى السيرفر:
- backend-new/routes/auth.js (محدث)
- backend-new/routes/students.js (محدث) 
- frontend-new/app/api/proxy/auth/login/route.js (موجود)
- frontend-new/config/api.js (محدث)
```

### 2. تشغيل سكريبت الإصلاح على السيرفر
```bash
# على السيرفر VPS:
cd /home/unitrans
chmod +x fix-production-auth-complete.sh
./fix-production-auth-complete.sh
```

### 3. حسابات الاختبار المتاحة
```
👤 Admin: admin@unibus.com / admin123
👤 Supervisor: supervisor@unibus.com / supervisor123  
👤 Student: student@unibus.com / student123
👤 Test: test@test.com / 123456
```

### 4. فحص حالة النظام
```bash
# فحص الخوادم
curl https://unibus.online/health
curl https://unibus.online/api/health

# فحص المصادقة
curl -X POST https://unibus.online/api/proxy/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}'
```

### 5. إذا استمرت المشكلة
```bash
# فحص اللوقز
tail -f /home/unitrans/backend.log
tail -f /home/unitrans/frontend.log

# إعادة تشغيل الخدمات
pkill -f node
cd /home/unitrans/backend-new && nohup node server.js &
cd /home/unitrans/frontend-new && nohup npm start &
```

## الملفات المُصلحة

### backend-new/routes/auth.js
- ✅ إصلاح دعم كلمات المرور المشفرة والعادية
- ✅ إضافة تشخيص مفصل
- ✅ تحسين معالجة الأخطاء

### backend-new/routes/students.js  
- ✅ إصلاح تبعية bcrypt → bcryptjs

### frontend-new/app/api/proxy/auth/login/route.js
- ✅ تحسين معالجة البروكسي
- ✅ إضافة تشخيص للطلبات

### frontend-new/config/api.js
- ✅ دعم متغيرات البيئة
- ✅ تحسين معالجة الأخطاء

## ملاحظات مهمة
- 🔒 النظام يدعم كلمات المرور المشفرة والعادية
- 🌐 البروكسي يعمل عبر Next.js لتجنب مشاكل CORS
- 📱 التطبيق يعمل على https://unibus.online
- 🗃️ قاعدة البيانات: MongoDB على localhost:27017
