#!/bin/bash

# Production Update Script for Authentication Fix
# This script updates the production server with the latest authentication fixes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

# Start the update process
print_header "🚀 Production Authentication Update"

# Navigate to project directory
print_status "📁 Navigating to project directory..."
cd /home/unitrans || { print_error "Failed to navigate to project directory"; exit 1; }

# Stop PM2 processes
print_status "⏹️ Stopping PM2 processes..."
pm2 stop all || print_warning "Some PM2 processes may not be running"

# Pull latest changes
print_status "📥 Pulling latest changes from GitHub..."
git pull origin main || { print_error "Failed to pull changes"; exit 1; }

# Update frontend dependencies
print_status "📦 Installing frontend dependencies..."
cd frontend-new
npm install --production=false

# Build frontend
print_status "🔨 Building frontend..."
npm run build

# Update backend dependencies
print_status "📦 Installing backend dependencies..."
cd ../backend-new
npm install --production

# Update environment variables for production
print_status "⚙️ Updating environment configuration..."
cat > .env << EOF
NODE_ENV=production
PORT=3001

# Database Configuration
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans

# CORS Configuration
FRONTEND_URL=https://unibus.online

# JWT Configuration
JWT_SECRET=production-jwt-secret-key-2024

# API Configuration
API_VERSION=v1
API_PREFIX=/api

# Logging
LOG_LEVEL=info
EOF

# Update frontend environment
print_status "⚙️ Updating frontend environment..."
cd ../frontend-new
cat > .env.local << EOF
# Frontend Environment Configuration
NEXT_PUBLIC_BACKEND_URL=https://unibus.online:3001
NEXT_PUBLIC_API_URL=https://unibus.online:3001/api
NEXT_PUBLIC_FRONTEND_URL=https://unibus.online

# Database Configuration (for reference)
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans

# JWT Configuration
JWT_SECRET=production-jwt-secret-key-2024
EOF

# Restart PM2 processes
print_status "🔄 Restarting PM2 processes..."
cd /home/unitrans
pm2 restart all

# Check PM2 status
print_status "📊 Checking PM2 status..."
pm2 status

# Test backend health
print_status "🏥 Testing backend health..."
sleep 5
curl -f http://localhost:3001/health || print_warning "Backend health check failed"

# Test frontend
print_status "🌐 Testing frontend..."
curl -f http://localhost:3000 || print_warning "Frontend test failed"

# Update Nginx configuration for authentication
print_status "🔧 Updating Nginx configuration..."
sudo tee /etc/nginx/sites-available/unitrans > /dev/null << 'EOF'
server {
    listen 80;
    server_name unibus.online www.unibus.online;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name unibus.online www.unibus.online;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/unibus.online/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/unibus.online/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Frontend (Next.js)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3001/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files
    location /uploads/ {
        alias /home/unitrans/backend-new/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /profiles/ {
        alias /home/unitrans/backend-new/uploads/profiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /backend-uploads/ {
        alias /home/unitrans/backend-new/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Test Nginx configuration
print_status "🔍 Testing Nginx configuration..."
sudo nginx -t || { print_error "Nginx configuration test failed"; exit 1; }

# Reload Nginx
print_status "🔄 Reloading Nginx..."
sudo systemctl reload nginx || { print_error "Failed to reload Nginx"; exit 1; }

# Final health checks
print_status "🏥 Running final health checks..."
sleep 10

# Test backend
print_status "🔧 Testing backend API..."
curl -f http://localhost:3001/health && print_success "Backend is healthy" || print_warning "Backend health check failed"

# Test frontend
print_status "🌐 Testing frontend..."
curl -f http://localhost:3000 && print_success "Frontend is accessible" || print_warning "Frontend test failed"

# Test production domain
print_status "🌍 Testing production domain..."
curl -f https://unibus.online && print_success "Production domain is accessible" || print_warning "Production domain test failed"

print_header "✅ Production Update Complete!"
print_success "Authentication system has been updated on production"
print_success "Backend API: https://unibus.online/api/"
print_success "Frontend: https://unibus.online"
print_success "Health Check: https://unibus.online/health"

print_status "📊 PM2 Status:"
pm2 status

print_status "🎯 You can now test login at: https://unibus.online/auth"
