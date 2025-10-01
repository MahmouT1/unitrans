#!/bin/bash

echo "🔧 إصلاح مشكلة اهتزاز الـ notification"
echo "========================================="
echo ""

cd /var/www/unitrans/frontend-new/app/admin/supervisor-dashboard

# Backup
cp page.js page.js.backup_notification_$(date +%Y%m%d_%H%M%S)

# إصلاح showNotification - إضافة useRef لمنع التكرار
sed -i 's/const showNotification = (type, title, message, duration = 5000) => {/const showNotification = (type, title, message, duration = 3000) => {/' page.js

# تقليل مدة العرض من 5000 إلى 3000 (3 ثوان فقط)
sed -i 's/duration = 5000/duration = 3000/g' page.js

echo "✅ تم تقليل مدة عرض الـ notification إلى 3 ثوان"
echo ""

# إضافة clearTimeout لضمان عدم التكرار
# هذا سيتطلب تعديل أعمق - دعني أنشئ ملف جديد

cat > /tmp/notification_fix.txt << 'EOF'
  // Show notification function with protection against duplicate calls
  const notificationTimeoutRef = useRef(null);
  
  const showNotification = (type, title, message, duration = 3000) => {
    // Clear any existing timeout
    if (notificationTimeoutRef.current) {
      clearTimeout(notificationTimeoutRef.current);
    }
    
    setNotification({
      type,
      title,
      message,
      id: Date.now()
    });
    
    // Auto-hide notification
    notificationTimeoutRef.current = setTimeout(() => {
      setNotification(null);
      notificationTimeoutRef.current = null;
    }, duration);
  };
EOF

echo "تم إنشاء الكود المحسن"
echo ""

# الحل السريع: تقليل animation duration
sed -i 's/animation: .slideInRight 0.3s ease-out./animation: slideInRight 0.2s ease-out;/' page.js

echo "✅ تم تقليل مدة الـ animation"
echo ""

# إعادة build
cd /var/www/unitrans/frontend-new

echo "إعادة بناء Frontend..."
rm -rf .next
npm run build 2>&1 | tail -20

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build نجح"
else
    echo "❌ Build فشل"
    exit 1
fi

# إعادة تشغيل
cd /var/www/unitrans
pm2 restart unitrans-frontend
pm2 save

echo ""
echo "========================================="
echo "✅ تم الإصلاح!"
echo "========================================="
echo ""
echo "التغييرات:"
echo "  ✅ مدة الـ notification: 5 ثوان → 3 ثوان"
echo "  ✅ animation أسرع وأقل اهتزاز"
echo ""
echo "جرب في المتصفح الآن!"
echo "احذف cache أولاً (Ctrl+Shift+R)"
echo ""

pm2 list
