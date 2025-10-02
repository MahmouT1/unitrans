#!/bin/bash

echo "➕ إنشاء Subscriptions Routes البسيطة"
echo "=============================================="
echo ""

cd /var/www/unitrans/backend-new/routes

# Backup
cp subscriptions.js subscriptions.js.backup_mongoose_$(date +%Y%m%d_%H%M%S)

# إنشاء routes بسيطة في بداية الملف
cat > /tmp/simple_sub_routes.js << 'EOF'

// Simple routes using MongoDB directly
const getDatabase = require('../lib/mongodb-simple-connection').getDatabase;

// GET all subscriptions
router.get('/', async (req, res) => {
  try {
    const db = await getDatabase();
    const subscriptions = await db.collection('subscriptions').find().sort({ createdAt: -1 }).toArray();
    
    return res.json({
      success: true,
      subscriptions: subscriptions.map(sub => ({
        id: sub._id.toString(),
        studentEmail: sub.studentEmail,
        studentName: sub.studentName,
        amount: sub.amount,
        subscriptionType: sub.subscriptionType,
        paymentMethod: sub.paymentMethod,
        status: sub.status || 'active',
        createdAt: sub.createdAt
      }))
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// POST create subscription
router.post('/', async (req, res) => {
  try {
    const { studentEmail, studentName, amount, subscriptionType, paymentMethod } = req.body;
    
    if (!studentEmail || !studentName || !amount) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }
    
    const db = await getDatabase();
    
    const newSubscription = {
      studentEmail: studentEmail.toLowerCase(),
      studentName,
      amount: parseFloat(amount),
      subscriptionType: subscriptionType || 'monthly',
      paymentMethod: paymentMethod || 'cash',
      status: 'active',
      startDate: new Date(),
      endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    const result = await db.collection('subscriptions').insertOne(newSubscription);
    
    console.log('✅ Subscription created:', result.insertedId);
    
    return res.json({
      success: true,
      message: 'Subscription created successfully',
      subscription: {
        id: result.insertedId.toString(),
        ...newSubscription
      }
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

EOF

# إضافة الـ routes الجديدة في بداية الملف (بعد const router)
LINE=$(grep -n "const router = express.Router();" subscriptions.js | cut -d: -f1)

if [ -n "$LINE" ]; then
    head -n $LINE subscriptions.js > /tmp/sub_part1.js
    cat /tmp/simple_sub_routes.js >> /tmp/sub_part1.js
    tail -n +$((LINE + 1)) subscriptions.js >> /tmp/sub_part1.js
    mv /tmp/sub_part1.js subscriptions.js
    
    echo "✅ تم إضافة Simple Routes"
else
    echo "❌ لم أجد const router"
    exit 1
fi

echo ""

# إعادة تشغيل Backend
cd /var/www/unitrans
pm2 restart unitrans-backend
pm2 save

sleep 3

echo ""
echo "=============================================="
echo "اختبار Subscriptions:"
echo "=============================================="

TOKEN=$(curl -s -X POST http://localhost:3001/auth-api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmedazab@gmail.com","password":"supervisor123"}' \
  | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')

# GET
echo ""
echo "GET /api/subscriptions:"
curl -s "http://localhost:3001/api/subscriptions" \
  -H "Authorization: Bearer $TOKEN"

echo ""
echo ""

# POST
echo "POST /api/subscriptions:"
curl -s -X POST "http://localhost:3001/api/subscriptions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "studentEmail":"aliramy123@gmail.com",
    "studentName":"ali ramy",
    "amount":500,
    "subscriptionType":"monthly",
    "paymentMethod":"cash"
  }'

echo ""
echo ""
echo "✅ تم!"
