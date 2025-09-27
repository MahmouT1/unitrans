#!/bin/bash

# Quick Routing Fix
# This script quickly fixes the routing issue

set -e

echo "🔧 Quick Routing Fix"

# Navigate to project directory
cd /home/unitrans

# Update Nginx configuration
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

    # Backend API - Priority routing
    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
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

    # Frontend (Next.js)
    location / {
        proxy_pass http://localhost:3000;
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
}
EOF

# Test and reload Nginx
echo "🔍 Testing Nginx configuration..."
nginx -t

echo "🔄 Reloading Nginx..."
systemctl reload nginx

# Test the fix
echo "🏥 Testing the fix..."
sleep 5

# Test health check
curl -f https://unibus.online/health && echo "✅ Health check working" || echo "❌ Health check failed"

# Test API endpoint
curl -X POST https://unibus.online/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test","role":"student"}' \
  && echo "✅ API endpoint working" || echo "❌ API endpoint failed"

echo "✅ Quick routing fix complete!"
echo "🌍 Test your login at: https://unibus.online/auth"
