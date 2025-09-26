# 🚀 دليل رفع مشروع UniBus على VPS Hostinger

## 📋 المتطلبات الأساسية

### 1. متطلبات VPS
- **نظام التشغيل:** Ubuntu 20.04 LTS أو أحدث
- **RAM:** 2GB على الأقل (4GB مفضل)
- **Storage:** 20GB على الأقل
- **CPU:** 2 cores على الأقل

### 2. متطلبات CyberPanel
- CyberPanel مثبت ومُعد
- SSL Certificate مُعد
- Domain مُعد ومُوجه للخادم

## 🔧 إعداد الخادم

### الخطوة 1: الاتصال بالخادم
```bash
ssh root@your-server-ip
```

### الخطوة 2: تحديث النظام
```bash
apt update && apt upgrade -y
```

### الخطوة 3: تثبيت Node.js 18.x
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs
```

### الخطوة 4: تثبيت PM2
```bash
npm install -g pm2
```

### الخطوة 5: تثبيت MongoDB
```bash
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
apt update
apt install -y mongodb-org
systemctl start mongod
systemctl enable mongod
```

### الخطوة 6: تثبيت Nginx
```bash
apt install -y nginx
systemctl start nginx
systemctl enable nginx
```

## 📁 إعداد المشروع

### الخطوة 1: إنشاء مجلد المشروع
```bash
mkdir -p /var/www/unitrans
cd /var/www/unitrans
```

### الخطوة 2: استنساخ المشروع من GitHub
```bash
git clone https://github.com/MahmouT1/unitrans.git .
```

### الخطوة 3: إعداد Backend
```bash
cd backend-new
npm install
```

### الخطوة 4: إعداد Frontend
```bash
cd ../frontend-new
npm install
npm run build
```

## ⚙️ إعداد متغيرات البيئة

### ملف Backend (.env)
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

### ملف Frontend (.env.local)
```bash
cd /var/www/unitrans/frontend-new
nano .env.local
```

```env
NEXT_PUBLIC_BACKEND_URL=http://localhost:3001
NEXT_PUBLIC_API_URL=http://localhost:3001/api
NODE_ENV=production
```

## 🚀 إعداد PM2

### ملف ecosystem.config.js
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

### تشغيل التطبيقات
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

## 🌐 إعداد Nginx

### ملف التكوين
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

### تفعيل الموقع
```bash
ln -s /etc/nginx/sites-available/unitrans /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

## 🔒 إعداد SSL مع Let's Encrypt

### تثبيت Certbot
```bash
apt install -y certbot python3-certbot-nginx
```

### الحصول على شهادة SSL
```bash
certbot --nginx -d your-domain.com -d www.your-domain.com
```

## 🗄️ إعداد قاعدة البيانات

### إنشاء قاعدة البيانات
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

### إضافة بيانات تجريبية
```bash
cd /var/www/unitrans/backend-new
node scripts/seedData.js
```

## 🔧 إعداد CyberPanel

### 1. إنشاء Website في CyberPanel
- اذهب إلى CyberPanel
- اضغط على "Create Website"
- أدخل domain name
- اختر PHP 8.1 أو أحدث

### 2. إعداد SSL
- اذهب إلى "SSL" في CyberPanel
- اضغط على "Let's Encrypt"
- أدخل domain name
- اضغط "Issue"

### 3. إعداد Firewall
- اذهب إلى "Firewall"
- أضف القواعد التالية:
  - Port 3000 (Frontend)
  - Port 3001 (Backend)
  - Port 22 (SSH)
  - Port 80 (HTTP)
  - Port 443 (HTTPS)

## 📊 مراقبة الأداء

### مراقبة PM2
```bash
pm2 status
pm2 logs
pm2 monit
```

### مراقبة النظام
```bash
htop
df -h
free -h
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
```

```bash
chmod +x /var/www/unitrans/update.sh
```

## 🛡️ الأمان

### 1. إعداد Firewall
```bash
ufw enable
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 3000
ufw allow 3001
```

### 2. تحديث النظام
```bash
apt update && apt upgrade -y
```

### 3. نسخ احتياطية
```bash
# نسخة احتياطية لقاعدة البيانات
mongodump --db unitrans --out /backup/mongodb/$(date +%Y%m%d)

# نسخة احتياطية للمشروع
tar -czf /backup/unitrans/$(date +%Y%m%d).tar.gz /var/www/unitrans
```

## 📈 تحسين الأداء

### 1. تحسين MongoDB
```bash
nano /etc/mongod.conf
```

```yaml
storage:
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
```

### 2. تحسين Nginx
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

## 📞 الدعم الفني

في حالة وجود مشاكل:
1. تحقق من السجلات
2. تأكد من حالة الخدمات
3. تحقق من إعدادات Firewall
4. تأكد من صحة SSL Certificate

---

**ملاحظة:** استبدل `your-domain.com` بالدومين الخاص بك و `your-server-ip` بعنوان IP الخاص بخادمك.
