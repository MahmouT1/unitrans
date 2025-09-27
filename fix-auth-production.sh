#!/bin/bash

# Fix Authentication on Production Server
# This script fixes authentication issues on production

set -e

echo "🔐 Fixing Authentication on Production Server"

# Navigate to project directory
cd /home/unitrans

# Stop PM2 processes
echo "⏹️ Stopping PM2 processes..."
pm2 stop all

# Check MongoDB status
echo "📊 Checking MongoDB status..."
systemctl status mongod --no-pager -l
systemctl start mongod
systemctl enable mongod

# Test MongoDB connection
echo "🔍 Testing MongoDB connection..."
mongosh --eval "db.runCommand('ping')" || echo "MongoDB connection test failed"

# Check if database exists and has data
echo "📋 Checking database and collections..."
mongosh --eval "
use unitrans;
db.users.find().limit(1).pretty();
db.users.countDocuments();
" || echo "Database check failed"

# Update frontend environment for production
echo "⚙️ Updating frontend environment..."
cd frontend-new
cat > .env.local << EOF
NEXT_PUBLIC_BACKEND_URL=https://unibus.online:3001
NEXT_PUBLIC_API_URL=https://unibus.online:3001/api
NEXT_PUBLIC_FRONTEND_URL=https://unibus.online
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans
JWT_SECRET=production-jwt-secret-key-2024
EOF

# Update backend environment
echo "⚙️ Updating backend environment..."
cd ../backend-new
cat > .env << EOF
NODE_ENV=production
PORT=3001
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans
FRONTEND_URL=https://unibus.online
JWT_SECRET=production-jwt-secret-key-2024
API_VERSION=v1
API_PREFIX=/api
LOG_LEVEL=info
EOF

# Create uploads directory
echo "📁 Creating uploads directory..."
mkdir -p uploads/profiles
chown -R www-data:www-data uploads

# Start backend first
echo "🚀 Starting backend..."
pm2 start server.js --name "unitrans-backend"

# Wait for backend to start
echo "⏳ Waiting for backend to start..."
sleep 10

# Test backend health
echo "🏥 Testing backend health..."
curl -f http://localhost:3001/health && echo "✅ Backend is healthy" || echo "❌ Backend health check failed"

# Test backend API endpoints
echo "🔍 Testing backend API endpoints..."
curl -f http://localhost:3001/api/auth/login -X POST -H "Content-Type: application/json" -d '{"email":"test","password":"test","role":"student"}' || echo "Auth endpoint test failed"

# Start frontend
echo "🚀 Starting frontend..."
cd ../frontend-new
pm2 start "npm run start" --name "unitrans-frontend"

# Wait for frontend to start
echo "⏳ Waiting for frontend to start..."
sleep 15

# Test frontend
echo "🌐 Testing frontend..."
curl -f http://localhost:3000 && echo "✅ Frontend is accessible" || echo "❌ Frontend test failed"

# Update Nginx configuration for backend access
echo "🔧 Updating Nginx configuration..."
sudo tee /etc/nginx/sites-available/unitrans > /dev/null << 'EOF'
server {
    listen 80;
    server_name unibus.online www.unibus.online;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name unibus.online www.unibus.online;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/unibus.online/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/unibus.online/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

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

    # Backend API - Direct access
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

    # Backend direct access on port 3001
    location /backend/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3001/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files
    location /uploads/ {
        alias /home/unitrans/backend-new/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /profiles/ {
        alias /home/unitrans/backend-new/uploads/profiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /backend-uploads/ {
        alias /home/unitrans/backend-new/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Test Nginx configuration
echo "🔍 Testing Nginx configuration..."
nginx -t

# Reload Nginx
echo "🔄 Reloading Nginx..."
systemctl reload nginx

# Final tests
echo "🏥 Running final tests..."
sleep 5

# Test backend through Nginx
echo "🔧 Testing backend through Nginx..."
curl -f https://unibus.online/health && echo "✅ Backend accessible via HTTPS" || echo "❌ Backend HTTPS test failed"

# Test frontend
echo "🌐 Testing frontend..."
curl -f https://unibus.online && echo "✅ Frontend accessible via HTTPS" || echo "❌ Frontend HTTPS test failed"

# Test API endpoint
echo "🔍 Testing API endpoint..."
curl -f https://unibus.online/api/auth/login -X POST -H "Content-Type: application/json" -d '{"email":"test","password":"test","role":"student"}' && echo "✅ API endpoint accessible" || echo "❌ API endpoint test failed"

echo "✅ Authentication fix complete!"
echo "🌍 Test your login at: https://unibus.online/auth"
echo "🔐 Backend API: https://unibus.online/api/"
echo "🏥 Health check: https://unibus.online/health"

# Show PM2 status
echo "📊 PM2 Status:"
pm2 status
