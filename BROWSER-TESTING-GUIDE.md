# 📋 دليل اختبار المشروع الكامل على المتصفح

## ⚠️ قبل البدء - مهم جداً:

### تنظيف Cache:
```
1. Ctrl+Shift+Delete
2. اختر: All time
3. ✓ Cookies and site data
4. ✓ Cached images and files
5. Clear data
6. أغلق المتصفح تماماً
7. افتحه من جديد
```

---

## 🎯 السيناريو الكامل: اختبار ali ramy

---

### المرحلة 1️⃣: إنشاء حساب جديد

1. **افتح:** `https://unibus.online/login`
2. **اضغط** على "إنشاء حساب جديد" أو "Register"
3. **أدخل البيانات:**
   - Full Name: `ali ramy`
   - Email: `aliramy123@gmail.com`
   - Password: `ali123`
   - Confirm Password: `ali123`
4. **اضغط** "Register"

**النتيجة المتوقعة:**
- ✅ "Account created successfully"
- ✅ يوجهك تلقائياً لـ Student Portal

---

### المرحلة 2️⃣: إكمال Registration (إذا طُلب منك)

إذا ظهرت صفحة Registration:

1. **أدخل البيانات:**
   - Phone Number: `01234567890`
   - College: `engineering`
   - Grade: `second-year`
   - Major: `computer science`
   - Address: `Cairo, Egypt`
2. **اضغط** "Submit"

**النتيجة المتوقعة:**
- ✅ "Registration completed successfully"

---

### المرحلة 3️⃣: Student Portal - التحقق من البانر

1. **تحقق من البانر (أعلى الصفحة):**

```
╔════════════════════════════════════════════╗
║     Student Account Information            ║
╚════════════════════════════════════════════╝

Full Name:    ali ramy
Email:        aliramy123@gmail.com
Student ID:   STU-XXXXXXXXXXXXX  ← يجب أن يظهر!
College:      engineering
Grade:        second-year
```

**✅ يجب ظهور Student ID (وليس "Not assigned")**

---

### المرحلة 4️⃣: Generate QR Code

1. **في Student Portal**
2. **اضغط** على زر **"Generate QR Code"**
3. **انتظر 2-3 ثوان**

**النتيجة المتوقعة:**
- ✅ نافذة جديدة تفتح
- ✅ QR Code يظهر
- ✅ بيانات الطالب تظهر تحت QR
- ✅ زر "Download QR Code"

**احفظ/صور هذا QR Code - ستحتاجه!**

---

### المرحلة 5️⃣: Logout من حساب الطالب

1. **اضغط** "Logout"
2. **العودة** لصفحة Login

---

### المرحلة 6️⃣: Login كـ Supervisor

1. **في صفحة Login:**
   - Email: `ahmedazab@gmail.com`
   - Password: `supervisor123`
2. **اضغط** "Login"

**النتيجة المتوقعة:**
- ✅ يوجهك لـ Supervisor Dashboard

---

### المرحلة 7️⃣: Supervisor - فتح Shift

1. **في Supervisor Dashboard**
2. **ابحث عن زر** "Open Shift" أو "Start Shift"
3. **اضغط** عليه
4. **اختر:** Morning/Evening shift

**النتيجة المتوقعة:**
- ✅ "Shift opened successfully"
- ✅ Shift Status: Active/Open
- ✅ Shift ID يظهر
- ✅ **Total Scans: 0**

---

### المرحلة 8️⃣: Scan QR Code - تسجيل الحضور

1. **في Supervisor Dashboard**
2. **اذهب لتبويب** "QR Scanner"
3. **اسمح** للكاميرا بالعمل
4. **امسح** QR Code الذي أنشأته في المرحلة 4

**أو:**
- استخدم "Manual Entry" وأدخل Student ID يدوياً

**النتيجة المتوقعة:**
- ✅ رسالة خضراء: "QR Code Scanned Successfully!"
- ✅ الرسالة تختفي بعد **1.5 ثانية**
- ✅ **Total Scans: 1** (يزيد!)
- ✅ اسم الطالب يظهر في الجدول

---

### المرحلة 9️⃣: Refresh - عرض السجلات

1. **اضغط** على زر **"Refresh Shift"** أو **"Refresh"**

**النتيجة المتوقعة:**
- ✅ **جدول Attendance Records** يظهر
- ✅ **ali ramy** يظهر في الجدول
- ✅ **Scan Time** يظهر
- ✅ **College, Grade** تظهر

---

### المرحلة 🔟: Student Details - عرض التفاصيل

1. **في جدول Attendance**
2. **اضغط** على **"Student Details"** بجانب اسم ali ramy

**النتيجة المتوقعة:**
- ✅ Modal/نافذة تفتح
- ✅ **صورة الطالب** (إذا موجودة)
- ✅ **جميع البيانات** تظهر
- ✅ **Attendance Count** يظهر
- ✅ **فورم Payment/Subscription** يظهر

---

### المرحلة 1️⃣1️⃣: دفع اشتراك من Supervisor

1. **في نافذة Student Details**
2. **ابحث عن** "Payment" أو "Subscription Form"
3. **أدخل:**
   - Amount: `500`
   - Payment Method: `Cash`
   - Subscription Type: `Monthly`
4. **اضغط** "Submit Payment"

**النتيجة المتوقعة:**
- ✅ رسالة: "Payment successful" أو "Subscription created"
- ✅ المبلغ: 500 EGP
- ✅ النافذة تغلق

---

### المرحلة 1️⃣2️⃣: التحقق من Student Search

1. **اذهب إلى** `Admin Panel` → **`Student Search`**
2. **ابحث عن:** `ali`

**النتيجة المتوقعة:**
- ✅ **ali ramy** يظهر في النتائج
- ✅ **Attendance Count: 1** (يظهر!)
- ✅ **College, Grade, Email** تظهر
- ✅ يمكن الضغط عليه لعرض التفاصيل

---

### المرحلة 1️⃣3️⃣: التحقق من Admin Subscriptions

1. **اذهب إلى** `Admin Panel` → **`Subscriptions`**

**النتيجة المتوقعة:**
- ✅ **ali ramy** يظهر في القائمة
- ✅ **Amount: 500 EGP**
- ✅ **Type: Monthly**
- ✅ **Status: Active**
- ✅ **Start Date & End Date** تظهر

---

### المرحلة 1️⃣4️⃣: Logout من Supervisor والعودة لـ Student

1. **Logout** من Supervisor
2. **Login** بحساب ali:
   - Email: `aliramy123@gmail.com`
   - Password: `ali123`

---

### المرحلة 1️⃣5️⃣: التحقق من Subscription في Student Portal

1. **في Student Portal**
2. **اذهب لتبويب** "My Subscription" أو "Subscriptions"

**النتيجة المتوقعة:**
- ✅ **Subscription Status: Active**
- ✅ **المبلغ المدفوع: 500 EGP**
- ✅ **Subscription Type: Monthly**
- ✅ **تاريخ البدء** يظهر
- ✅ **تاريخ التجديد** يظهر (30 يوم من الآن)
- ✅ **Remaining Days** يظهر

---

### المرحلة 1️⃣6️⃣: Login كـ Admin والتحقق من Reports

1. **Logout** من Student
2. **Login** كـ Admin (إذا يوجد):
   - Email: `admin@unibus.com` / Password: `admin123`
   
   **أو استخدم Ahmed كـ Admin:**
   - Email: `ahmedazab@gmail.com` / Password: `supervisor123`

3. **اذهب إلى** `Admin Panel` → **`Reports`**

**النتيجة المتوقعة:**
- ✅ **Total Revenue: 500 EGP** (أو أكثر)
- ✅ **Total Students: 5** (أو أكثر)
- ✅ **Total Attendance Records**
- ✅ **Total Subscriptions**
- ✅ **Graphs/Charts** تظهر الإيرادات

---

## ✅ Checklist النهائي:

```
☐ إنشاء حساب جديد
☐ Student ID يظهر في البانر
☐ QR Code يُنشأ بنجاح
☐ Supervisor يفتح Shift
☐ Scan QR يعمل
☐ Total Scans يزيد
☐ Attendance Record يظهر في الجدول
☐ Student Details يفتح
☐ Payment ينجح
☐ Subscription تظهر في Admin
☐ Subscription تظهر في Student Portal
☐ Reports تعرض الإيرادات (500 EGP)
☐ Student Search يعرض الطالب
☐ Attendance Count يظهر في Search
```

---

## 🎊 المشروع مكتمل - جرب الآن!

**ابدأ من المرحلة 1 واتبع الخطوات!**

**إذا واجهت أي مشكلة، أخبرني فوراً!** ✅🚀

---

## 💡 ملاحظات مهمة:

1. **استخدم Incognito Mode** لأول مرة
2. **Hard Refresh** (Ctrl+Shift+R) إذا لم تظهر البيانات
3. **جميع APIs تعمل على السيرفر** - المشكلة فقط Cache
4. **Student ID و QR Code** جاهزان 100%

**🎉 بالتوفيق في العرض!** ✨

