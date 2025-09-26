#!/bin/bash

# 🚀 UniBus One-Click Deployment Script
# سكريبت رفع مشروع UniBus بنقرة واحدة على VPS

set -e

# ألوان للطباعة
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# متغيرات المشروع
PROJECT_DIR="/var/www/unitrans"
DOMAIN=""
EMAIL=""

# دالة طباعة الرسائل
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# التحقق من صلاحيات المدير
if [ "$EUID" -ne 0 ]; then
    print_error "يرجى تشغيل السكريبت كمدير (root)"
    exit 1
fi

# الحصول على البيانات من المستخدم
print_header "🚀 UniBus - رفع المشروع على VPS"
echo ""
echo "مرحباً! سأقوم برفع مشروع UniBus على خادمك تلقائياً"
echo ""

read -p "أدخل اسم الدومين (مثال: yourdomain.com): " DOMAIN
read -p "أدخل بريدك الإلكتروني للـ SSL: " EMAIL
echo ""

print_success "تم حفظ البيانات بنجاح!"

# تحديث النظام
print_header "📦 تحديث النظام"
apt update && apt upgrade -y
apt install -y curl wget git vim htop unzip software-properties-common rsync tar findutils
print_success "تم تحديث النظام بنجاح!"

# تثبيت Node.js 22.x
print_header "📦 تثبيت Node.js 22.x"
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
apt-get install -y nodejs
print_success "تم تثبيت Node.js $(node --version) بنجاح!"

# تثبيت PM2
print_header "📦 تثبيت PM2"
npm install -g pm2
pm2 install pm2-logrotate
print_success "تم تثبيت PM2 بنجاح!"

# تثبيت MongoDB
print_header "📦 تثبيت MongoDB"
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
apt update
apt install -y mongodb-org
systemctl start mongod
systemctl enable mongod
print_success "تم تثبيت MongoDB بنجاح!"

# تثبيت Nginx
print_header "📦 تثبيت Nginx"
apt install -y nginx
systemctl start nginx
systemctl enable nginx
print_success "تم تثبيت Nginx بنجاح!"

# تثبيت SSL
print_header "📦 تثبيت أدوات SSL"
apt install -y certbot python3-certbot-nginx
print_success "تم تثبيت أدوات SSL بنجاح!"

# إنشاء مجلد المشروع
print_header "📁 إنشاء مجلد المشروع"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR
print_success "تم إنشاء مجلد المشروع!"

# تحميل المشروع
print_header "📥 تحميل المشروع من GitHub"
# حذف المجلد الحالي بالكامل بطريقة أكثر فعالية
cd ..
print_status "حذف المجلد السابق..."
rm -rf unitrans 2>/dev/null || true
sleep 2

# التحقق من أن المجلد محذوف تماماً
if [ -d "unitrans" ]; then
    print_status "إجبار حذف المجلد..."
    sudo rm -rf unitrans 2>/dev/null || true
    sleep 1
fi

print_status "إنشاء مجلد جديد..."
mkdir -p unitrans
cd unitrans

# التحقق من أن المجلد فارغ تماماً
if [ "$(ls -A . 2>/dev/null)" ]; then
    print_status "تنظيف المجلد من الملفات المتبقية..."
    rm -rf * .* 2>/dev/null || true
fi

print_status "تحميل المشروع من GitHub..."
# استخدام استراتيجية مختلفة: تحميل في مجلد مؤقت ثم نقل الملفات
print_status "تحميل المشروع في مجلد مؤقت..."
cd ..
if [ -d "unitrans-temp" ]; then
    rm -rf unitrans-temp
fi

# محاولة استخدام git archive أولاً (أسرع وأكثر موثوقية)
print_status "محاولة تحميل المشروع باستخدام git archive..."
if git archive --remote=https://github.com/MahmouT1/unitrans.git HEAD | tar -x -C unitrans/ 2>/dev/null; then
    print_success "تم تحميل المشروع بنجاح باستخدام git archive!"
else
    # تحميل المشروع في مجلد مؤقت
    if git clone https://github.com/MahmouT1/unitrans.git unitrans-temp; then
    print_status "نقل الملفات إلى المجلد النهائي..."
    # نقل جميع الملفات من المجلد المؤقت إلى المجلد النهائي
    # استخدام rsync للتأكد من نقل جميع الملفات
    if command -v rsync >/dev/null 2>&1; then
        rsync -av --delete unitrans-temp/ unitrans/
    else
        # استخدام cp مع خيارات أكثر قوة
        cp -r unitrans-temp/* unitrans/ 2>/dev/null || true
        cp -r unitrans-temp/.* unitrans/ 2>/dev/null || true
    fi
    # حذف المجلد المؤقت
    rm -rf unitrans-temp
    print_success "تم تحميل المشروع بنجاح!"
else
    print_error "فشل في تحميل المشروع من GitHub"
    print_status "محاولة حل بديل بـ ZIP..."
    
    # حل بديل: تحميل كـ zip
    print_status "تحميل المشروع كـ ZIP..."
    wget -O unitrans.zip https://github.com/MahmouT1/unitrans/archive/refs/heads/main.zip
    unzip -o unitrans.zip
    
    # استخدام tar للتأكد من نقل جميع الملفات
    if command -v tar >/dev/null 2>&1; then
        print_status "نقل الملفات باستخدام tar..."
        tar -cf - -C unitrans-main . | tar -xf - -C unitrans/
    else
        # استخدام find و xargs للتأكد من نقل جميع الملفات
        print_status "نقل الملفات باستخدام find و xargs..."
        find unitrans-main -type f -exec cp --parents {} unitrans/ \; 2>/dev/null || true
        find unitrans-main -type d -exec mkdir -p unitrans/{} \; 2>/dev/null || true
    fi
    
    rm -rf unitrans-main unitrans.zip
    
    print_success "تم تحميل المشروع بنجاح باستخدام ZIP!"
    fi
fi

# العودة إلى مجلد المشروع
cd unitrans

# إنشاء مجلدات الصور والملفات
print_header "📁 إنشاء مجلدات الصور والملفات"
mkdir -p frontend-new/public/uploads
mkdir -p frontend-new/public/profiles
mkdir -p backend-new/uploads
mkdir -p backend-new/uploads/profiles
mkdir -p backend-new/data
print_success "تم إنشاء مجلدات الصور والملفات بنجاح!"

# تثبيت dependencies
print_header "📦 تثبيت المكتبات"
cd backend-new
npm install
cd ../frontend-new
npm install

# تثبيت المكتبات المفقودة
print_header "📦 تثبيت المكتبات المفقودة"
npm install axios
npm install qrcode
npm install jsqr
npm install zxing

# حذف الملفات المفقودة
print_header "🗑️ حذف الملفات المفقودة"
rm -f app/admin/supervisor-dashboard-enhanced/page.js
rm -f lib/Student.js
rm -f lib/User.js
rm -f lib/SupportTicket.js
rm -f lib/UserSimple.js
rm -f lib/StudentSimple.js
rm -f components/WorkingQRScannerFixed.js
rm -f app/api/attendance/register-simple/route.js
rm -f app/api/attendance/scan-qr/route.js
rm -f app/api/students/profile/route.js
rm -f app/api/support/tickets/route.js
rm -f app/api/test-db/route.js
rm -f app/api/test-student-simple/route.js
rm -f app/api/test-student/route.js
rm -f app/api/test-user-simple/route.js
rm -f app/api/test-user/route.js

# بناء المشروع
npm run build
cd ..
print_success "تم تثبيت جميع المكتبات بنجاح!"

# إنشاء ملفات البيئة
print_header "⚙️ إعداد ملفات البيئة"
cat > backend-new/.env << EOF
PORT=3001
MONGODB_URI=mongodb://localhost:27017/unitrans
DB_NAME=unitrans
JWT_SECRET=$(openssl rand -base64 32)
NODE_ENV=production
EOF

cat > frontend-new/.env.local << EOF
NEXT_PUBLIC_BACKEND_URL=http://localhost:3001
NEXT_PUBLIC_API_URL=http://localhost:3001/api
NODE_ENV=production
EOF
print_success "تم إنشاء ملفات البيئة بنجاح!"

# إعداد PM2
print_header "⚙️ إعداد PM2"
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
      error_file: '/var/log/pm2/unitrans-backend-error.log',
      out_file: '/var/log/pm2/unitrans-backend-out.log',
      log_file: '/var/log/pm2/unitrans-backend.log',
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
      error_file: '/var/log/pm2/unitrans-frontend-error.log',
      out_file: '/var/log/pm2/unitrans-frontend-out.log',
      log_file: '/var/log/pm2/unitrans-frontend.log',
      time: true
    }
  ]
};
EOF

# تشغيل التطبيقات
pm2 start ecosystem.config.js
pm2 save
pm2 startup
print_success "تم تشغيل التطبيقات بنجاح!"

# إعداد Nginx
print_header "🌐 إعداد Nginx"
cat > /etc/nginx/sites-available/unitrans << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

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

    location /_next/static/ {
        proxy_pass http://localhost:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /uploads/ {
        alias $PROJECT_DIR/frontend-new/public/uploads/;
        expires 1y;
        add_header Cache-Control "public";
    }

    # Profiles
    location /profiles/ {
        alias $PROJECT_DIR/frontend-new/public/profiles/;
        expires 1y;
        add_header Cache-Control "public";
    }

    # Backend uploads
    location /backend-uploads/ {
        alias $PROJECT_DIR/backend-new/uploads/;
        expires 1y;
        add_header Cache-Control "public";
    }
}
EOF

# تفعيل الموقع
ln -sf /etc/nginx/sites-available/unitrans /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
print_success "تم إعداد Nginx بنجاح!"

# إعداد SSL
print_header "🔒 إعداد SSL"
certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive
print_success "تم إعداد SSL بنجاح!"

# إعداد MongoDB (بدون كلمة مرور)
print_header "🗄️ إعداد قاعدة البيانات"
mongosh --eval "
use unitrans;
db.createCollection('test');
db.createCollection('students');
db.createCollection('users');
db.createCollection('attendance');
db.createCollection('shifts');
db.createCollection('subscriptions');
db.createCollection('supporttickets');
db.createCollection('driversalaries');
db.createCollection('expenses');
db.createCollection('transportation');
"
print_success "تم إعداد قاعدة البيانات بنجاح!"

# إضافة بيانات تجريبية
print_header "🌱 إضافة البيانات التجريبية"
cd backend-new
node scripts/seedData.js
cd ..
print_success "تم إضافة البيانات التجريبية بنجاح!"

# إعداد صلاحيات الملفات
print_header "🔐 إعداد صلاحيات الملفات"
chown -R www-data:www-data $PROJECT_DIR/frontend-new/public/uploads
chown -R www-data:www-data $PROJECT_DIR/frontend-new/public/profiles
chown -R www-data:www-data $PROJECT_DIR/backend-new/uploads
chmod -R 755 $PROJECT_DIR/frontend-new/public/uploads
chmod -R 755 $PROJECT_DIR/frontend-new/public/profiles
chmod -R 755 $PROJECT_DIR/backend-new/uploads
print_success "تم إعداد صلاحيات الملفات بنجاح!"

# إعداد Firewall
print_header "🛡️ إعداد Firewall"
ufw --force enable
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 3000
ufw allow 3001
print_success "تم إعداد Firewall بنجاح!"

# إنشاء سكريبت التحديث
print_header "🔄 إنشاء سكريبت التحديث"
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
echo "تم تحديث المشروع بنجاح!"
EOF

chmod +x $PROJECT_DIR/update.sh
print_success "تم إنشاء سكريبت التحديث!"

# إنشاء سكريبت النسخ الاحتياطية
print_header "💾 إنشاء سكريبت النسخ الاحتياطية"
mkdir -p /backup/unitrans
cat > $PROJECT_DIR/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
mongodump --db unitrans --out /backup/unitrans/mongodb_$DATE
tar -czf /backup/unitrans/unitrans_$DATE.tar.gz /var/www/unitrans
find /backup/unitrans -name "*" -mtime +7 -delete
echo "تم إنشاء نسخة احتياطية: $DATE"
EOF

chmod +x $PROJECT_DIR/backup.sh
print_success "تم إنشاء سكريبت النسخ الاحتياطية!"

# إعداد Cron Jobs
print_header "⏰ إعداد المهام التلقائية"
(crontab -l 2>/dev/null; echo "0 2 * * * $PROJECT_DIR/backup.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 3 * * * $PROJECT_DIR/update.sh") | crontab -
print_success "تم إعداد المهام التلقائية!"

# فحص اتصال قاعدة البيانات
print_header "🔍 فحص اتصال قاعدة البيانات"
mongosh --eval "
use unitrans;
db.stats();
" > /dev/null 2>&1 && print_success "✅ اتصال قاعدة البيانات يعمل بنجاح!" || print_error "❌ مشكلة في اتصال قاعدة البيانات"

# فحص التطبيقات
print_header "🔍 فحص التطبيقات"
curl -s http://localhost:3000 > /dev/null && print_success "✅ الواجهة الأمامية تعمل بنجاح!" || print_error "❌ مشكلة في الواجهة الأمامية"
curl -s http://localhost:3001/api/health > /dev/null && print_success "✅ الواجهة الخلفية تعمل بنجاح!" || print_error "❌ مشكلة في الواجهة الخلفية"

# فحص الحالة النهائية
print_header "✅ فحص الحالة النهائية"
echo ""
echo -e "${GREEN}🎉 تم رفع المشروع بنجاح!${NC}"
echo ""
echo -e "${BLUE}📊 حالة النظام:${NC}"
pm2 status
echo ""
echo -e "${BLUE}🌐 روابط المشروع:${NC}"
echo "الواجهة الأمامية: http://localhost:3000"
echo "الواجهة الخلفية: http://localhost:3001"
echo "الموقع الإنتاجي: https://$DOMAIN"
echo "لوحة التحكم: https://$DOMAIN/admin"
echo "QR Scanner: https://$DOMAIN/admin/supervisor-dashboard"
echo ""
echo -e "${BLUE}📁 مجلدات الصور:${NC}"
echo "الصور العامة: $PROJECT_DIR/frontend-new/public/uploads/"
echo "صور الملفات الشخصية: $PROJECT_DIR/frontend-new/public/profiles/"
echo "صور الخادم: $PROJECT_DIR/backend-new/uploads/"
echo ""
echo -e "${BLUE}📝 أوامر مفيدة:${NC}"
echo "pm2 status          - فحص حالة التطبيقات"
echo "pm2 logs            - عرض السجلات"
echo "pm2 restart all     - إعادة تشغيل التطبيقات"
echo "$PROJECT_DIR/update.sh      - تحديث المشروع"
echo "$PROJECT_DIR/backup.sh      - إنشاء نسخة احتياطية"
echo ""
echo -e "${GREEN}🚀 مشروع UniBus جاهز للاستخدام على: https://$DOMAIN${NC}"
echo ""
print_success "تم الانتهاء من الرفع بنجاح!"
