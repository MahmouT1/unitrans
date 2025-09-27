#!/bin/bash

echo "🔧 Quick CORS Fix"

cd /home/unitrans

# Update frontend environment
echo "⚙️ Updating frontend environment..."
cd frontend-new
cat > .env.local << 'EOF'
NEXT_PUBLIC_BACKEND_URL=https://unibus.online:3001
NEXT_PUBLIC_API_URL=https://unibus.online:3001/api
NEXT_PUBLIC_FRONTEND_URL=https://unibus.online
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
CORS_ORIGIN=https://unibus.online
EOF

# Install CORS
npm install cors

# Add CORS to server.js
echo "🔧 Adding CORS to server.js..."
if ! grep -q "cors" server.js; then
  sed -i '1i const cors = require("cors");' server.js
  sed -i '/const app = express();/a app.use(cors({\n  origin: ["https://unibus.online", "https://www.unibus.online"],\n  credentials: true\n}));' server.js
fi

# Restart services
echo "🔄 Restarting services..."
pm2 stop all
pm2 start server.js --name "unitrans-backend" --cwd backend-new
sleep 10
cd frontend-new
npm run build
pm2 start "npm run start" --name "unitrans-frontend"

echo "✅ Quick CORS fix complete!"
echo "🌍 Test at: https://unibus.online/auth"
