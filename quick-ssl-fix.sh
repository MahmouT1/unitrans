#!/bin/bash

echo "🔧 Quick SSL Fix"

cd /home/unitrans

# Update frontend to use HTTP for backend
echo "⚙️ Updating frontend environment..."
cd frontend-new
cat > .env.local << 'EOF'
NEXT_PUBLIC_BACKEND_URL=http://localhost:3001
NEXT_PUBLIC_API_URL=http://localhost:3001/api
NEXT_PUBLIC_FRONTEND_URL=https://unibus.online
EOF

# Update Nginx to proxy API requests
echo "🔧 Updating Nginx..."
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

    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Test and reload
nginx -t && systemctl reload nginx

# Restart services
pm2 stop all
pm2 start server.js --name "unitrans-backend" --cwd backend-new
sleep 10
cd frontend-new
npm run build
pm2 start "npm run start" --name "unitrans-frontend"

echo "✅ Quick SSL fix complete!"
echo "🌍 Test at: https://unibus.online/auth"
