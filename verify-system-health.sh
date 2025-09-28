#!/bin/bash

# =================================================
# 🔍 فحص صحة النظام قبل وبعد النشر
# =================================================

echo "🔍 بدء فحص صحة النظام..."
echo "=================================="

# معلومات النظام
echo "📊 معلومات النظام:"
echo "  📅 التاريخ: $(date)"
echo "  🖥️ المستخدم: $(whoami)"
echo "  📁 المجلد: $(pwd)"
echo ""

# 1️⃣ فحص MongoDB
echo "🗄️ 1. فحص MongoDB..."
MONGO_STATUS=$(systemctl is-active mongod 2>/dev/null || echo "inactive")
if [ "$MONGO_STATUS" = "active" ]; then
    echo "✅ MongoDB يعمل"
    
    # فحص الاتصال
    MONGO_CONNECTION=$(mongosh --eval "db.runCommand('ping')" --quiet 2>/dev/null | grep -c "ok.*1" || echo "0")
    if [ "$MONGO_CONNECTION" -gt 0 ]; then
        echo "✅ الاتصال بـ MongoDB يعمل"
    else
        echo "⚠️ مشكلة في الاتصال بـ MongoDB"
    fi
else
    echo "❌ MongoDB لا يعمل"
fi

# 2️⃣ فحص Nginx
echo ""
echo "🌐 2. فحص Nginx..."
NGINX_STATUS=$(systemctl is-active nginx 2>/dev/null || echo "inactive")
if [ "$NGINX_STATUS" = "active" ]; then
    echo "✅ Nginx يعمل"
    
    # فحص التكوين
    nginx -t >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ تكوين Nginx صحيح"
    else
        echo "⚠️ مشكلة في تكوين Nginx"
    fi
else
    echo "❌ Nginx لا يعمل"
fi

# 3️⃣ فحص PM2
echo ""
echo "⚙️ 3. فحص PM2..."
if command -v pm2 >/dev/null 2>&1; then
    echo "✅ PM2 مُثبت"
    
    # حالة التطبيقات
    PM2_APPS=$(pm2 jlist 2>/dev/null | jq -r '.[] | "\(.name): \(.pm2_env.status)"' 2>/dev/null || echo "لا يمكن قراءة حالة PM2")
    echo "📊 حالة التطبيقات:"
    echo "$PM2_APPS" | sed 's/^/    /'
    
else
    echo "❌ PM2 غير مُثبت"
fi

# 4️⃣ فحص المنافذ
echo ""
echo "🔌 4. فحص المنافذ..."
PORTS=("3000" "3001" "80" "443")
for port in "${PORTS[@]}"; do
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        echo "✅ المنفذ $port مُستخدم"
    else
        echo "⚠️ المنفذ $port غير مُستخدم"
    fi
done

# 5️⃣ فحص المساحة
echo ""
echo "💾 5. فحص مساحة القرص..."
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
echo "📊 استخدام القرص: $DISK_USAGE%"
if [ "$DISK_USAGE" -lt 80 ]; then
    echo "✅ مساحة القرص كافية"
else
    echo "⚠️ مساحة القرص محدودة ($DISK_USAGE%)"
fi

# 6️⃣ فحص الذاكرة
echo ""
echo "🧠 6. فحص الذاكرة..."
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
echo "📊 استخدام الذاكرة: $MEMORY_USAGE%"
if [ "$MEMORY_USAGE" -lt 80 ]; then
    echo "✅ الذاكرة كافية"
else
    echo "⚠️ استخدام عالي للذاكرة ($MEMORY_USAGE%)"
fi

# 7️⃣ فحص APIs
echo ""
echo "🌐 7. فحص APIs..."

# Frontend
FRONTEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/ 2>/dev/null || echo "000")
echo "🌐 Frontend (https://unibus.online/): $FRONTEND_HEALTH"

# Backend Health
BACKEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online:3001/health 2>/dev/null || echo "000")
echo "🔧 Backend Health: $BACKEND_HEALTH"

# Auth APIs
AUTH_LOGIN=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/api/proxy/auth/login 2>/dev/null || echo "000")
echo "🔐 Auth Login API: $AUTH_LOGIN"

AUTH_REGISTER=$(curl -s -o /dev/null -w "%{http_code}" https://unibus.online/api/proxy/auth/register 2>/dev/null || echo "000")
echo "📝 Auth Register API: $AUTH_REGISTER"

# 8️⃣ فحص الملفات المهمة
echo ""
echo "📁 8. فحص الملفات المهمة..."
IMPORTANT_FILES=(
    "/var/www/unitrans/frontend-new/app/auth/page.js"
    "/var/www/unitrans/backend-new/routes/auth.js"
    "/var/www/unitrans/frontend-new/app/api/proxy/auth/register/route.js"
    "/var/www/unitrans/frontend-new/app/api/proxy/auth/login/route.js"
)

for file in "${IMPORTANT_FILES[@]}"; do
    if [ -f "$file" ]; then
        SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        echo "✅ $file ($SIZE bytes)"
    else
        echo "❌ مفقود: $file"
    fi
done

# 9️⃣ فحص Logs
echo ""
echo "📋 9. فحص آخر أخطاء PM2..."
if command -v pm2 >/dev/null 2>&1; then
    echo "📋 آخر 3 أخطاء من unitrans-frontend:"
    pm2 logs unitrans-frontend --lines 3 --nostream 2>/dev/null | tail -3 | sed 's/^/    /'
    
    echo "📋 آخر 3 أخطاء من unitrans-backend:"
    pm2 logs unitrans-backend --lines 3 --nostream 2>/dev/null | tail -3 | sed 's/^/    /'
fi

echo ""
echo "=================================="
echo "✅ انتهى فحص صحة النظام"
echo "=================================="

# إرجاع رمز الخروج
if [ "$FRONTEND_HEALTH" = "200" ] && [ "$BACKEND_HEALTH" = "200" ]; then
    echo "🎯 النظام يعمل بشكل جيد"
    exit 0
else
    echo "⚠️ هناك مشاكل في النظام تحتاج انتباه"
    exit 1
fi
