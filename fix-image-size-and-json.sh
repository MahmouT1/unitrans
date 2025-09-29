#!/bin/bash

echo "🔧 إصلاح مشكلة الصور الكبيرة و JSON parsing"
echo "=========================================="

cd /var/www/unitrans

echo "🛑 إيقاف Frontend..."
pm2 stop unitrans-frontend

echo ""
echo "🔧 إصلاح 1: ضغط الصور في Registration:"
echo "====================================="

# إصلاح handleFileChange في Registration لضغط الصور
cat > /tmp/image_compression_fix.js << 'EOF'
  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      if (!file.type.startsWith('image/')) {
        setError('Please select an image file');
        return;
      }
      if (file.size > 10 * 1024 * 1024) {
        setError('File size must be less than 10MB');
        return;
      }

      // ضغط الصورة قبل الحفظ
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      const img = new Image();
      
      img.onload = () => {
        // تحديد أقصى عرض وارتفاع
        const MAX_WIDTH = 400;
        const MAX_HEIGHT = 400;
        
        let { width, height } = img;
        
        // حساب الأبعاد الجديدة مع الحفاظ على النسبة
        if (width > height) {
          if (width > MAX_WIDTH) {
            height = (height * MAX_WIDTH) / width;
            width = MAX_WIDTH;
          }
        } else {
          if (height > MAX_HEIGHT) {
            width = (width * MAX_HEIGHT) / height;
            height = MAX_HEIGHT;
          }
        }
        
        canvas.width = width;
        canvas.height = height;
        
        // رسم الصورة المضغوطة
        ctx.drawImage(img, 0, 0, width, height);
        
        // تحويل إلى base64 مع ضغط إضافي
        const compressedDataURL = canvas.toDataURL('image/jpeg', 0.7); // 70% quality
        
        console.log('📸 Image compressed:', {
          originalSize: file.size,
          compressedSize: compressedDataURL.length,
          reduction: Math.round((1 - compressedDataURL.length / file.size) * 100) + '%'
        });
        
        setFormData(prev => ({
          ...prev,
          profilePhoto: compressedDataURL
        }));
        
        setError('');
      };
      
      const reader = new FileReader();
      reader.onloadend = () => {
        img.src = reader.result;
      };
      reader.readAsDataURL(file);
    }
  };
EOF

# تطبيق الإصلاح على Registration page
sed -i '/const handleFileChange = (e) => {/,/};/{
  /const handleFileChange = (e) => {/r /tmp/image_compression_fix.js
  d
}' frontend-new/app/student/registration/page.js

echo "✅ تم إضافة ضغط الصور في Registration"

echo ""
echo "🔧 إصلاح 2: زيادة حد الـ payload في Backend:"
echo "==========================================="

# زيادة حد الـ body parser في server.js
if ! grep -q "limit.*50mb" backend-new/server.js; then
    sed -i '/app.use(express.json/c\
app.use(express.json({ limit: "50mb" })); // زيادة حد الـ payload\
app.use(express.urlencoded({ extended: true, limit: "50mb" }));' backend-new/server.js
    echo "✅ تم زيادة حد الـ payload في Backend"
else
    echo "✅ حد الـ payload مُعدّل مسبقاً"
fi

echo ""
echo "🔧 إصلاح 3: تحسين error handling في Registration:"
echo "============================================="

# إضافة better error handling
sed -i '/} catch (error) {/,/} finally {/{
  s/setError.*Network error.*/setError(`Registration failed: ${error.message || "Network error"}. Please try again.`);/
}' frontend-new/app/student/registration/page.js

echo "✅ تم تحسين error handling"

echo ""
echo "🔧 إصلاح 4: إضافة validation للصورة المضغوطة:"
echo "=========================================="

# إضافة validation إضافية قبل الإرسال
sed -i '/const updateData = {/i\
      // التحقق من حجم الصورة المضغوطة\
      if (formData.profilePhoto && formData.profilePhoto.length > 2 * 1024 * 1024) {\
        setError("Image is still too large after compression. Please select a smaller image.");\
        setLoading(false);\
        return;\
      }\
' frontend-new/app/student/registration/page.js

echo "✅ تم إضافة validation للصورة"

echo ""
echo "🏗️ إعادة بناء Frontend:"
echo "======================="

cd frontend-new
rm -rf .next
npm run build

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ البناء نجح!"
    
    echo ""
    echo "🚀 إعادة تشغيل Frontend و Backend..."
    pm2 restart unitrans-frontend
    pm2 restart unitrans-backend
    
    echo ""
    echo "⏳ انتظار استقرار النظام..."
    sleep 8
    
    echo ""
    echo "🧪 اختبار Registration:"
    echo "===================="
    
    curl -I https://unibus.online/student/registration -w "Status: %{http_code}\n" -s
    
else
    echo "❌ البناء فشل!"
fi

echo ""
echo "📊 حالة النهائية:"
pm2 status

echo ""
echo "✅ إصلاح الصور الكبيرة و JSON parsing اكتمل!"
echo ""
echo "🎯 التحسينات المطبقة:"
echo "   📸 ضغط الصور تلقائياً (400x400px, 70% quality)"
echo "   📦 زيادة حد الـ payload إلى 50MB"
echo "   🛠️ تحسين error handling"
echo "   ✅ validation إضافية للصور"
echo ""
echo "🔗 جرب: https://unibus.online/student/registration"
echo "   📸 اختر صورة أصغر أو ستُضغط تلقائياً"
echo "   📱 QR Code سيعمل بامتياز!"

# تنظيف
rm -f /tmp/image_compression_fix.js
