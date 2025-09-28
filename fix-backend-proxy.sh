#!/bin/bash

echo "🔧 إصلاح Backend proxy routes"
echo "============================="

cd /var/www/unitrans

echo "🛑 إيقاف Backend..."
pm2 stop unitrans-backend

echo ""
echo "📝 إضافة proxy routes مباشرة في server.js:"
echo "==========================================="

# التحقق من وجود proxy routes في server.js
if grep -q "/api/login" backend-new/server.js; then
    echo "ℹ️ proxy routes موجودة مسبقاً"
else
    echo "🔧 إضافة proxy routes..."
    
    # إضافة proxy routes قبل السطر الأخير
    sed -i '$i\
\
// ===== FRONTEND AUTH PROXY ROUTES =====\
app.post("/api/login", async (req, res) => {\
  try {\
    console.log("🔄 Frontend Proxy Login:", req.body.email);\
    \
    const { MongoClient } = require("mongodb");\
    const bcrypt = require("bcrypt");\
    const jwt = require("jsonwebtoken");\
    \
    const client = new MongoClient(process.env.MONGODB_URI);\
    await client.connect();\
    const db = client.db(process.env.MONGODB_DB_NAME);\
    const usersCollection = db.collection("users");\
    \
    const user = await usersCollection.findOne({ email: req.body.email });\
    \
    if (!user) {\
      await client.close();\
      return res.status(400).json({ success: false, message: "الحساب غير موجود" });\
    }\
    \
    const validPassword = await bcrypt.compare(req.body.password, user.password);\
    \
    if (!validPassword) {\
      await client.close();\
      return res.status(400).json({ success: false, message: "كلمة المرور غير صحيحة" });\
    }\
    \
    const token = jwt.sign(\
      { userId: user._id, email: user.email, role: user.role },\
      process.env.JWT_SECRET || "fallback-secret",\
      { expiresIn: "24h" }\
    );\
    \
    let redirectUrl;\
    if (user.role === "admin") {\
      redirectUrl = "/admin/dashboard";\
    } else if (user.role === "supervisor") {\
      redirectUrl = "/admin/supervisor-dashboard";\
    } else {\
      redirectUrl = "/student/portal";\
    }\
    \
    await client.close();\
    \
    res.json({\
      success: true,\
      message: "تم تسجيل الدخول بنجاح",\
      token,\
      user: { email: user.email, fullName: user.fullName, role: user.role },\
      redirectUrl\
    });\
    \
  } catch (error) {\
    console.error("❌ Login error:", error);\
    res.status(500).json({ success: false, message: "خطأ في الخادم" });\
  }\
});\
\
app.post("/api/register", async (req, res) => {\
  try {\
    console.log("🔄 Frontend Proxy Register:", req.body.email);\
    \
    const { MongoClient } = require("mongodb");\
    const bcrypt = require("bcrypt");\
    const jwt = require("jsonwebtoken");\
    \
    const client = new MongoClient(process.env.MONGODB_URI);\
    await client.connect();\
    const db = client.db(process.env.MONGODB_DB_NAME);\
    const usersCollection = db.collection("users");\
    \
    const existingUser = await usersCollection.findOne({ email: req.body.email });\
    \
    if (existingUser) {\
      await client.close();\
      return res.status(400).json({ success: false, message: "الحساب موجود مسبقاً" });\
    }\
    \
    const hashedPassword = await bcrypt.hash(req.body.password, 10);\
    \
    const newUser = {\
      email: req.body.email,\
      password: hashedPassword,\
      fullName: req.body.fullName,\
      role: req.body.role || "student",\
      createdAt: new Date(),\
      isActive: true\
    };\
    \
    await usersCollection.insertOne(newUser);\
    \
    const token = jwt.sign(\
      { userId: newUser._id, email: newUser.email, role: newUser.role },\
      process.env.JWT_SECRET || "fallback-secret",\
      { expiresIn: "24h" }\
    );\
    \
    await client.close();\
    \
    res.json({\
      success: true,\
      message: "تم إنشاء الحساب بنجاح",\
      token,\
      user: { email: newUser.email, fullName: newUser.fullName, role: newUser.role },\
      redirectUrl: "/student/portal"\
    });\
    \
  } catch (error) {\
    console.error("❌ Register error:", error);\
    res.status(500).json({ success: false, message: "خطأ في الخادم" });\
  }\
});\
\
console.log("✅ Frontend Auth Proxy Routes Added to Backend");' backend-new/server.js

    echo "✅ تم إضافة proxy routes"
fi

echo ""
echo "🚀 إعادة تشغيل Backend:"
echo "======================"

pm2 start unitrans-backend

echo ""
echo "⏳ انتظار استقرار Backend..."
sleep 8

echo ""
echo "🧪 اختبار Backend الجديد:"
echo "========================"

echo "1️⃣ اختبار Backend proxy route (مباشر):"
curl -X POST http://localhost:3001/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\n📊 Status: %{http_code}\n"

echo ""
echo "2️⃣ اختبار عبر HTTPS domain:"
curl -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\n📊 Status: %{http_code}\n"

echo ""
echo "3️⃣ اختبار Admin login:"
curl -X POST https://unibus.online/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"roo2admin@gmail.com","password":"admin123"}' \
  -w "\n📊 Status: %{http_code}\n"

echo ""
echo "📊 حالة الخدمات:"
pm2 status

echo ""
echo "✅ Backend proxy routes تم تفعيلها!"
echo "🔗 جرب الآن: https://unibus.online/login"
echo ""
echo "🔐 الحسابات الجاهزة:"
echo "==================="
echo "👨‍💼 Admin:      roo2admin@gmail.com / admin123"
echo "👨‍🏫 Supervisor: ahmedazab@gmail.com / supervisor123"
echo "👨‍🎓 Student:    test@test.com / 123456"
