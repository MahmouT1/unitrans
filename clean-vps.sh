#!/bin/bash

# 🧹 سكريبت تنظيف VPS الشامل
# هذا السكريبت ينظف VPS تماماً قبل رفع مشروع UniBus

set -e

# ألوان للطباعة
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# دالة طباعة الرسائل
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

# التحقق من صلاحيات المدير
if [ "$EUID" -ne 0 ]; then
    print_error "يرجى تشغيل السكريبت كمدير (root)"
    exit 1
fi

print_header "🧹 تنظيف VPS الشامل"
echo ""
echo "تحذير: هذا السكريبت سيقوم بحذف جميع البيانات والخدمات الموجودة!"
echo "تأكد من أنك تريد المتابعة..."
echo ""
read -p "هل أنت متأكد؟ اكتب 'yes' للمتابعة: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_error "تم إلغاء العملية"
    exit 1
fi

# إيقاف جميع الخدمات
print_header "🛑 إيقاف جميع الخدمات"
systemctl stop nginx 2>/dev/null || true
systemctl stop apache2 2>/dev/null || true
systemctl stop mongod 2>/dev/null || true
systemctl stop mysql 2>/dev/null || true
systemctl stop postgresql 2>/dev/null || true
systemctl stop redis 2>/dev/null || true
systemctl stop memcached 2>/dev/null || true
print_success "تم إيقاف جميع الخدمات"

# إيقاف PM2
print_header "🛑 إيقاف PM2"
pm2 kill 2>/dev/null || true
print_success "تم إيقاف PM2"

# حذف التطبيقات الموجودة
print_header "🗑️ حذف التطبيقات الموجودة"
rm -rf /var/www/* 2>/dev/null || true
rm -rf /home/*/public_html/* 2>/dev/null || true
rm -rf /opt/* 2>/dev/null || true
print_success "تم حذف التطبيقات"

# حذف قواعد البيانات
print_header "🗑️ حذف قواعد البيانات"
systemctl stop mongod 2>/dev/null || true
rm -rf /var/lib/mongodb/* 2>/dev/null || true
systemctl stop mysql 2>/dev/null || true
rm -rf /var/lib/mysql/* 2>/dev/null || true
systemctl stop postgresql 2>/dev/null || true
rm -rf /var/lib/postgresql/* 2>/dev/null || true
print_success "تم حذف قواعد البيانات"

# حذف ملفات Nginx
print_header "🗑️ حذف ملفات Nginx"
rm -rf /etc/nginx/sites-enabled/* 2>/dev/null || true
rm -rf /etc/nginx/sites-available/* 2>/dev/null || true
rm -rf /var/log/nginx/* 2>/dev/null || true
print_success "تم حذف ملفات Nginx"

# حذف ملفات Apache
print_header "🗑️ حذف ملفات Apache"
rm -rf /etc/apache2/sites-enabled/* 2>/dev/null || true
rm -rf /etc/apache2/sites-available/* 2>/dev/null || true
rm -rf /var/log/apache2/* 2>/dev/null || true
print_success "تم حذف ملفات Apache"

# حذف ملفات SSL
print_header "🗑️ حذف ملفات SSL"
rm -rf /etc/letsencrypt/* 2>/dev/null || true
rm -rf /etc/ssl/certs/* 2>/dev/null || true
rm -rf /etc/ssl/private/* 2>/dev/null || true
print_success "تم حذف ملفات SSL"

# حذف ملفات السجلات
print_header "🗑️ حذف ملفات السجلات"
rm -rf /var/log/* 2>/dev/null || true
mkdir -p /var/log
touch /var/log/syslog
print_success "تم حذف ملفات السجلات"

# حذف ملفات PM2
print_header "🗑️ حذف ملفات PM2"
rm -rf ~/.pm2/* 2>/dev/null || true
rm -rf /root/.pm2/* 2>/dev/null || true
print_success "تم حذف ملفات PM2"

# حذف Node.js و npm
print_header "🗑️ حذف Node.js و npm"
apt remove --purge -y nodejs npm 2>/dev/null || true
rm -rf /usr/local/bin/npm 2>/dev/null || true
rm -rf /usr/local/bin/node 2>/dev/null || true
rm -rf /usr/local/lib/node_modules 2>/dev/null || true
rm -rf /usr/local/include/node 2>/dev/null || true
rm -rf /usr/local/share/man/*/node* 2>/dev/null || true
print_success "تم حذف Node.js و npm"

# حذف MongoDB
print_header "🗑️ حذف MongoDB"
apt remove --purge -y mongodb-org mongodb-org-server mongodb-org-mongos mongodb-org-shell mongodb-org-tools 2>/dev/null || true
rm -rf /var/lib/mongodb 2>/dev/null || true
rm -rf /var/log/mongodb 2>/dev/null || true
rm -rf /etc/mongod.conf 2>/dev/null || true
print_success "تم حذف MongoDB"

# حذف MySQL
print_header "🗑️ حذف MySQL"
apt remove --purge -y mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-* 2>/dev/null || true
rm -rf /var/lib/mysql 2>/dev/null || true
rm -rf /var/log/mysql 2>/dev/null || true
rm -rf /etc/mysql 2>/dev/null || true
print_success "تم حذف MySQL"

# حذف PostgreSQL
print_header "🗑️ حذف PostgreSQL"
apt remove --purge -y postgresql postgresql-* 2>/dev/null || true
rm -rf /var/lib/postgresql 2>/dev/null || true
rm -rf /var/log/postgresql 2>/dev/null || true
rm -rf /etc/postgresql 2>/dev/null || true
print_success "تم حذف PostgreSQL"

# حذف Redis
print_header "🗑️ حذف Redis"
apt remove --purge -y redis-server redis-tools 2>/dev/null || true
rm -rf /var/lib/redis 2>/dev/null || true
rm -rf /var/log/redis 2>/dev/null || true
rm -rf /etc/redis 2>/dev/null || true
print_success "تم حذف Redis"

# حذف Memcached
print_header "🗑️ حذف Memcached"
apt remove --purge -y memcached 2>/dev/null || true
rm -rf /var/lib/memcached 2>/dev/null || true
rm -rf /var/log/memcached 2>/dev/null || true
print_success "تم حذف Memcached"

# حذف PHP
print_header "🗑️ حذف PHP"
apt remove --purge -y php* 2>/dev/null || true
rm -rf /etc/php 2>/dev/null || true
rm -rf /var/lib/php 2>/dev/null || true
print_success "تم حذف PHP"

# حذف Python
print_header "🗑️ حذف Python"
apt remove --purge -y python3-pip python3-venv python3-dev 2>/dev/null || true
rm -rf /usr/local/lib/python* 2>/dev/null || true
rm -rf /usr/local/bin/python* 2>/dev/null || true
print_success "تم حذف Python"

# حذف Git
print_header "🗑️ حذف Git"
apt remove --purge -y git 2>/dev/null || true
rm -rf /usr/local/bin/git 2>/dev/null || true
print_success "تم حذف Git"

# حذف Docker
print_header "🗑️ حذف Docker"
apt remove --purge -y docker.io docker-ce docker-ce-cli containerd.io 2>/dev/null || true
rm -rf /var/lib/docker 2>/dev/null || true
rm -rf /etc/docker 2>/dev/null || true
print_success "تم حذف Docker"

# حذف Composer
print_header "🗑️ حذف Composer"
rm -rf /usr/local/bin/composer 2>/dev/null || true
rm -rf /root/.composer 2>/dev/null || true
print_success "تم حذف Composer"

# حذف ملفات المستخدمين
print_header "🗑️ حذف ملفات المستخدمين"
rm -rf /home/*/.* 2>/dev/null || true
rm -rf /root/.* 2>/dev/null || true
print_success "تم حذف ملفات المستخدمين"

# حذف ملفات Cron
print_header "🗑️ حذف ملفات Cron"
crontab -r 2>/dev/null || true
rm -rf /var/spool/cron/* 2>/dev/null || true
rm -rf /etc/cron.* 2>/dev/null || true
print_success "تم حذف ملفات Cron"

# حذف ملفات النسخ الاحتياطية
print_header "🗑️ حذف ملفات النسخ الاحتياطية"
rm -rf /backup/* 2>/dev/null || true
rm -rf /var/backups/* 2>/dev/null || true
rm -rf /tmp/* 2>/dev/null || true
print_success "تم حذف ملفات النسخ الاحتياطية"

# تنظيف النظام
print_header "🧹 تنظيف النظام"
apt autoremove -y
apt autoclean
apt clean
rm -rf /var/cache/apt/archives/*
rm -rf /var/cache/apt/lists/*
print_success "تم تنظيف النظام"

# إعادة تعيين Firewall
print_header "🛡️ إعادة تعيين Firewall"
ufw --force reset
ufw --force disable
print_success "تم إعادة تعيين Firewall"

# إعادة تعيين Hostname
print_header "🔄 إعادة تعيين Hostname"
hostnamectl set-hostname localhost
print_success "تم إعادة تعيين Hostname"

# تنظيف الذاكرة
print_header "🧹 تنظيف الذاكرة"
sync
echo 3 > /proc/sys/vm/drop_caches
print_success "تم تنظيف الذاكرة"

# إعادة تشغيل النظام
print_header "🔄 إعادة تشغيل النظام"
print_warning "سيتم إعادة تشغيل النظام الآن..."
print_success "تم تنظيف VPS بنجاح!"
echo ""
echo "الآن يمكنك تشغيل سكريبت الرفع:"
echo "wget https://raw.githubusercontent.com/MahmouT1/unitrans/main/one-click-deploy.sh"
echo "chmod +x one-click-deploy.sh"
echo "./one-click-deploy.sh"
echo ""
print_warning "إعادة تشغيل النظام في 10 ثواني..."
sleep 10
reboot
