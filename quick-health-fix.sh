#!/bin/bash

echo "🔧 Quick Health Fix"

cd /home/unitrans/backend-new

# Add health endpoint
echo "app.get('/api/health', (req, res) => { res.json({ status: 'OK', timestamp: new Date().toISOString() }); });" >> server.js

# Restart backend
pm2 restart unitrans-backend

# Test
sleep 5
curl -f https://unibus.online/api/health && echo "✅ Health works" || echo "❌ Health failed"

echo "✅ Quick health fix complete!"
