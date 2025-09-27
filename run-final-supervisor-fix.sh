#!/bin/bash

echo "🔄 تشغيل سكريبت إصلاح صفحة المشرف النهائي..."

# Upload the fix script to the server
curl -sSL https://raw.githubusercontent.com/MahmouT1/unitrans/main/fix-supervisor-dashboard-final.sh | bash

echo "✅ تم تشغيل السكريبت بنجاح!"
