#!/bin/bash

echo "🚀 UNIBUS VPS DEPLOYMENT - COMPLETE FIX"
echo "========================================="

# Navigate to project directory
cd /home/unitrans

echo "📥 Step 1: Pulling latest changes from GitHub..."
git fetch origin
git reset --hard origin/main
git pull origin main

echo "🔧 Step 2: Stopping all running services..."
pkill -f node || true
pkill -f npm || true
sleep 2

echo "🔧 Step 3: Installing backend dependencies..."
cd backend-new
npm install
cd ..

echo "🔧 Step 4: Installing frontend dependencies..."
cd frontend-new
npm install
cd ..

echo "🔧 Step 5: Setting up database users..."
cd backend-new
cat > setup-users.js << 'EOF'
const { MongoClient } = require('mongodb');

async function setupUsers() {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
    const dbName = process.env.MONGODB_DB_NAME || 'student_portal';
    
    const client = new MongoClient(mongoUri);
    await client.connect();
    const db = client.db(dbName);
    
    console.log('🔗 Connected to database:', dbName);
    
    // Production users
    const users = [
      {
        email: 'admin@unibus.com',
        password: 'admin123',
        fullName: 'System Administrator',
        role: 'admin',
        isActive: true,
        createdAt: new Date()
      },
      {
        email: 'supervisor@unibus.com', 
        password: 'supervisor123',
        fullName: 'System Supervisor',
        role: 'supervisor',
        isActive: true,
        createdAt: new Date()
      },
      {
        email: 'student@unibus.com',
        password: 'student123', 
        fullName: 'Test Student',
        role: 'student',
        isActive: true,
        createdAt: new Date()
      },
      {
        email: 'test@test.com',
        password: '123456',
        fullName: 'Test User',
        role: 'student', 
        isActive: true,
        createdAt: new Date()
      },
      {
        email: 'rozan@gmail.com',
        password: 'roz123',
        fullName: 'Rozan User',
        role: 'student', 
        isActive: true,
        createdAt: new Date()
      }
    ];
    
    // Clear and recreate users
    await db.collection('users').deleteMany({
      email: { $in: users.map(u => u.email) }
    });
    
    const result = await db.collection('users').insertMany(users);
    console.log('✅ Created', result.insertedCount, 'users');
    
    // Create student records
    for (const user of users) {
      if (user.role === 'student') {
        await db.collection('students').deleteOne({ email: user.email });
        await db.collection('students').insertOne({
          fullName: user.fullName,
          email: user.email,
          phoneNumber: '',
          college: 'University College',
          grade: 'Bachelor',
          major: 'Computer Science',
          address: {},
          attendanceCount: 0,
          isActive: true,
          createdAt: new Date()
        });
      }
    }
    
    console.log('✅ Setup complete!');
    await client.close();
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

setupUsers();
EOF

node setup-users.js
cd ..

echo "🔧 Step 6: Creating environment file..."
cat > .env << 'EOF'
NODE_ENV=production
PORT=3001
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB_NAME=student_portal

NEXT_PUBLIC_BACKEND_URL=https://unibus.online
NEXT_PUBLIC_FRONTEND_URL=https://unibus.online

JWT_SECRET=unibus-production-secret-2024
SESSION_SECRET=unibus-session-secret-2024
EOF

echo "🔧 Step 7: Building frontend..."
cd frontend-new
npm run build
cd ..

echo "🔧 Step 8: Starting backend service..."
cd backend-new
nohup node server.js > ../logs/backend.log 2>&1 &
sleep 3
cd ..

echo "🔧 Step 9: Starting frontend service..."
cd frontend-new
nohup npm start > ../logs/frontend.log 2>&1 &
sleep 5
cd ..

echo "🔧 Step 10: Updating Nginx configuration..."
cat > /etc/nginx/sites-available/unibus.online << 'EOF'
server {
    listen 80;
    server_name unibus.online www.unibus.online;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name unibus.online www.unibus.online;

    ssl_certificate /etc/letsencrypt/live/unibus.online/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/unibus.online/privkey.pem;

    # CORS headers
    add_header Access-Control-Allow-Origin "https://unibus.online" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Accept, Authorization, Cache-Control, Content-Type, DNT, If-Modified-Since, Keep-Alive, Origin, User-Agent, X-Requested-With" always;

    # Handle preflight requests
    if ($request_method = 'OPTIONS') {
        add_header Access-Control-Allow-Origin "https://unibus.online";
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Accept, Authorization, Cache-Control, Content-Type, DNT, If-Modified-Since, Keep-Alive, Origin, User-Agent, X-Requested-With";
        add_header Access-Control-Max-Age 1728000;
        add_header Content-Type "text/plain; charset=utf-8";
        add_header Content-Length 0;
        return 204;
    }

    # Proxy routes (through Next.js)
    location /api/proxy/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }

    # Direct API routes (to backend)
    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3001/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Frontend (Next.js)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }

    # Static files
    location /uploads/ {
        alias /home/unitrans/backend-new/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

echo "🔧 Step 11: Testing and reloading Nginx..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration valid"
    systemctl reload nginx
    echo "✅ Nginx reloaded"
else
    echo "❌ Nginx configuration error!"
    exit 1
fi

echo "🔧 Step 12: Creating logs directory..."
mkdir -p logs

echo "🧪 Step 13: Testing all endpoints..."

echo "Testing backend health..."
curl -s http://localhost:3001/health | jq '.status' || echo "❌ Backend health failed"

echo "Testing direct auth..."
AUTH_RESULT=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}')
echo $AUTH_RESULT | jq '.success' || echo "❌ Direct auth failed"

echo "Testing proxy auth..."
sleep 2
PROXY_RESULT=$(curl -s -X POST http://localhost:3000/api/proxy/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}')
echo $PROXY_RESULT | jq '.success' || echo "❌ Proxy auth failed"

echo "🎉 DEPLOYMENT COMPLETE!"
echo "================================"
echo "📋 Test Accounts:"
echo "  • admin@unibus.com / admin123 (admin)"
echo "  • supervisor@unibus.com / supervisor123 (supervisor)"
echo "  • student@unibus.com / student123 (student)"
echo "  • test@test.com / 123456 (student)"
echo "  • rozan@gmail.com / roz123 (student)"
echo ""
echo "🌍 Access: https://unibus.online"
echo "🔐 Login: https://unibus.online/auth"
echo ""
echo "📊 Check logs:"
echo "  tail -f logs/backend.log"
echo "  tail -f logs/frontend.log"
echo ""
echo "🔄 If issues persist, run:"
echo "  systemctl status nginx"
echo "  ps aux | grep node"
