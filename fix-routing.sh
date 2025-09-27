#!/bin/bash

# Fix Routing Issue for API Endpoints
# This script fixes the routing problem for API endpoints

set -e

echo "🔧 Fixing Routing Issue for API Endpoints"

# Navigate to project directory
cd /home/unitrans

# Stop PM2 processes
echo "⏹️ Stopping PM2 processes..."
pm2 stop all

# Update Nginx configuration to fix routing
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

    # Backend API - Priority routing
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
        proxy_connect_timeout 86400;
        proxy_send_timeout 86400;
    }

    # Health check - Direct backend access
    location /health {
        proxy_pass http://localhost:3001/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Frontend (Next.js) - Catch all
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

# Start backend
echo "🚀 Starting backend..."
cd backend-new
pm2 start server.js --name "unitrans-backend"

# Wait for backend
echo "⏳ Waiting for backend to start..."
sleep 10

# Test backend directly
echo "🏥 Testing backend directly..."
curl -f http://localhost:3001/health && echo "✅ Backend is healthy" || echo "❌ Backend health check failed"

# Test backend API directly
echo "🔐 Testing backend API directly..."
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test","role":"student"}' \
  && echo "✅ Backend API working" || echo "❌ Backend API failed"

# Start frontend
echo "🚀 Starting frontend..."
cd ../frontend-new
pm2 start "npm run start" --name "unitrans-frontend"

# Wait for frontend
echo "⏳ Waiting for frontend to start..."
sleep 10

# Test frontend
echo "🌐 Testing frontend..."
curl -f http://localhost:3000 && echo "✅ Frontend is accessible" || echo "❌ Frontend test failed"

# Test through Nginx
echo "🔍 Testing through Nginx..."
curl -f https://unibus.online/health && echo "✅ Health check via HTTPS" || echo "❌ Health check failed"

# Test API through Nginx
echo "🔐 Testing API through Nginx..."
curl -X POST https://unibus.online/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test","role":"student"}' \
  && echo "✅ API via HTTPS working" || echo "❌ API via HTTPS failed"

echo "✅ Routing fix complete!"
echo "🌍 Test your login at: https://unibus.online/auth"
echo "🔐 Backend API: https://unibus.online/api/"
echo "🏥 Health check: https://unibus.online/health"

# Show PM2 status
pm2 status
