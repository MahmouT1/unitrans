# 🚀 رفع مشروع UniBus على VPS - دليل سريع

## 📋 المتطلبات
- VPS مع Ubuntu 20.04 أو أحدث
- 4GB RAM على الأقل
- دومين مُعد ومُوجه للخادم
- اتصال بالإنترنت

## 🎯 الرفع بنقرة واحدة

### الخطوة 1: الاتصال بالخادم
```bash
ssh root@your-server-ip
```

### الخطوة 2: تحميل السكريبت
```bash
wget https://raw.githubusercontent.com/MahmouT1/unitrans/main/one-click-deploy.sh
```

### الخطوة 3: تشغيل السكريبت
```bash
chmod +x one-click-deploy.sh
./one-click-deploy.sh
```

### الخطوة 4: إدخال البيانات
السكريبت سيسألك عن:
- اسم الدومين (مثال: yourdomain.com)
- البريد الإلكتروني للـ SSL

**ملاحظة:** السكريبت متوافق مع MongoDB Compass (بدون كلمة مرور) و Node.js 22.x

## ✅ ما يفعله السكريبت تلقائياً

### 🔧 التثبيت
- تحديث النظام
- تثبيت Node.js 18.x
- تثبيت PM2
- تثبيت MongoDB
- تثبيت Nginx
- تثبيت أدوات SSL

### 📁 المشروع
- تحميل المشروع من GitHub
- تثبيت جميع المكتبات
- بناء المشروع
- إعداد ملفات البيئة

### ⚙️ الإعداد
- تشغيل التطبيقات مع PM2
- إعداد Nginx
- إعداد SSL Certificate
- إعداد قاعدة البيانات
- إضافة البيانات التجريبية

### 🛡️ الأمان
- إعداد Firewall
- حماية المنافذ
- SSL آمن

### 🔄 الصيانة
- سكريبت التحديث التلقائي
- سكريبت النسخ الاحتياطية
- مهام Cron تلقائية

## 🎉 النتيجة النهائية

بعد تشغيل السكريبت ستحصل على:
- موقع UniBus يعمل على: `https://yourdomain.com`
- لوحة تحكم إدارية
- نظام QR Scanner
- إدارة الطلاب والحضور
- تقارير مالية
- نسخ احتياطية تلقائية

## 📞 في حالة وجود مشاكل

### فحص الحالة
```bash
pm2 status
systemctl status nginx
systemctl status mongod
```

### عرض السجلات
```bash
pm2 logs
tail -f /var/log/nginx/error.log
```

### إعادة تشغيل الخدمات
```bash
pm2 restart all
systemctl restart nginx
```

## 🔄 تحديث المشروع

```bash
/var/www/unitrans/update.sh
```

## 💾 إنشاء نسخة احتياطية

```bash
/var/www/unitrans/backup.sh
```

---

**ملاحظة:** السكريبت آمن 100% ولا يحتاج أي تدخل يدوي. فقط شغله واتركه يعمل! 🚀
