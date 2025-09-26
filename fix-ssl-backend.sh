#!/bin/bash

echo "🔧 Fixing SSL/HTTPS Backend Issue"

cd /home/unitrans

# Update frontend environment to use HTTP for backend
echo "⚙️ Updating frontend environment to use HTTP for backend..."
cd frontend-new
cat > .env.local << 'EOF'
NEXT_PUBLIC_BACKEND_URL=http://localhost:3001
NEXT_PUBLIC_API_URL=http://localhost:3001/api
NEXT_PUBLIC_FRONTEND_URL=https://unibus.online
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans
JWT_SECRET=production-jwt-secret-key-2024
EOF

# Update backend environment
echo "⚙️ Updating backend environment..."
cd ../backend-new
cat > .env << 'EOF'
NODE_ENV=production
PORT=3001
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans
FRONTEND_URL=https://unibus.online
JWT_SECRET=production-jwt-secret-key-2024
API_VERSION=v1
API_PREFIX=/api
LOG_LEVEL=info
CORS_ORIGIN=https://unibus.online
EOF

# Update Nginx to proxy backend requests
echo "🔧 Updating Nginx to proxy backend requests..."
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

    # API routes - proxy to backend
    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3001/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Main app
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
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
    
    # Restart backend
    echo "🔄 Restarting backend..."
    pm2 stop unitrans-backend
    pm2 start server.js --name "unitrans-backend" --cwd backend-new
    
    # Wait for backend
    echo "⏳ Waiting for backend to start..."
    sleep 10
    
    # Restart frontend
    echo "🔄 Restarting frontend..."
    pm2 stop unitrans-frontend
    cd frontend-new
    npm run build
    pm2 start "npm run start" --name "unitrans-frontend"
    
    # Wait for frontend
    echo "⏳ Waiting for frontend to start..."
    sleep 15
    
    # Test API through Nginx proxy
    echo "🔍 Testing API through Nginx proxy..."
    curl -X POST https://unibus.online/api/auth/login \
      -H "Content-Type: application/json" \
      -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}' \
      && echo "✅ API through Nginx works" || echo "❌ API through Nginx failed"
    
    # Test direct backend
    echo "🔍 Testing direct backend..."
    curl -X POST http://localhost:3001/api/auth/login \
      -H "Content-Type: application/json" \
      -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}' \
      && echo "✅ Direct backend works" || echo "❌ Direct backend failed"
    
    echo "✅ SSL/HTTPS backend fix complete!"
    echo "🌍 Test your login at: https://unibus.online/auth"
    
else
    echo "❌ Nginx configuration has errors"
fi
