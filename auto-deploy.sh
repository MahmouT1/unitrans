#!/bin/bash

# 🚀 UniBus Auto-Deployment Script for Hostinger VPS
# This script automatically deploys UniBus on Hostinger VPS with Ubuntu and CyberPanel

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration variables
PROJECT_DIR="/var/www/unitrans"
DOMAIN=""
EMAIL=""
MONGO_PASSWORD=""
ADMIN_EMAIL=""
BACKUP_DIR="/backup/unitrans"
LOG_DIR="/var/log/unitrans"

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
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root"
        exit 1
    fi
}

# Function to get user input
get_user_input() {
    print_header "🚀 UniBus Auto-Deployment Setup"
    echo ""
    read -p "Enter your domain name (e.g., yourdomain.com): " DOMAIN
    read -p "Enter your email for SSL: " EMAIL
    read -s -p "Enter MongoDB password: " MONGO_PASSWORD
    echo
    read -p "Enter admin email for alerts: " ADMIN_EMAIL
    echo ""
    print_success "Configuration saved!"
}

# Function to update system
update_system() {
    print_header "📦 Updating System Packages"
    apt update && apt upgrade -y
    apt install -y curl wget git vim htop unzip software-properties-common
    print_success "System updated successfully!"
}

# Function to install Node.js
install_nodejs() {
    print_header "📦 Installing Node.js 18.x"
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
    print_success "Node.js $(node --version) installed successfully!"
}

# Function to install PM2
install_pm2() {
    print_header "📦 Installing PM2"
    npm install -g pm2
    pm2 install pm2-logrotate
    pm2 set pm2-logrotate:max_size 10M
    pm2 set pm2-logrotate:retain 30
    print_success "PM2 installed successfully!"
}

# Function to install MongoDB
install_mongodb() {
    print_header "📦 Installing MongoDB"
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    apt update
    apt install -y mongodb-org
    systemctl start mongod
    systemctl enable mongod
    print_success "MongoDB installed successfully!"
}

# Function to install Nginx
install_nginx() {
    print_header "📦 Installing Nginx"
    apt install -y nginx
    systemctl start nginx
    systemctl enable nginx
    print_success "Nginx installed successfully!"
}

# Function to install SSL tools
install_ssl_tools() {
    print_header "📦 Installing SSL Tools"
    apt install -y certbot python3-certbot-nginx
    print_success "SSL tools installed successfully!"
}

# Function to create project directory
create_project_dir() {
    print_header "📁 Creating Project Directory"
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR
    print_success "Project directory created: $PROJECT_DIR"
}

# Function to clone project
clone_project() {
    print_header "📥 Cloning Project from GitHub"
    git clone https://github.com/MahmouT1/unitrans.git .
    print_success "Project cloned successfully!"
}

# Function to install dependencies
install_dependencies() {
    print_header "📦 Installing Dependencies"
    
    # Backend dependencies
    print_status "Installing backend dependencies..."
    cd backend-new
    npm install
    cd ..
    
    # Frontend dependencies and build
    print_status "Installing frontend dependencies and building..."
    cd frontend-new
    npm install
    npm run build
    cd ..
    
    print_success "Dependencies installed successfully!"
}

# Function to create environment files
create_env_files() {
    print_header "⚙️ Creating Environment Files"
    
    # Backend .env
    cat > backend-new/.env << EOF
PORT=3001
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans
JWT_SECRET=$(openssl rand -base64 32)
NODE_ENV=production
EOF

    # Frontend .env.local
    cat > frontend-new/.env.local << EOF
NEXT_PUBLIC_BACKEND_URL=http://localhost:3001
NEXT_PUBLIC_API_URL=http://localhost:3001/api
NODE_ENV=production
EOF

    print_success "Environment files created successfully!"
}

# Function to create PM2 configuration
create_pm2_config() {
    print_header "⚙️ Creating PM2 Configuration"
    
    cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'unitrans-backend',
      script: './backend-new/server.js',
      cwd: '$PROJECT_DIR',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      error_file: '$LOG_DIR/unitrans-backend-error.log',
      out_file: '$LOG_DIR/unitrans-backend-out.log',
      log_file: '$LOG_DIR/unitrans-backend.log',
      time: true
    },
    {
      name: 'unitrans-frontend',
      script: 'npm',
      args: 'start',
      cwd: '$PROJECT_DIR/frontend-new',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      error_file: '$LOG_DIR/unitrans-frontend-error.log',
      out_file: '$LOG_DIR/unitrans-frontend-out.log',
      log_file: '$LOG_DIR/unitrans-frontend.log',
      time: true
    }
  ]
};
EOF

    print_success "PM2 configuration created successfully!"
}

# Function to start applications
start_applications() {
    print_header "🚀 Starting Applications"
    
    # Create log directory
    mkdir -p $LOG_DIR
    
    # Start applications with PM2
    pm2 start ecosystem.config.js
    pm2 save
    pm2 startup
    
    print_success "Applications started successfully!"
}

# Function to configure Nginx
configure_nginx() {
    print_header "🌐 Configuring Nginx"
    
    cat > /etc/nginx/sites-available/unitrans << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    # Frontend (Next.js)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Static files
    location /_next/static/ {
        proxy_pass http://localhost:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Uploads
    location /uploads/ {
        alias $PROJECT_DIR/frontend-new/public/uploads/;
        expires 1y;
        add_header Cache-Control "public";
    }
}
EOF

    # Enable site
    ln -sf /etc/nginx/sites-available/unitrans /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    nginx -t
    systemctl reload nginx
    
    print_success "Nginx configured successfully!"
}

# Function to setup SSL
setup_ssl() {
    print_header "🔒 Setting up SSL Certificate"
    
    certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive
    
    print_success "SSL certificate installed successfully!"
}

# Function to setup MongoDB
setup_mongodb() {
    print_header "🗄️ Setting up MongoDB"
    
    mongosh --eval "
    use unitrans;
    db.createUser({
      user: 'unitrans_user',
      pwd: '$MONGO_PASSWORD',
      roles: ['readWrite']
    });
    "
    
    print_success "MongoDB configured successfully!"
}

# Function to seed database
seed_database() {
    print_header "🌱 Seeding Database"
    
    cd backend-new
    node scripts/seedData.js
    cd ..
    
    print_success "Database seeded successfully!"
}

# Function to setup firewall
setup_firewall() {
    print_header "🛡️ Setting up Firewall"
    
    ufw --force enable
    ufw allow 22
    ufw allow 80
    ufw allow 443
    ufw allow 3000
    ufw allow 3001
    
    print_success "Firewall configured successfully!"
}

# Function to create monitoring script
create_monitoring() {
    print_header "📊 Setting up Monitoring"
    
    # Create monitoring script
    cat > $PROJECT_DIR/monitor.sh << 'EOF'
#!/bin/bash
DATE=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="/var/log/unitrans-monitor.log"

echo "[$DATE] UniBus System Status" >> $LOG_FILE
echo "================================" >> $LOG_FILE

# Check PM2 status
echo "PM2 Status:" >> $LOG_FILE
pm2 status >> $LOG_FILE

# Check system resources
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)" >> $LOG_FILE
echo "Memory Usage: $(free | grep Mem | awk '{printf "%.2f%%", $3/$2 * 100.0}')" >> $LOG_FILE
echo "Disk Usage: $(df -h / | awk 'NR==2{printf "%s", $5}')" >> $LOG_FILE

# Check application health
curl -s http://localhost:3000 > /dev/null && echo "Frontend: OK" >> $LOG_FILE || echo "Frontend: ERROR" >> $LOG_FILE
curl -s http://localhost:3001/api/health > /dev/null && echo "Backend: OK" >> $LOG_FILE || echo "Backend: ERROR" >> $LOG_FILE
EOF

    chmod +x $PROJECT_DIR/monitor.sh
    
    # Create alert script
    cat > $PROJECT_DIR/alert.sh << EOF
#!/bin/bash
ALERT_EMAIL="$ADMIN_EMAIL"

# Check if applications are running
if ! pm2 status | grep -q "online"; then
    echo "ALERT: UniBus applications are not running!" | mail -s "UniBus Alert" \$ALERT_EMAIL
fi

# Check disk space
DISK_USAGE=\$(df -h / | awk 'NR==2{print \$5}' | cut -d'%' -f1)
if [ \$DISK_USAGE -gt 80 ]; then
    echo "ALERT: Disk usage is at \${DISK_USAGE}%" | mail -s "UniBus Disk Alert" \$ALERT_EMAIL
fi

# Check memory usage
MEMORY_USAGE=\$(free | grep Mem | awk '{printf "%.0f", \$3/\$2 * 100.0}')
if [ \$MEMORY_USAGE -gt 90 ]; then
    echo "ALERT: Memory usage is at \${MEMORY_USAGE}%" | mail -s "UniBus Memory Alert" \$ALERT_EMAIL
fi
EOF

    chmod +x $PROJECT_DIR/alert.sh
    
    # Setup cron jobs
    (crontab -l 2>/dev/null; echo "*/5 * * * * $PROJECT_DIR/monitor.sh") | crontab -
    (crontab -l 2>/dev/null; echo "*/10 * * * * $PROJECT_DIR/alert.sh") | crontab -
    
    print_success "Monitoring setup successfully!"
}

# Function to create backup script
create_backup() {
    print_header "💾 Setting up Backup System"
    
    mkdir -p $BACKUP_DIR/mongodb
    mkdir -p $BACKUP_DIR/unitrans
    
    cat > $PROJECT_DIR/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)

# MongoDB backup
mongodump --db unitrans --out /backup/unitrans/mongodb/$DATE

# Project backup
tar -czf /backup/unitrans/unitrans/unitrans_$DATE.tar.gz /var/www/unitrans

# Keep only last 7 days
find /backup/unitrans/mongodb -type d -mtime +7 -exec rm -rf {} \;
find /backup/unitrans/unitrans -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

    chmod +x $PROJECT_DIR/backup.sh
    
    # Setup backup cron job
    (crontab -l 2>/dev/null; echo "0 2 * * * $PROJECT_DIR/backup.sh") | crontab -
    
    print_success "Backup system setup successfully!"
}

# Function to create update script
create_update_script() {
    print_header "🔄 Creating Update Script"
    
    cat > $PROJECT_DIR/update.sh << 'EOF'
#!/bin/bash
cd /var/www/unitrans
git pull origin main
cd backend-new
npm install
cd ../frontend-new
npm install
npm run build
pm2 restart all
echo "Update completed successfully!"
EOF

    chmod +x $PROJECT_DIR/update.sh
    
    print_success "Update script created successfully!"
}

# Function to create maintenance script
create_maintenance_script() {
    print_header "🔧 Creating Maintenance Script"
    
    cat > $PROJECT_DIR/maintenance.sh << 'EOF'
#!/bin/bash
echo "🔧 Starting UniBus maintenance..."

# Restart services
pm2 restart all

# Clear logs older than 30 days
find /var/log -name "*.log" -mtime +30 -delete

# Clear PM2 logs
pm2 flush

# Update system packages
apt update && apt upgrade -y

# Restart services
systemctl restart nginx
systemctl restart mongod

echo "✅ Maintenance completed successfully!"
EOF

    chmod +x $PROJECT_DIR/maintenance.sh
    
    print_success "Maintenance script created successfully!"
}

# Function to final status check
final_status_check() {
    print_header "✅ Final Status Check"
    
    echo -e "${CYAN}📊 System Status:${NC}"
    pm2 status
    echo ""
    
    echo -e "${CYAN}🌐 Application URLs:${NC}"
    echo "Frontend: http://localhost:3000"
    echo "Backend: http://localhost:3001"
    echo "Production: https://$DOMAIN"
    echo ""
    
    echo -e "${CYAN}📝 Useful Commands:${NC}"
    echo "pm2 status          - Check application status"
    echo "pm2 logs            - View logs"
    echo "pm2 restart all     - Restart applications"
    echo "$PROJECT_DIR/update.sh      - Update application"
    echo "$PROJECT_DIR/backup.sh      - Create backup"
    echo "$PROJECT_DIR/maintenance.sh - Run maintenance"
    echo ""
    
    print_success "UniBus deployment completed successfully!"
    echo -e "${GREEN}🎉 Your application is now live at: https://$DOMAIN${NC}"
}

# Main execution function
main() {
    print_header "🚀 UniBus Auto-Deployment for Hostinger VPS"
    echo ""
    
    # Check if running as root
    check_root
    
    # Get user input
    get_user_input
    
    # System setup
    update_system
    install_nodejs
    install_pm2
    install_mongodb
    install_nginx
    install_ssl_tools
    
    # Project setup
    create_project_dir
    clone_project
    install_dependencies
    create_env_files
    create_pm2_config
    start_applications
    
    # Configuration
    configure_nginx
    setup_ssl
    setup_mongodb
    seed_database
    setup_firewall
    
    # Monitoring and maintenance
    create_monitoring
    create_backup
    create_update_script
    create_maintenance_script
    
    # Final check
    final_status_check
}

# Run main function
main "$@"
