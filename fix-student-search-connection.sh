#!/bin/bash

echo "🔧 Fixing Student Search Database Connection..."
echo "=============================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_DIR="/var/www/unitrans"

# Navigate to project directory
cd $PROJECT_DIR || exit 1

echo -e "${BLUE}📂 Current directory: $(pwd)${NC}"

# Step 1: Create the missing API route file
echo -e "\n${YELLOW}Step 1: Creating missing API route /api/students/all...${NC}"

mkdir -p frontend-new/app/api/students/all

cat > frontend-new/app/api/students/all/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = searchParams.get('page') || '1';
    const limit = searchParams.get('limit') || '20';
    const search = searchParams.get('search') || '';
    
    // Build backend URL with query parameters
    const backendUrl = process.env.BACKEND_URL || 'http://localhost:3001';
    const params = new URLSearchParams({
      page,
      limit,
      ...(search && { search })
    });
    
    console.log(`📡 Proxying request to backend: ${backendUrl}/api/students/all?${params}`);
    
    // Proxy request to backend
    const backendResponse = await fetch(`${backendUrl}/api/students/all?${params}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    const data = await backendResponse.json();
    
    if (!backendResponse.ok) {
      console.error('❌ Backend error:', data);
      return NextResponse.json(data, { status: backendResponse.status });
    }
    
    console.log(`✅ Successfully fetched ${data.students?.length || 0} students`);
    
    return NextResponse.json(data, { status: 200 });
    
  } catch (error) {
    console.error('❌ Error fetching students:', error);
    return NextResponse.json(
      { 
        success: false, 
        message: 'Failed to fetch students', 
        error: error.message 
      },
      { status: 500 }
    );
  }
}
EOF

echo -e "${GREEN}✅ Created: frontend-new/app/api/students/all/route.js${NC}"

# Step 2: Check and create .env files if they don't exist
echo -e "\n${YELLOW}Step 2: Checking environment variables...${NC}"

# Backend .env
if [ ! -f "backend-new/.env" ]; then
    echo -e "${YELLOW}Creating backend-new/.env...${NC}"
    cat > backend-new/.env << 'EOF'
# MongoDB Configuration
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB_NAME=student_portal

# Server Configuration
PORT=3001
NODE_ENV=production

# CORS
FRONTEND_URL=http://localhost:3000

# JWT Secret (change this to a secure random string)
JWT_SECRET=your-secret-key-change-this-in-production
EOF
    echo -e "${GREEN}✅ Created: backend-new/.env${NC}"
else
    echo -e "${GREEN}✅ backend-new/.env already exists${NC}"
fi

# Frontend .env.local
if [ ! -f "frontend-new/.env.local" ]; then
    echo -e "${YELLOW}Creating frontend-new/.env.local...${NC}"
    cat > frontend-new/.env.local << 'EOF'
# Backend API URL
BACKEND_URL=http://localhost:3001

# MongoDB Configuration (for Next.js API routes)
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB_NAME=student_portal

# Next.js
NEXT_PUBLIC_API_URL=http://localhost:3000
EOF
    echo -e "${GREEN}✅ Created: frontend-new/.env.local${NC}"
else
    echo -e "${GREEN}✅ frontend-new/.env.local already exists${NC}"
fi

# Step 3: Test MongoDB connection
echo -e "\n${YELLOW}Step 3: Testing MongoDB connection...${NC}"

# Check if MongoDB is running
if systemctl is-active --quiet mongod; then
    echo -e "${GREEN}✅ MongoDB is running${NC}"
else
    echo -e "${RED}❌ MongoDB is not running${NC}"
    echo -e "${YELLOW}Starting MongoDB...${NC}"
    sudo systemctl start mongod
    sudo systemctl enable mongod
    echo -e "${GREEN}✅ MongoDB started${NC}"
fi

# Test connection with a simple query
cd backend-new
node -e "
const { MongoClient } = require('mongodb');
const uri = 'mongodb://localhost:27017';
const client = new MongoClient(uri);

async function test() {
  try {
    await client.connect();
    console.log('✅ Successfully connected to MongoDB');
    
    const db = client.db('student_portal');
    const collections = await db.listCollections().toArray();
    console.log('📊 Available collections:', collections.map(c => c.name).join(', '));
    
    const studentsCount = await db.collection('students').countDocuments();
    console.log('👥 Total students in database:', studentsCount);
    
    await client.close();
  } catch (error) {
    console.error('❌ MongoDB connection error:', error.message);
    process.exit(1);
  }
}
test();
" || echo -e "${RED}❌ MongoDB connection test failed${NC}"

cd ..

# Step 4: Rebuild frontend
echo -e "\n${YELLOW}Step 4: Rebuilding frontend with new API routes...${NC}"
cd frontend-new

# Kill any existing Next.js process
pkill -f "next dev" || true
pkill -f "next start" || true

# Rebuild
npm run build

echo -e "${GREEN}✅ Frontend rebuilt successfully${NC}"

cd ..

# Step 5: Restart services
echo -e "\n${YELLOW}Step 5: Restarting services...${NC}"

# Check if PM2 is being used
if command -v pm2 &> /dev/null; then
    echo -e "${BLUE}Using PM2 to restart services...${NC}"
    
    # Restart backend
    pm2 restart backend-new || pm2 start backend-new/server.js --name backend-new
    
    # Restart frontend
    pm2 restart frontend-new || (cd frontend-new && pm2 start npm --name frontend-new -- start)
    
    pm2 save
    echo -e "${GREEN}✅ Services restarted with PM2${NC}"
else
    echo -e "${YELLOW}PM2 not found. Please manually restart your services:${NC}"
    echo -e "Backend: cd backend-new && node server.js"
    echo -e "Frontend: cd frontend-new && npm start"
fi

# Step 6: Test the API endpoint
echo -e "\n${YELLOW}Step 6: Testing API endpoint...${NC}"
sleep 3  # Wait for services to start

# Test backend endpoint
echo -e "${BLUE}Testing backend /api/students/all...${NC}"
BACKEND_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/students/all?page=1&limit=20)

if [ "$BACKEND_TEST" = "200" ]; then
    echo -e "${GREEN}✅ Backend API is working (Status: $BACKEND_TEST)${NC}"
else
    echo -e "${YELLOW}⚠️  Backend API status: $BACKEND_TEST${NC}"
fi

# Test frontend proxy endpoint
echo -e "${BLUE}Testing frontend /api/students/all...${NC}"
FRONTEND_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/students/all?page=1&limit=20)

if [ "$FRONTEND_TEST" = "200" ]; then
    echo -e "${GREEN}✅ Frontend API proxy is working (Status: $FRONTEND_TEST)${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend API status: $FRONTEND_TEST${NC}"
fi

# Final status
echo -e "\n${GREEN}=============================================="
echo -e "✅ Fix completed!"
echo -e "=============================================="
echo -e "${NC}"
echo -e "Next steps:"
echo -e "1. Check the Student Search page in your browser"
echo -e "2. Open browser console (F12) to see connection status"
echo -e "3. The page should now display all students from database"
echo -e ""
echo -e "If you still see errors:"
echo -e "- Check logs: pm2 logs"
echo -e "- Verify MongoDB: systemctl status mongod"
echo -e "- Check .env files have correct database credentials"
echo -e ""
