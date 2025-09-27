#!/bin/bash

echo "🔧 Fixing Backend Restart Issue"
echo "=============================="

cd /home/unitrans

# Check current status
echo "📊 Current PM2 status:"
pm2 status

# Check backend logs
echo "📋 Checking backend logs..."
pm2 logs unitrans-backend --lines 20

# Stop and delete all PM2 processes
echo "⏹️ Stopping and deleting all PM2 processes..."
pm2 stop all
pm2 delete all

# Kill any processes on port 3001
echo "🔪 Killing processes on port 3001..."
lsof -ti:3001 | xargs kill -9 2>/dev/null || echo "No processes on port 3001"

# Check backend directory
echo "📁 Checking backend directory..."
cd backend-new
ls -la

# Check package.json
echo "📄 Checking package.json..."
if [ -f "package.json" ]; then
    echo "✅ package.json exists"
    cat package.json | grep -E "(name|version|scripts)"
else
    echo "❌ package.json not found"
    exit 1
fi

# Check environment variables
echo "⚙️ Checking environment variables..."
if [ -f ".env" ]; then
    echo "✅ .env file exists"
    cat .env
else
    echo "❌ .env file not found"
    echo "Creating .env file..."
    cat > .env << 'EOF'
PORT=3001
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans
NODE_ENV=production
JWT_SECRET=your-secret-key-here
EOF
fi

# Install dependencies
echo "📦 Installing backend dependencies..."
npm install

# Check if students.js exists and is valid
echo "🔍 Checking students.js route file..."
if [ -f "routes/students.js" ]; then
    echo "✅ students.js exists"
    # Check for syntax errors
    node -c routes/students.js && echo "✅ Syntax is valid" || echo "❌ Syntax error in students.js"
else
    echo "❌ students.js not found"
fi

# Start backend with PM2
echo "🚀 Starting backend with PM2..."
pm2 start "npm run start" --name "unitrans-backend"

# Wait for backend to start
echo "⏳ Waiting for backend to start..."
sleep 10

# Check PM2 status
echo "📊 Checking PM2 status after start:"
pm2 status

# Test backend health
echo "🏥 Testing backend health..."
for i in {1..5}; do
    echo "Attempt $i..."
    if curl -s http://localhost:3001/api/health; then
        echo "✅ Backend is healthy!"
        break
    else
        echo "❌ Backend not responding, waiting..."
        sleep 5
    fi
done

# Check backend logs again
echo "📋 Checking backend logs after start..."
pm2 logs unitrans-backend --lines 10

# Test QR code generation
echo "🧪 Testing QR code generation..."
curl -X POST http://localhost:3001/api/students/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"studentData":{"_id":"test","studentId":"STU123","fullName":"Test Student","email":"test@example.com"}}' \
  || echo "QR code test failed"

# Start frontend
echo "🚀 Starting frontend..."
cd ../frontend-new
pm2 start "npm run start" --name "unitrans-frontend"

# Wait for frontend to start
sleep 15

# Final status
echo "📊 Final PM2 status:"
pm2 status

echo ""
echo "✅ Backend restart fix completed!"
echo "🌍 Test your project at: https://unibus.online"
echo "📋 Check logs with: pm2 logs"
