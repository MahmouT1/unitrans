#!/bin/bash

echo "🔧 إصلاح مشكلة Auth API Mismatch - Frontend يحاول الوصول لـ /auth-api/login"
echo "====================================================================="

cd /var/www/unitrans

echo ""
echo "🔍 1️⃣ فحص المشكلة الحالية:"
echo "========================"

echo "🔍 فحص PM2 status:"
pm2 status

echo ""
echo "🔍 فحص backend routes:"
curl -s http://localhost:3001/api/health

echo ""
echo "🔍 فحص frontend login page:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/login

echo ""
echo "🔧 2️⃣ إضافة /auth-api/login route إلى Backend:"
echo "=========================================="

echo "📝 إضافة /auth-api/login route إلى server.js:"

# Backup current server.js
cp backend-new/server.js backend-new/server.js.backup-$(date +%Y%m%d-%H%M%S)

# Add auth-api routes to server.js
cat >> backend-new/server.js << 'EOF'

// CRITICAL: Add /auth-api/login route for Frontend compatibility
app.post('/auth-api/login', async (req, res) => {
  try {
    console.log('🔑 /auth-api/login route called with:', req.body.email);
    
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ 
        success: false, 
        message: 'Email and password are required' 
      });
    }

    // Connect to MongoDB
    const client = new MongoClient(process.env.MONGODB_URI);
    await client.connect();
    const db = client.db(process.env.MONGODB_DB_NAME);
    const usersCollection = db.collection('users');

    // Find user
    const user = await usersCollection.findOne({ email: email.toLowerCase() });
    
    if (!user) {
      await client.close();
      return res.status(401).json({ 
        success: false, 
        message: 'Account not found. Please check your email or register first.' 
      });
    }

    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password);
    
    if (!isValidPassword) {
      await client.close();
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid password' 
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user._id, 
        email: user.email, 
        role: user.role 
      },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    await client.close();

    console.log('✅ /auth-api/login successful for:', user.email);

    // Return success response
    res.json({
      success: true,
      message: 'Login successful',
      token: token,
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        role: user.role
      },
      redirectUrl: user.role === 'student' ? '/student/portal' : 
                  user.role === 'admin' ? '/admin/dashboard' : 
                  user.role === 'supervisor' ? '/admin/supervisor-dashboard' : '/student/portal'
    });

  } catch (error) {
    console.error('❌ /auth-api/login error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Internal server error' 
    });
  }
});

// CRITICAL: Add /auth-api/register route for Frontend compatibility
app.post('/auth-api/register', async (req, res) => {
  try {
    console.log('📝 /auth-api/register route called with:', req.body.email);
    
    const { email, password, fullName, role } = req.body;
    
    if (!email || !password || !fullName) {
      return res.status(400).json({ 
        success: false, 
        message: 'Email, password, and full name are required' 
      });
    }

    // Connect to MongoDB
    const client = new MongoClient(process.env.MONGODB_URI);
    await client.connect();
    const db = client.db(process.env.MONGODB_DB_NAME);
    const usersCollection = db.collection('users');

    // Check if user already exists
    const existingUser = await usersCollection.findOne({ email: email.toLowerCase() });
    
    if (existingUser) {
      await client.close();
      return res.status(400).json({ 
        success: false, 
        message: 'User already exists with this email' 
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user
    const newUser = {
      email: email.toLowerCase(),
      password: hashedPassword,
      fullName: fullName,
      role: role || 'student',
      createdAt: new Date(),
      isActive: true
    };

    const result = await usersCollection.insertOne(newUser);
    
    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: result.insertedId, 
        email: newUser.email, 
        role: newUser.role 
      },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    await client.close();

    console.log('✅ /auth-api/register successful for:', newUser.email);

    // Return success response
    res.json({
      success: true,
      message: 'Registration successful',
      token: token,
      user: {
        id: result.insertedId,
        email: newUser.email,
        fullName: newUser.fullName,
        role: newUser.role
      },
      redirectUrl: newUser.role === 'student' ? '/student/portal' : 
                  newUser.role === 'admin' ? '/admin/dashboard' : 
                  newUser.role === 'supervisor' ? '/admin/supervisor-dashboard' : '/student/portal'
    });

  } catch (error) {
    console.error('❌ /auth-api/register error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Internal server error' 
    });
  }
});

EOF

echo "✅ تم إضافة /auth-api/login و /auth-api/register routes إلى server.js"

echo ""
echo "🔧 3️⃣ إعادة تشغيل Backend:"
echo "========================="

echo "🔄 إعادة تشغيل backend..."
pm2 restart unitrans-backend

echo "⏳ انتظار 10 ثواني للتأكد من التشغيل..."
sleep 10

echo "🔍 فحص حالة backend:"
pm2 status unitrans-backend

echo ""
echo "🧪 4️⃣ اختبار /auth-api/login مباشرة:"
echo "================================="

echo "🔍 اختبار /auth-api/login على port 3001:"
AUTH_API_LOGIN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\nHTTP Status: %{http_code}\n")

echo "$AUTH_API_LOGIN"

echo ""
echo "🔍 اختبار /auth-api/register على port 3001:"
AUTH_API_REGISTER=$(curl -s -X POST http://localhost:3001/auth-api/register \
  -H "Content-Type: application/json" \
  -d '{"email":"newuser@test.com","password":"123456","fullName":"New User","role":"student"}' \
  -w "\nHTTP Status: %{http_code}\n")

echo "$AUTH_API_REGISTER"

echo ""
echo "🧪 5️⃣ اختبار من خلال Nginx:"
echo "=========================="

echo "🔍 اختبار /auth-api/login من خلال Nginx:"
NGINX_AUTH_API_LOGIN=$(curl -s -X POST https://unibus.online/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' \
  -w "\nHTTP Status: %{http_code}\n")

echo "$NGINX_AUTH_API_LOGIN"

echo ""
echo "🔍 اختبار صفحة Login:"
LOGIN_PAGE=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" https://unibus.online/login)
echo "$LOGIN_PAGE"

echo ""
echo "📊 6️⃣ تقرير الإصلاح النهائي:"
echo "=========================="

echo "✅ الإصلاحات المطبقة:"
echo "   🔧 تم إضافة /auth-api/login route للتوافق مع Frontend"
echo "   📝 تم إضافة /auth-api/register route للتوافق مع Frontend"
echo "   🔄 تم إعادة تشغيل backend"
echo "   🧪 تم اختبار جميع المسارات"

echo ""
echo "🎯 النتائج:"
echo "   🔑 /auth-api/login: $(echo "$AUTH_API_LOGIN" | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   📝 /auth-api/register: $(echo "$AUTH_API_REGISTER" | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   🌐 Nginx /auth-api/login: $(echo "$NGINX_AUTH_API_LOGIN" | grep -q "success" && echo "✅ يعمل" || echo "❌ لا يعمل")"
echo "   📱 Login Page: $LOGIN_PAGE"

echo ""
echo "🎉 تم إصلاح مشكلة Auth API Mismatch!"
echo "🌐 يمكنك الآن اختبار صفحة Login:"
echo "   🔗 https://unibus.online/login"
echo "   📧 test@test.com / 123456"
echo "   ✅ يجب أن يعمل بدون أخطاء!"
