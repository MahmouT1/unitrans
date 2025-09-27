#!/bin/bash

echo "🔧 Fixing localhost references in frontend"

cd /home/unitrans

# Update frontend environment to use relative URLs
echo "⚙️ Updating frontend environment..."
cd frontend-new
cat > .env.local << 'EOF'
NEXT_PUBLIC_BACKEND_URL=https://unibus.online
NEXT_PUBLIC_API_URL=https://unibus.online/api
NEXT_PUBLIC_FRONTEND_URL=https://unibus.online
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans
JWT_SECRET=production-jwt-secret-key-2024
EOF

# Find and replace localhost references in frontend code
echo "🔍 Finding localhost references in frontend code..."
find . -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" | xargs grep -l "localhost:3001" | head -10

# Replace localhost:3001 with relative URLs
echo "🔧 Replacing localhost:3001 with relative URLs..."
find . -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" | xargs sed -i 's|http://localhost:3001|https://unibus.online|g'
find . -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" | xargs sed -i 's|localhost:3001|unibus.online|g'

# Update API service to use relative URLs
echo "🔧 Updating API service..."
if [ -f "services/api.js" ]; then
    sed -i 's|http://localhost:3001|https://unibus.online|g' services/api.js
    sed -i 's|localhost:3001|unibus.online|g' services/api.js
fi

# Update config files
echo "🔧 Updating config files..."
if [ -f "config/api.js" ]; then
    sed -i 's|http://localhost:3001|https://unibus.online|g' config/api.js
    sed -i 's|localhost:3001|unibus.online|g' config/api.js
fi

# Update all API route files
echo "🔧 Updating API route files..."
find app/api -name "*.js" | xargs sed -i 's|http://localhost:3001|https://unibus.online|g'
find app/api -name "*.js" | xargs sed -i 's|localhost:3001|unibus.online|g'

# Update components
echo "🔧 Updating components..."
find components -name "*.js" -o -name "*.jsx" | xargs sed -i 's|http://localhost:3001|https://unibus.online|g'
find components -name "*.js" -o -name "*.jsx" | xargs sed -i 's|localhost:3001|unibus.online|g'

# Update app pages
echo "🔧 Updating app pages..."
find app -name "*.js" -o -name "*.jsx" | xargs sed -i 's|http://localhost:3001|https://unibus.online|g'
find app -name "*.js" -o -name "*.jsx" | xargs sed -i 's|localhost:3001|unibus.online|g'

# Rebuild frontend
echo "🏗️ Rebuilding frontend..."
npm run build

# Restart frontend
echo "🔄 Restarting frontend..."
pm2 stop unitrans-frontend
pm2 start "npm run start" --name "unitrans-frontend"

# Wait for frontend
echo "⏳ Waiting for frontend to start..."
sleep 15

# Test API calls
echo "🔍 Testing API calls..."
curl -f https://unibus.online/api/health && echo "✅ Health API works" || echo "❌ Health API failed"
curl -f https://unibus.online/api/admin/students && echo "✅ Students API works" || echo "❌ Students API failed"

echo "✅ localhost references fix complete!"
echo "🌍 Test your admin pages at: https://unibus.online/admin"
