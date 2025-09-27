#!/bin/bash

echo "🔧 Fixing API Proxy Routes"

cd /home/unitrans

# Check if proxy routes exist
echo "🔍 Checking proxy routes..."
ls -la frontend-new/app/api/proxy/ 2>/dev/null || echo "Proxy directory not found"

# Create proxy routes if they don't exist
echo "📁 Creating proxy routes..."
mkdir -p frontend-new/app/api/proxy/auth

# Create login proxy route
cat > frontend-new/app/api/proxy/auth/login/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    
    const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';
    const response = await fetch(`${backendUrl}/api/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const data = await response.json();
    
    return NextResponse.json(data, { status: response.status });
  } catch (error) {
    console.error('Proxy error:', error);
    return NextResponse.json(
      { success: false, message: 'Proxy error: ' + error.message },
      { status: 500 }
    );
  }
}
EOF

# Create register proxy route
cat > frontend-new/app/api/proxy/auth/register/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    
    const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';
    const response = await fetch(`${backendUrl}/api/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const data = await response.json();
    
    return NextResponse.json(data, { status: response.status });
  } catch (error) {
    console.error('Proxy error:', error);
    return NextResponse.json(
      { success: false, message: 'Proxy error: ' + error.message },
      { status: 500 }
    );
  }
}
EOF

# Update Nginx configuration to handle proxy routes
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

    ssl_certificate /etc/letsencrypt/live/unibus.online/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/unibus.online/privkey.pem;

    # API routes - direct to backend
    location /api/auth/ {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API proxy routes - through frontend
    location /api/proxy/ {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Other API routes
    location /api/ {
        proxy_pass http://localhost:3001;
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
    
    # Restart frontend to pick up new routes
    echo "🔄 Restarting frontend..."
    pm2 restart unitrans-frontend
    
    # Wait for frontend to start
    echo "⏳ Waiting for frontend to start..."
    sleep 10
    
    # Test endpoints
    echo "🔍 Testing endpoints..."
    
    # Test direct API
    curl -X POST https://unibus.online/api/auth/login \
      -H "Content-Type: application/json" \
      -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}' \
      && echo "✅ Direct API works" || echo "❌ Direct API failed"
    
    # Test proxy API
    curl -X POST https://unibus.online/api/proxy/auth/login \
      -H "Content-Type: application/json" \
      -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}' \
      && echo "✅ Proxy API works" || echo "❌ Proxy API failed"
    
    echo "✅ API proxy fix complete!"
    echo "🌍 Test your login at: https://unibus.online/auth"
    
else
    echo "❌ Nginx configuration has errors"
fi
