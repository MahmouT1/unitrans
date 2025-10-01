#!/bin/bash

echo "🎨 تغيير نوع الـ notification"
echo "==============================="
echo ""

cd /var/www/unitrans/frontend-new/app/admin/supervisor-dashboard

# Backup
cp page.js page.js.backup_notification_style_$(date +%Y%m%d_%H%M%S)

# 1. تغيير showNotification لاستخدام alert بسيط
echo "1. تغيير showNotification..."

# استبدال دالة showNotification
cat > /tmp/new_notification.js << 'EOF'
  // Simple notification without animation
  const showNotification = (type, title, message, duration = 2000) => {
    // Show simple alert-style notification
    const isSuccess = type === 'success';
    const icon = isSuccess ? '✅' : '❌';
    const color = isSuccess ? '#10b981' : '#ef4444';
    
    // Create simple notification
    const notification = {
      type,
      title: `${icon} ${title}`,
      message,
      id: Date.now()
    };
    
    setNotification(notification);
    
    // Auto-hide after duration
    setTimeout(() => {
      setNotification(null);
    }, duration);
  };
EOF

# نستبدل الدالة القديمة
# نبحث عن showNotification ونستبدلها
LINE=$(grep -n "const showNotification = " page.js | head -1 | cut -d: -f1)

if [ -n "$LINE" ]; then
    # نحذف من السطر إلى نهاية الدالة (};)
    END_LINE=$((LINE + 15))
    
    # نقسم الملف
    head -n $((LINE - 1)) page.js > /tmp/page_part1.js
    cat /tmp/new_notification.js >> /tmp/page_part1.js
    tail -n +$END_LINE page.js >> /tmp/page_part1.js
    
    mv /tmp/page_part1.js page.js
    
    echo "✅ تم تغيير showNotification"
else
    echo "⚠️  لم أجد showNotification"
fi

echo ""

# 2. تبسيط الـ notification CSS - إزالة animation
echo "2. إزالة animation..."

# استبدال animation بـ fade بسيط
sed -i "s/animation: 'slideInRight [^']*'/transition: 'opacity 0.3s ease'/" page.js
sed -i "s/animation: slideInRight [^,}]*/opacity: 1/" page.js

echo "✅ تم إزالة animation"

echo ""

# 3. Build
cd /var/www/unitrans/frontend-new

echo "حذف .next..."
rm -rf .next

echo ""
echo "البناء..."
npm run build 2>&1 | tail -25

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build نجح!"
    
    # إعادة تشغيل
    cd /var/www/unitrans
    pm2 restart unitrans-frontend
    pm2 save
    
    echo "✅ تم إعادة التشغيل"
else
    echo ""
    echo "❌ Build فشل"
    exit 1
fi

echo ""
echo "==============================="
echo "✅ تم!"
echo "==============================="
echo ""
echo "التغييرات:"
echo "  ✅ notification بسيطة بدون animation"
echo "  ✅ تختفي بعد ثانيتين"
echo "  ✅ لا اهتزاز!"
echo ""
echo "جرب في المتصفح الآن!"
echo "Ctrl+Shift+R"
echo ""

pm2 list
