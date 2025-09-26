# 🚀 دليل الرفع الشامل لمشروع UniBus على VPS Hostinger

## 📋 نظرة عامة

هذا الدليل يوضح كيفية رفع مشروع UniBus على VPS Hostinger مع Ubuntu Linux وCyberPanel بطريقة احترافية.

## 🎯 المتطلبات الأساسية

### 1. متطلبات VPS
- **نظام التشغيل:** Ubuntu 20.04 LTS أو أحدث
- **RAM:** 4GB على الأقل (8GB مفضل)
- **Storage:** 50GB على الأقل
- **CPU:** 2 cores على الأقل
- **Bandwidth:** غير محدود

### 2. متطلبات CyberPanel
- CyberPanel مثبت ومُعد
- SSL Certificate مُعد
- Domain مُعد ومُوجه للخادم

## 🔧 الخطوات التفصيلية

### المرحلة 1: إعداد الخادم الأساسي

#### 1.1 الاتصال بالخادم
```bash
ssh root@your-server-ip
```

#### 1.2 تحديث النظام
```bash
apt update && apt upgrade -y
apt install -y curl wget git vim htop
```

#### 1.3 تثبيت Node.js 18.x
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs
node --version
npm --version
```

#### 1.4 تثبيت PM2
```bash
npm install -g pm2
pm2 --version
```

#### 1.5 تثبيت MongoDB
```bash
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
apt update
apt install -y mongodb-org
systemctl start mongod
systemctl enable mongod
```

#### 1.6 تثبيت Nginx
```bash
apt install -y nginx
systemctl start nginx
systemctl enable nginx
```

### المرحلة 2: إعداد المشروع

#### 2.1 إنشاء مجلد المشروع
```bash
mkdir -p /var/www/unitrans
cd /var/www/unitrans
```

#### 2.2 استنساخ المشروع
```bash
git clone https://github.com/MahmouT1/unitrans.git .
```

#### 2.3 إعداد Backend
```bash
cd backend-new
npm install
```

#### 2.4 إعداد Frontend
```bash
cd ../frontend-new
npm install
npm run build
```

### المرحلة 3: إعداد متغيرات البيئة

#### 3.1 ملف Backend (.env)
```bash
cd /var/www/unitrans/backend-new
nano .env
```

```env
PORT=3001
MONGODB_URI=mongodb://localhost:27017
DB_NAME=unitrans
JWT_SECRET=your-super-secret-jwt-key-here
NODE_ENV=production
```

#### 3.2 ملف Frontend (.env.local)
```bash
cd /var/www/unitrans/frontend-new
nano .env.local
```

```env
NEXT_PUBLIC_BACKEND_URL=http://localhost:3001
NEXT_PUBLIC_API_URL=http://localhost:3001/api
NODE_ENV=production
```

### المرحلة 4: إعداد PM2

#### 4.1 ملف ecosystem.config.js
```bash
cd /var/www/unitrans
nano ecosystem.config.js
```

```javascript
module.exports = {
  apps: [
    {
      name: 'unitrans-backend',
      script: './backend-new/server.js',
      cwd: '/var/www/unitrans',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      error_file: '/var/log/pm2/unitrans-backend-error.log',
      out_file: '/var/log/pm2/unitrans-backend-out.log',
      log_file: '/var/log/pm2/unitrans-backend.log',
      time: true
    },
    {
      name: 'unitrans-frontend',
      script: 'npm',
      args: 'start',
      cwd: '/var/www/unitrans/frontend-new',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      error_file: '/var/log/pm2/unitrans-frontend-error.log',
      out_file: '/var/log/pm2/unitrans-frontend-out.log',
      log_file: '/var/log/pm2/unitrans-frontend.log',
      time: true
    }
  ]
};
```

#### 4.2 تشغيل التطبيقات
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### المرحلة 5: إعداد Nginx

#### 5.1 ملف التكوين
```bash
nano /etc/nginx/sites-available/unitrans
```

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

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
    }

    # Static files
    location /_next/static/ {
        proxy_pass http://localhost:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Uploads
    location /uploads/ {
        alias /var/www/unitrans/frontend-new/public/uploads/;
        expires 1y;
        add_header Cache-Control "public";
    }
}
```

#### 5.2 تفعيل الموقع
```bash
ln -s /etc/nginx/sites-available/unitrans /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
```

### المرحلة 6: إعداد SSL

#### 6.1 تثبيت Certbot
```bash
apt install -y certbot python3-certbot-nginx
```

#### 6.2 الحصول على شهادة SSL
```bash
certbot --nginx -d your-domain.com -d www.your-domain.com
```

### المرحلة 7: إعداد قاعدة البيانات

#### 7.1 إنشاء قاعدة البيانات
```bash
mongosh
```

```javascript
use unitrans
db.createUser({
  user: "unitrans_user",
  pwd: "your-secure-password",
  roles: ["readWrite"]
})
```

#### 7.2 إضافة بيانات تجريبية
```bash
cd /var/www/unitrans/backend-new
node scripts/seedData.js
```

### المرحلة 8: إعداد CyberPanel

#### 8.1 إنشاء Website
1. اذهب إلى CyberPanel
2. اضغط على "Create Website"
3. أدخل domain name
4. اختر PHP 8.1 أو أحدث

#### 8.2 إعداد SSL
1. اذهب إلى "SSL" في CyberPanel
2. اضغط على "Let's Encrypt"
3. أدخل domain name
4. اضغط "Issue"

#### 8.3 إعداد Firewall
1. اذهب إلى "Firewall"
2. أضف القواعد التالية:
   - Port 3000 (Frontend)
   - Port 3001 (Backend)
   - Port 22 (SSH)
   - Port 80 (HTTP)
   - Port 443 (HTTPS)

### المرحلة 9: إعداد المراقبة

#### 9.1 تثبيت أدوات المراقبة
```bash
apt install -y htop iotop nethogs nload iftop
npm install -g pm2-logrotate
pm2 install pm2-server-monit
```

#### 9.2 إعداد سكريبت المراقبة
```bash
nano /var/www/unitrans/monitor.sh
```

```bash
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
```

```bash
chmod +x /var/www/unitrans/monitor.sh
```

#### 9.3 إعداد Cron Jobs
```bash
(crontab -l 2>/dev/null; echo "*/5 * * * * /var/www/unitrans/monitor.sh") | crontab -
```

### المرحلة 10: إعداد النسخ الاحتياطية

#### 10.1 سكريبت النسخ الاحتياطية
```bash
nano /var/www/unitrans/backup.sh
```

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)

# MongoDB backup
mongodump --db unitrans --out /backup/mongodb/$DATE

# Project backup
tar -czf /backup/unitrans/unitrans_$DATE.tar.gz /var/www/unitrans

# Keep only last 7 days
find /backup/mongodb -type d -mtime +7 -exec rm -rf {} \;
find /backup/unitrans -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

```bash
chmod +x /var/www/unitrans/backup.sh
mkdir -p /backup/mongodb /backup/unitrans
```

#### 10.2 إعداد النسخ الاحتياطية التلقائية
```bash
(crontab -l 2>/dev/null; echo "0 2 * * * /var/www/unitrans/backup.sh") | crontab -
```

### المرحلة 11: إعداد الأمان

#### 11.1 إعداد Firewall
```bash
ufw enable
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 3000
ufw allow 3001
```

#### 11.2 تحديث النظام
```bash
apt update && apt upgrade -y
```

#### 11.3 إعداد Fail2Ban
```bash
apt install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban
```

### المرحلة 12: تحسين الأداء

#### 12.1 تحسين MongoDB
```bash
nano /etc/mongod.conf
```

```yaml
storage:
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
```

#### 12.2 تحسين Nginx
```bash
nano /etc/nginx/nginx.conf
```

```nginx
worker_processes auto;
worker_connections 1024;

gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
```

#### 12.3 تحسين PM2
```bash
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 30
```

## 🔄 تحديث المشروع

### سكريبت التحديث
```bash
nano /var/www/unitrans/update.sh
```

```bash
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
```

```bash
chmod +x /var/www/unitrans/update.sh
```

## 🚨 استكشاف الأخطاء

### 1. فحص الحالة
```bash
pm2 status
systemctl status nginx
systemctl status mongod
```

### 2. فحص السجلات
```bash
pm2 logs unitrans-backend
pm2 logs unitrans-frontend
tail -f /var/log/nginx/error.log
```

### 3. فحص المنافذ
```bash
netstat -tlnp
```

## ✅ التحقق من النجاح

### 1. فحص الخدمات
```bash
curl http://localhost:3000
curl http://localhost:3001/api/health
```

### 2. فحص SSL
```bash
curl -I https://your-domain.com
```

### 3. فحص قاعدة البيانات
```bash
mongosh unitrans --eval "db.stats()"
```

## 📊 مراقبة الأداء

### 1. مراقبة PM2
```bash
pm2 status
pm2 logs
pm2 monit
```

### 2. مراقبة النظام
```bash
htop
df -h
free -h
```

### 3. مراقبة الشبكة
```bash
nload
iftop
```

## 🔧 الصيانة الدورية

### 1. تحديث النظام
```bash
apt update && apt upgrade -y
```

### 2. تنظيف السجلات
```bash
pm2 flush
find /var/log -name "*.log" -mtime +30 -delete
```

### 3. إعادة تشغيل الخدمات
```bash
pm2 restart all
systemctl restart nginx
systemctl restart mongod
```

## 📞 الدعم الفني

في حالة وجود مشاكل:
1. تحقق من السجلات
2. تأكد من حالة الخدمات
3. تحقق من إعدادات Firewall
4. تأكد من صحة SSL Certificate

---

**ملاحظة:** استبدل `your-domain.com` بالدومين الخاص بك و `your-server-ip` بعنوان IP الخاص بخادمك.
