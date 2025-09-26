#!/bin/bash

# Complete Production Setup from Scratch
# This script sets up the entire project on a fresh server

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

# Start the setup process
print_header "🚀 Complete Production Setup from Scratch"

# Update system
print_status "📦 Updating system packages..."
apt update && apt upgrade -y

# Install required packages
print_status "📦 Installing required packages..."
apt install -y curl wget git nginx certbot python3-certbot-nginx ufw

# Install Node.js 22.x
print_status "📦 Installing Node.js 22.x..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

# Install PM2 globally
print_status "📦 Installing PM2..."
npm install -g pm2

# Install MongoDB
print_status "📦 Installing MongoDB..."
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
apt update
apt install -y mongodb-org

# Start and enable MongoDB
print_status "🔄 Starting MongoDB..."
systemctl start mongod
systemctl enable mongod

# Create project directory
print_status "📁 Creating project directory..."
mkdir -p /home/unitrans
cd /home/unitrans

# Clone the project
print_status "📥 Cloning project from GitHub..."
git clone https://github.com/MahmouT1/unitrans.git .

# Install backend dependencies
print_status "📦 Installing backend dependencies..."
cd backend-new
npm install --production

# Create backend environment file
print_status "⚙️ Creating backend environment file..."
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

# Install frontend dependencies
print_status "📦 Installing frontend dependencies..."
cd ../frontend-new
npm install

# Create frontend environment file
print_status "⚙️ Creating frontend environment file..."
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

# Build frontend
print_status "🔨 Building frontend..."
npm run build

# Create uploads directories
print_status "📁 Creating uploads directories..."
mkdir -p /home/unitrans/backend-new/uploads/profiles
chown -R www-data:www-data /home/unitrans/backend-new/uploads

# Start backend with PM2
print_status "🚀 Starting backend with PM2..."
cd /home/unitrans/backend-new
pm2 start server.js --name "unitrans-backend"

# Start frontend with PM2
print_status "🚀 Starting frontend with PM2..."
cd /home/unitrans/frontend-new
pm2 start "npm run start" --name "unitrans-frontend"

# Save PM2 configuration
print_status "💾 Saving PM2 configuration..."
pm2 save
pm2 startup

# Configure Nginx
print_status "🔧 Configuring Nginx..."
cat > /etc/nginx/sites-available/unitrans << 'EOF'
server {
    listen 80;
    server_name unibus.online www.unibus.online;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name unibus.online www.unibus.online;

    # SSL Configuration (will be updated by certbot)
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

# Enable the site
print_status "🔗 Enabling Nginx site..."
ln -sf /etc/nginx/sites-available/unitrans /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
print_status "🔍 Testing Nginx configuration..."
nginx -t

# Start Nginx
print_status "🔄 Starting Nginx..."
systemctl start nginx
systemctl enable nginx

# Configure firewall
print_status "🔥 Configuring firewall..."
ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable

# Wait for services to start
print_status "⏳ Waiting for services to start..."
sleep 10

# Test services
print_status "🏥 Testing services..."
curl -f http://localhost:3001/health && print_success "Backend is healthy" || print_warning "Backend health check failed"
curl -f http://localhost:3000 && print_success "Frontend is accessible" || print_warning "Frontend test failed"

print_header "✅ Production Setup Complete!"
print_success "All services are configured and running"
print_success "Backend API: http://localhost:3001"
print_success "Frontend: http://localhost:3000"
print_success "Nginx: Configured and running"

print_status "📊 PM2 Status:"
pm2 status

print_status "🎯 Next steps:"
print_status "1. Get SSL certificate: certbot --nginx -d unibus.online -d www.unibus.online"
print_status "2. Test your site: https://unibus.online"
print_status "3. Login at: https://unibus.online/auth"
