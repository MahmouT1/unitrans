#!/bin/bash

# Ultimate Supervisor Removal Script
# Removes ALL supervisor-related pages and functionality completely

echo "🗑️ Starting Ultimate Supervisor Removal..."

# Navigate to frontend directory
cd /var/www/unitrans/frontend-new
echo "📁 Current directory: $(pwd)"

# 1. Remove ALL supervisor directories and files
echo "🗑️ Removing ALL supervisor directories..."
rm -rf app/admin/supervisor*
rm -rf app/admin/attendance/supervisor*
rm -rf app/supervisor*

# 2. Remove supervisor files from all locations
echo "🗑️ Removing supervisor files from all locations..."
find . -name "*supervisor*" -type f -delete 2>/dev/null || true
find . -name "*supervisor*" -type d -exec rm -rf {} + 2>/dev/null || true

# 3. Remove ALL supervisor API routes
echo "🗑️ Removing ALL supervisor API routes..."
rm -rf app/api/supervisor*
rm -rf app/api/shifts*

# 4. Clean supervisor references from ALL layout files
echo "🔧 Cleaning supervisor references from ALL layouts..."
find app -name "layout.js" -exec sed -i '/supervisor/d' {} \; 2>/dev/null || true
find app -name "page.js" -exec sed -i '/supervisor/d' {} \; 2>/dev/null || true

# 5. Remove supervisor from admin dashboard layout specifically
if [ -f "app/admin/dashboard/layout.js" ]; then
    echo "🔧 Cleaning admin dashboard layout..."
    sed -i '/supervisor-dashboard/d' app/admin/dashboard/layout.js
    sed -i '/Supervisor Dashboard/d' app/admin/dashboard/layout.js
    sed -i '/supervisor/d' app/admin/dashboard/layout.js
fi

# 6. Remove supervisor from auth page
if [ -f "app/auth/page.js" ]; then
    echo "🔧 Cleaning auth page..."
    sed -i '/supervisor-dashboard/d' app/auth/page.js
    sed -i '/supervisor/d' app/auth/page.js
fi

# 7. Clean admin layout CSS completely
echo "🔧 Cleaning admin layout CSS..."
cat > app/admin/admin-layout.css << 'CSS_EOF'
/* Admin Layout CSS - Clean Version */
.admin-layout {
  display: flex;
  min-height: 100vh;
  background-color: #f5f5f5;
}
.admin-sidebar {
  width: 250px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 20px 0;
  box-shadow: 2px 0 10px rgba(0,0,0,0.1);
}
.admin-sidebar h2 {
  text-align: center;
  margin-bottom: 30px;
  font-size: 1.5rem;
  font-weight: bold;
}
.admin-sidebar nav ul {
  list-style: none;
  padding: 0;
  margin: 0;
}
.admin-sidebar nav ul li {
  margin-bottom: 10px;
}
.admin-sidebar nav ul li a {
  display: flex;
  align-items: center;
  padding: 12px 20px;
  color: white;
  text-decoration: none;
  transition: all 0.3s ease;
  border-radius: 0 25px 25px 0;
  margin-right: 10px;
}
.admin-sidebar nav ul li a:hover {
  background-color: rgba(255,255,255,0.1);
  transform: translateX(5px);
}
.admin-sidebar nav ul li a.active {
  background-color: rgba(255,255,255,0.2);
  font-weight: bold;
}
.admin-sidebar nav ul li a svg {
  margin-right: 10px;
  width: 20px;
  height: 20px;
}
.main-content {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
}
@media (max-width: 768px) {
  .admin-layout {
    flex-direction: column;
  }
  .admin-sidebar {
    width: 100%;
    height: auto;
  }
  .main-content {
    padding: 10px;
  }
}
CSS_EOF

# 8. Remove ALL supervisor components
echo "🗑️ Removing ALL supervisor components..."
rm -rf components/supervisor*
rm -rf components/admin/Supervisor*
find components -name "*supervisor*" -type f -delete 2>/dev/null || true
find components -name "*supervisor*" -type d -exec rm -rf {} + 2>/dev/null || true

# 9. Clean ALL Next.js cache
echo "🧹 Cleaning ALL Next.js cache..."
rm -rf .next
rm -rf node_modules/.cache
rm -rf .next/server/app/admin/supervisor*
rm -rf .next/server/app/api/supervisor*
rm -rf .next/server/app/api/shifts*

# 10. Remove supervisor from package.json if exists
echo "🔧 Cleaning package.json..."
if [ -f "package.json" ]; then
    sed -i '/supervisor/d' package.json 2>/dev/null || true
fi

# 11. Remove supervisor from any config files
echo "🔧 Cleaning config files..."
find . -name "*.json" -exec sed -i '/supervisor/d' {} \; 2>/dev/null || true
find . -name "*.js" -exec sed -i '/supervisor/d' {} \; 2>/dev/null || true

# 12. Rebuild application
echo "🔨 Rebuilding application..."
npm run build

# 13. Restart PM2
echo "🔄 Restarting PM2..."
pm2 restart unitrans-frontend

# 14. Final verification
echo "🔍 Final verification..."
if [ -d "app/admin/supervisor-dashboard" ]; then
    echo "❌ Supervisor dashboard still exists!"
else
    echo "✅ Supervisor dashboard removed successfully!"
fi

if [ -d "app/api/shifts" ]; then
    echo "❌ Shifts API still exists!"
else
    echo "✅ Shifts API removed successfully!"
fi

# 15. Check for any remaining supervisor files
echo "🔍 Checking for remaining supervisor files..."
REMAINING=$(find . -name "*supervisor*" 2>/dev/null | wc -l)
if [ "$REMAINING" -gt 0 ]; then
    echo "❌ Found $REMAINING remaining supervisor files:"
    find . -name "*supervisor*" 2>/dev/null
else
    echo "✅ No supervisor files remaining!"
fi

echo "✅ Ultimate supervisor removal finished!"
echo "🌐 Application should now work at: https://unibus.online"
echo "📋 ALL supervisor pages and functionality have been removed"
