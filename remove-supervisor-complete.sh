#!/bin/bash

# Complete Supervisor Removal Script
# This script removes all supervisor-related pages and references

echo "🚀 Starting Complete Supervisor Removal..."

# Navigate to frontend directory
cd /var/www/unitrans/frontend-new

echo "📁 Current directory: $(pwd)"

# 1. Remove all supervisor directories
echo "🗑️ Removing supervisor directories..."
rm -rf app/admin/supervisor-dashboard
rm -rf app/admin/supervisor-mobile  
rm -rf app/admin/supervisor-simple
rm -rf app/admin/supervisor-dashboard-enhanced

# 2. Remove supervisor files from .next cache
echo "🗑️ Cleaning .next cache..."
rm -rf .next/server/app/admin/supervisor*
rm -rf .next/static/chunks/*supervisor*

# 3. Remove supervisor references from layout files
echo "🔧 Cleaning layout files..."

# Remove supervisor dashboard link from admin layout
sed -i '/supervisor-dashboard/d' app/admin/dashboard/layout.js
sed -i '/Supervisor Dashboard/d' app/admin/dashboard/layout.js

# Remove supervisor references from auth page
sed -i '/supervisor-dashboard/d' app/auth/page.js

# Remove supervisor references from dashboard-no-guard
sed -i '/supervisor-dashboard/d' app/admin/dashboard-no-guard/page.js

# 4. Clean CSS file
echo "🎨 Cleaning CSS files..."
cat > app/admin/admin-layout.css << 'EOF'
/* Basic Admin Layout Styles */
.admin-layout {
  display: flex;
  min-height: 100vh;
  background-color: #f8f9fa;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.admin-sidebar {
  width: 280px;
  background: linear-gradient(180deg, #1e293b 0%, #334155 100%);
  color: white;
  display: flex;
  flex-direction: column;
  box-shadow: 4px 0 20px rgba(0, 0, 0, 0.1);
  position: fixed;
  height: 100vh;
  overflow-y: auto;
  z-index: 1000;
}

.sidebar-header {
  padding: 1.5rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.admin-profile {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.admin-avatar {
  width: 50px;
  height: 50px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
}

.admin-info {
  flex: 1;
}

.admin-name {
  font-weight: 600;
  font-size: 1rem;
  margin-bottom: 0.25rem;
}

.admin-role {
  font-size: 0.875rem;
  color: #94a3b8;
}

.sidebar-nav {
  flex: 1;
  padding: 1rem 0;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1.5rem;
  color: #cbd5e1;
  text-decoration: none;
  transition: all 0.3s ease;
  border-left: 3px solid transparent;
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.nav-item.active {
  background: rgba(102, 126, 234, 0.2);
  color: #667eea;
  border-left-color: #667eea;
}

.nav-icon {
  font-size: 1.25rem;
  width: 24px;
  text-align: center;
}

.nav-label {
  font-weight: 500;
}

.sidebar-actions {
  padding: 1rem;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

main {
  margin-left: 280px;
  flex: 1;
  min-height: 100vh;
  background-color: #f8f9fa;
}

@media (max-width: 768px) {
  .admin-sidebar {
    display: none;
  }
  
  main {
    margin-left: 0;
  }
}
EOF

# 5. Remove any remaining supervisor references
echo "🔍 Searching for remaining supervisor references..."
find . -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" | xargs grep -l "supervisor" 2>/dev/null | while read file; do
    echo "🧹 Cleaning $file..."
    sed -i '/supervisor/d' "$file" 2>/dev/null || true
done

# 6. Clean build cache
echo "🧹 Cleaning build cache..."
rm -rf .next
rm -rf node_modules/.cache

# 7. Rebuild application
echo "🔨 Rebuilding application..."
npm run build

# 8. Restart PM2
echo "🔄 Restarting PM2..."
pm2 restart unitrans-frontend

# 9. Verify removal
echo "✅ Verification:"
echo "Checking for supervisor directories..."
if [ -d "app/admin/supervisor-dashboard" ]; then
    echo "❌ supervisor-dashboard still exists"
else
    echo "✅ supervisor-dashboard removed"
fi

if [ -d "app/admin/supervisor-mobile" ]; then
    echo "❌ supervisor-mobile still exists"
else
    echo "✅ supervisor-mobile removed"
fi

if [ -d "app/admin/supervisor-simple" ]; then
    echo "❌ supervisor-simple still exists"
else
    echo "✅ supervisor-simple removed"
fi

echo "🔍 Checking for supervisor references in layout..."
if grep -q "supervisor" app/admin/dashboard/layout.js; then
    echo "❌ supervisor references still found in layout"
else
    echo "✅ supervisor references removed from layout"
fi

echo "🎉 Supervisor removal completed!"
echo "📋 Summary:"
echo "   - All supervisor directories removed"
echo "   - All supervisor references cleaned"
echo "   - CSS file reset"
echo "   - Application rebuilt"
echo "   - PM2 restarted"
echo ""
echo "🌐 You can now access the application at: https://unibus.online"
echo "📱 The supervisor dashboard should no longer be accessible"
