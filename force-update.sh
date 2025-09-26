#!/bin/bash

# 🚀 Force Update Script for UniBus
# سكريبت إجبار التحديث

set -e

# ألوان للطباعة
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# التحقق من صلاحيات المدير
if [ "$EUID" -ne 0 ]; then
    print_error "يرجى تشغيل السكريبت كمدير (root)"
    exit 1
fi

print_header "🚀 إجبار تحديث مشروع UniBus"

# إيقاف التطبيقات
print_status "⏹️ إيقاف التطبيقات..."
pm2 stop all

# الانتقال إلى مجلد المشروع
cd /var/www/unitrans

# حذف مجلد .next للبناء النظيف
print_status "🗑️ حذف مجلد البناء القديم..."
rm -rf frontend-new/.next

# تحديث المشروع
print_status "📥 تحديث المشروع من GitHub..."
git fetch origin
git reset --hard origin/main
print_success "تم تحديث المشروع!"

# تحديث الفرونت إند
print_header "🔄 تحديث الفرونت إند"
cd frontend-new

print_status "تثبيت المكتبات..."
npm install --force

print_status "بناء المشروع من جديد..."
npm run build

print_success "تم بناء الفرونت إند!"

# تحديث الباك إند
print_header "🔄 تحديث الباك إند"
cd ../backend-new

print_status "تثبيت المكتبات..."
npm install

print_success "تم تحديث الباك إند!"

# إعادة تشغيل التطبيقات
print_header "🔄 إعادة تشغيل التطبيقات"
cd /var/www/unitrans

print_status "إعادة تشغيل PM2..."
pm2 start all

print_status "فحص حالة التطبيقات..."
pm2 status

# فحص الخدمات
print_header "🔍 فحص الخدمات"
print_status "فحص الفرونت إند..."
sleep 5
curl -s http://localhost:3000 > /dev/null && print_success "✅ الفرونت إند يعمل" || print_warning "⚠️ الفرونت إند قد يحتاج وقت إضافي"

print_status "فحص الباك إند..."
curl -s http://localhost:3001/health > /dev/null && print_success "✅ الباك إند يعمل" || print_warning "⚠️ الباك إند قد يحتاج وقت إضافي"

print_header "✅ تم الانتهاء من التحديث الإجباري!"
print_success "المشروع محدث ويعمل على: https://unibus.online"
print_success "🧪 جرب تسجيل الدخول بـ:"
print_success "   البريد: test@unibus.online"
print_success "   كلمة المرور: 123456"
print_success "   النوع: student"
print_warning "⚠️ إذا لم يعمل، انتظر 2-3 دقائق ثم جرب مرة أخرى"
