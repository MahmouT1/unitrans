#!/bin/bash

# Complete Supervisor Removal Script - Final Version
# Removes ALL supervisor-related pages and functionality

echo "🗑️ Starting Complete Supervisor Removal..."

# Navigate to frontend directory
cd /var/www/unitrans/frontend-new

echo "📁 Current directory: $(pwd)"

# 1. Remove all supervisor directories and files
echo "🗑️ Removing supervisor directories..."
rm -rf app/admin/supervisor-dashboard*
rm -rf app/admin/supervisor-mobile
rm -rf app/admin/supervisor-simple
rm -rf app/admin/attendance/supervisor

# 2. Remove supervisor-related files from app directory
echo "🗑️ Removing supervisor files..."
find app -name "*supervisor*" -type f -delete
find app -name "*supervisor*" -type d -exec rm -rf {} + 2>/dev/null || true

# 3. Remove supervisor routes from API
echo "🗑️ Removing supervisor API routes..."
rm -rf app/api/supervisor*
rm -rf app/api/shifts*

# 4. Clean up any supervisor references in layout files
echo "🔧 Cleaning supervisor references from layouts..."

# Remove supervisor links from admin dashboard layout
if [ -f "app/admin/dashboard/layout.js" ]; then
    sed -i '/supervisor-dashboard/d' app/admin/dashboard/layout.js
    sed -i '/Supervisor Dashboard/d' app/admin/dashboard/layout.js
fi

# Remove supervisor links from auth page
if [ -f "app/auth/page.js" ]; then
    sed -i '/supervisor-dashboard/d' app/auth/page.js
    sed -i '/supervisor/d' app/auth/page.js
fi

# 5. Clean up admin layout CSS
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

/* Mobile Responsive */
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

# 6. Clean up any remaining supervisor components
echo "🗑️ Removing supervisor components..."
rm -rf components/supervisor*
rm -rf components/admin/Supervisor*
find components -name "*supervisor*" -type f -delete 2>/dev/null || true

# 7. Clean Next.js cache
echo "🧹 Cleaning Next.js cache..."
rm -rf .next
rm -rf node_modules/.cache

# 8. Clean any supervisor-related build artifacts
echo "🗑️ Cleaning build artifacts..."
rm -rf .next/server/app/admin/supervisor*
rm -rf .next/server/app/api/supervisor*
rm -rf .next/server/app/api/shifts*

# 9. Rebuild the application
echo "🔨 Rebuilding application..."
npm run build

# 10. Restart PM2
echo "🔄 Restarting PM2..."
pm2 restart unitrans-frontend

# 11. Final verification
echo "🔍 Verifying removal..."
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

echo "✅ Complete supervisor removal finished!"
echo "🌐 Application should now work at: https://unibus.online"
echo "📋 All supervisor pages and functionality have been removed"
