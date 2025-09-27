#!/bin/bash

echo "🔧 Fixing Nginx Routing for API Proxy"

# Update Nginx configuration
echo "⚙️ Updating Nginx configuration..."
cat > /etc/nginx/sites-available/unibus.online << 'EOF'
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

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # API Proxy Routes - MUST come before the main location block
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
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
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
    location /_next/static/ {
        alias /home/unitrans/frontend-new/.next/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /uploads/ {
        alias /home/unitrans/uploads/;
        expires 1y;
        add_header Cache-Control "public";
    }

    location /profiles/ {
        alias /home/unitrans/profiles/;
        expires 1y;
        add_header Cache-Control "public";
    }

    location /backend-uploads/ {
        alias /home/unitrans/backend-uploads/;
        expires 1y;
        add_header Cache-Control "public";
    }

    # Main application
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
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
EOF

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    
    # Reload Nginx
    echo "🔄 Reloading Nginx..."
    systemctl reload nginx
    
    # Test API endpoints
    echo "🔍 Testing API endpoints..."
    
    # Test health endpoint
    curl -f https://unibus.online/health && echo "✅ Health endpoint works" || echo "❌ Health endpoint failed"
    
    # Test API proxy
    curl -f https://unibus.online/api/health && echo "✅ API proxy works" || echo "❌ API proxy failed"
    
    # Test login endpoint
    curl -X POST https://unibus.online/api/auth/login \
      -H "Content-Type: application/json" \
      -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}' \
      && echo "✅ Login endpoint works" || echo "❌ Login endpoint failed"
    
    echo "✅ Nginx routing fix complete!"
    echo "🌍 Test your login at: https://unibus.online/auth"
    
else
    echo "❌ Nginx configuration has errors"
    echo "Please check the configuration manually"
fi
