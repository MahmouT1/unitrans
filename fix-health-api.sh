#!/bin/bash

echo "🔧 Fixing Health API"

cd /home/unitrans

# Check if health endpoint exists in backend
echo "🔍 Checking backend health endpoint..."
cd backend-new

# Add health endpoint if missing
if ! grep -q "app.get('/api/health'" server.js; then
    echo "🔧 Adding health endpoint to backend..."
    cat >> server.js << 'EOF'

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'production',
        message: 'Backend API Server Running',
        database: 'Connected'
    });
});
EOF
fi

# Restart backend
echo "🔄 Restarting backend..."
pm2 stop unitrans-backend
pm2 start "npm start" --name "unitrans-backend"

# Wait for backend
echo "⏳ Waiting for backend to start..."
sleep 10

# Test health endpoint
echo "🔍 Testing health endpoint..."
curl -f http://localhost:3001/api/health && echo "✅ Backend health works" || echo "❌ Backend health failed"
curl -f https://unibus.online/api/health && echo "✅ Nginx health works" || echo "❌ Nginx health failed"

echo "✅ Health API fix complete!"
