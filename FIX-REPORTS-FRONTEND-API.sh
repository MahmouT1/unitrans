#!/bin/bash

echo "🔧 إصلاح Reports لاستخدام Frontend API فقط"
echo "=============================================="

cd /var/www/unitrans && \
git pull origin main && \
bash FIX-REPORTS-COMPLETE.sh
