#!/bin/bash

echo "🔧 Fixing CORS and Environment Issues"

cd /home/unitrans

# Update frontend environment
echo "⚙️ Updating frontend environment..."
cd frontend-new
cat > .env.local << 'EOF'
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

# Add CORS middleware to backend
echo "🔧 Adding CORS middleware to backend..."
cat > cors-config.js << 'EOF'
const cors = require('cors');

const corsOptions = {
  origin: [
    'https://unibus.online',
    'https://www.unibus.online',
    'http://localhost:3000',
    'http://localhost:3001'
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

module.exports = cors(corsOptions);
EOF

# Update server.js to use CORS
echo "🔧 Updating server.js to use CORS..."
if ! grep -q "cors" server.js; then
  # Add CORS import at the top
  sed -i '1i const cors = require("cors");' server.js
  
  # Add CORS middleware after express initialization
  sed -i '/const app = express();/a app.use(cors({\n  origin: ["https://unibus.online", "https://www.unibus.online", "http://localhost:3000"],\n  credentials: true,\n  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],\n  allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"]\n}));' server.js
fi

# Install cors if not installed
echo "📦 Installing CORS package..."
npm install cors

# Stop and restart backend
echo "🔄 Restarting backend..."
pm2 stop unitrans-backend
pm2 start server.js --name "unitrans-backend"

# Wait for backend
echo "⏳ Waiting for backend to start..."
sleep 10

# Stop and restart frontend
echo "🔄 Restarting frontend..."
pm2 stop unitrans-frontend
cd ../frontend-new
npm run build
pm2 start "npm run start" --name "unitrans-frontend"

# Wait for frontend
echo "⏳ Waiting for frontend to start..."
sleep 15

# Test CORS
echo "🔍 Testing CORS..."
curl -H "Origin: https://unibus.online" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     https://unibus.online:3001/api/auth/login \
     && echo "✅ CORS preflight works" || echo "❌ CORS preflight failed"

# Test login
echo "🔍 Testing login..."
curl -X POST https://unibus.online:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -H "Origin: https://unibus.online" \
  -d '{"email":"sona123@gmail.com","password":"sona123","role":"student"}' \
  && echo "✅ Login works" || echo "❌ Login failed"

echo "✅ CORS and environment fix complete!"
echo "🌍 Test your login at: https://unibus.online/auth"
