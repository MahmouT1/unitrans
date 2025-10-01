#!/bin/bash

echo "🔄 إعادة تشغيل كامل النظام"
echo "=============================="
echo ""

cd /var/www/unitrans

# 1. إيقاف كل شيء
echo "1. إيقاف جميع الخدمات..."
pm2 stop all
pm2 delete all

# 2. بدء Backend
echo ""
echo "2. بدء Backend..."
cd backend-new
pm2 start server.js --name unitrans-backend
cd ..

sleep 3

# 3. بدء Frontend
echo ""
echo "3. بدء Frontend..."
cd frontend-new

# حذف .next
rm -rf .next

# Build
echo "Building..."
npm run build 2>&1 | tail -20

if [ $? -eq 0 ]; then
    pm2 start npm --name unitrans-frontend -- start
    echo "✅ Production mode"
else
    pm2 start npm --name unitrans-frontend -- run dev
    echo "✅ Dev mode"
fi

cd ..

pm2 save

echo ""
echo "4. انتظار 15 ثانية..."
sleep 15

echo ""
echo "5. اختبار نهائي:"
echo "=============================="

# Test students API
echo ""
echo "Students API:"
curl -s http://localhost:3000/api/students/all?page=1&limit=1 | grep -o '"success":[^,]*'

# Test QR with email
echo ""
echo "QR with email:"
curl -s -X POST http://localhost:3000/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"email":"mahmoudtarekmonaim@gmail.com"}' | grep -o '"success":[^,]*'

# Test QR with studentData
echo ""
echo "QR with studentData:"
curl -s -X POST http://localhost:3000/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentData":{"email":"mahmoudtarekmonaim@gmail.com"}}' | grep -o '"success":[^,]*'

echo ""
echo ""
echo "=============================="
echo "✅ تم إعادة التشغيل!"
echo "=============================="
echo ""
echo "الآن في المتصفح:"
echo "1. أغلق المتصفح تماماً"
echo "2. افتحه من جديد"  
echo "3. اذهب لـ: https://unibus.online/login"
echo "4. سجل دخول وجرب QR Code"
echo ""

pm2 list
