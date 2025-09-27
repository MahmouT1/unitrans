#!/bin/bash

# 🚀 Quick Frontend Update Script
# سكريبت تحديث سريع للفرونت إند

set -e

# ألوان للطباعة
GREEN='\033[0;32m'
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

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_header "🚀 تحديث سريع للفرونت إند"

# الانتقال إلى مجلد المشروع
cd /var/www/unitrans

print_status "📥 تحديث المشروع من GitHub..."
git pull origin main
print_success "تم تحديث المشروع!"

# تحديث الفرونت إند
print_status "🔄 تحديث الفرونت إند..."
cd frontend-new

print_status "تثبيت المكتبات..."
npm install

print_status "بناء المشروع..."
npm run build

print_success "تم بناء الفرونت إند!"

# إعادة تشغيل الفرونت إند فقط
print_status "🔄 إعادة تشغيل الفرونت إند..."
pm2 restart unitrans-frontend

print_status "فحص حالة الفرونت إند..."
pm2 status unitrans-frontend

print_success "✅ تم تحديث الفرونت إند بنجاح!"
print_success "🌐 الموقع: https://unibus.online"
print_success "🧪 جرب تسجيل الدخول بـ:"
print_success "   البريد: test@unibus.online"
print_success "   كلمة المرور: 123456"
print_success "   النوع: student"
