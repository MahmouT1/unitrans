#!/bin/bash

echo "🔧 Quick localhost Fix"

cd /home/unitrans/frontend-new

# Update environment
cat > .env.local << 'EOF'
NEXT_PUBLIC_BACKEND_URL=https://unibus.online
NEXT_PUBLIC_API_URL=https://unibus.online/api
NEXT_PUBLIC_FRONTEND_URL=https://unibus.online
EOF

# Replace localhost references
find . -name "*.js" -o -name "*.jsx" | xargs sed -i 's|http://localhost:3001|https://unibus.online|g'
find . -name "*.js" -o -name "*.jsx" | xargs sed -i 's|localhost:3001|unibus.online|g'

# Rebuild and restart
npm run build
pm2 stop unitrans-frontend
pm2 start "npm run start" --name "unitrans-frontend"

echo "✅ Quick localhost fix complete!"
echo "🌍 Test at: https://unibus.online/admin"
