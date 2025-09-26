#!/bin/bash

# 🚀 Production Update Script for UniBus
# سكريبت تحديث المشروع على السيرفر الإنتاجي

set -e

# ألوان للطباعة
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# دالة طباعة الرسائل
print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# التحقق من صلاحيات المدير
if [ "$EUID" -ne 0 ]; then
    print_error "يرجى تشغيل السكريبت كمدير (root)"
    exit 1
fi

print_header "🚀 تحديث مشروع UniBus على السيرفر الإنتاجي"

# الانتقال إلى مجلد المشروع
cd /var/www/unitrans

print_status "📥 تحديث المشروع من GitHub..."
git pull origin main
print_success "تم تحديث المشروع بنجاح!"

# تحديث الفرونت إند
print_header "🔄 تحديث الفرونت إند"
cd frontend-new

print_status "تثبيت المكتبات الجديدة..."
npm install

print_status "بناء المشروع..."
npm run build

print_success "تم تحديث الفرونت إند بنجاح!"

# تحديث الباك إند
print_header "🔄 تحديث الباك إند"
cd ../backend-new

print_status "تثبيت المكتبات الجديدة..."
npm install

print_success "تم تحديث الباك إند بنجاح!"

# إعادة تشغيل التطبيقات
print_header "🔄 إعادة تشغيل التطبيقات"
cd /var/www/unitrans

print_status "إعادة تشغيل PM2..."
pm2 restart all

print_status "فحص حالة التطبيقات..."
pm2 status

print_success "تم إعادة تشغيل التطبيقات بنجاح!"

# فحص الخدمات
print_header "🔍 فحص الخدمات"
print_status "فحص الفرونت إند..."
curl -s http://localhost:3000 > /dev/null && print_success "✅ الفرونت إند يعمل" || print_error "❌ الفرونت إند لا يعمل"

print_status "فحص الباك إند..."
curl -s http://localhost:3001/health > /dev/null && print_success "✅ الباك إند يعمل" || print_error "❌ الباك إند لا يعمل"

print_status "فحص Nginx..."
systemctl is-active nginx > /dev/null && print_success "✅ Nginx يعمل" || print_error "❌ Nginx لا يعمل"

print_header "✅ تم الانتهاء من التحديث بنجاح!"
print_success "المشروع محدث ويعمل على: https://unibus.online"
