# إصلاح آمن لمشكلة التسجيل

## 🔍 المشكلة المحددة:
- صفحة التسجيل تُظهر "Registration not implemented yet"
- أخطاء اتصال بـ localhost:3001 بدلاً من الدومين

## 📋 الفحص المطلوب أولاً:

### 1️⃣ فحص ملف Auth الحالي على السيرفر:
```bash
ssh root@unibus.online "cat /var/www/unitrans/frontend-new/app/auth/page.js | grep -A 5 -B 5 'Registration not implemented'"
```

### 2️⃣ فحص إعدادات البيئة:
```bash
ssh root@unibus.online "cat /var/www/unitrans/frontend-new/.env.local"
```

### 3️⃣ فحص ملف API Config:
```bash
ssh root@unibus.online "cat /var/www/unitrans/frontend-new/config/api.js"
```

## 🔧 الإصلاح الآمن (بناء على النتائج):

### إذا كانت المشكلة في ملف auth/page.js:
- نحتاج لإزالة رسالة "Registration not implemented yet"
- وتفعيل دالة التسجيل

### إذا كانت المشكلة في إعدادات API:
- نحتاج لتغيير localhost إلى unibus.online

## 🚨 قاعدة الأمان:
- لا نرفع أي تحديثات قبل فهم الملفات الحالية
- نأخذ backup من أي ملف قبل تعديله
- نختبر كل تغيير منفرداً
