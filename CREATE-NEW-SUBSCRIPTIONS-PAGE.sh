#!/bin/bash

echo "🎨 إنشاء صفحة Subscriptions جديدة - بسيطة واحترافية"
echo "============================================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd /var/www/unitrans/frontend-new/app/admin/subscriptions

# Backup الصفحة القديمة
echo -e "${YELLOW}1️⃣ Backup الصفحة القديمة...${NC}"
mv page.js page.js.OLD_BACKUP_$(date +%Y%m%d_%H%M%S)
echo "✅ Backup تم"
echo ""

# إنشاء صفحة جديدة بسيطة
echo -e "${YELLOW}2️⃣ إنشاء صفحة جديدة...${NC}"

cat > page.js << 'NEWPAGE'
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function SubscriptionsPage() {
  const router = useRouter();
  const [subscriptions, setSubscriptions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState('');

  useEffect(() => {
    // Check authentication
    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }
    
    fetchSubscriptions();
  }, []);

  const fetchSubscriptions = async () => {
    try {
      setLoading(true);
      console.log('📋 Fetching subscriptions...');
      
      const response = await fetch('/api/subscriptions');
      const data = await response.json();
      
      console.log('API Response:', data);
      
      if (data.success && data.subscriptions) {
        setSubscriptions(data.subscriptions);
        console.log(`✅ Loaded ${data.subscriptions.length} subscriptions`);
      } else {
        setSubscriptions([]);
      }
    } catch (error) {
      console.error('Error:', error);
      setSubscriptions([]);
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (date) => {
    if (!date) return 'N/A';
    return new Date(date).toLocaleDateString('en-US');
  };

  const formatAmount = (amount) => {
    return `${amount || 0} EGP`;
  };

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      {/* Header */}
      <div style={{ 
        marginBottom: '30px',
        borderBottom: '2px solid #e5e7eb',
        paddingBottom: '20px'
      }}>
        <h1 style={{ 
          fontSize: '28px',
          fontWeight: 'bold',
          color: '#1f2937',
          margin: '0 0 8px 0'
        }}>
          💳 Subscription Management
        </h1>
        <p style={{ 
          color: '#6b7280',
          margin: 0,
          fontSize: '14px'
        }}>
          Manage student subscriptions and payments
        </p>
      </div>

      {/* Actions */}
      <div style={{ marginBottom: '20px', display: 'flex', gap: '10px' }}>
        <button
          onClick={fetchSubscriptions}
          disabled={loading}
          style={{
            padding: '10px 20px',
            backgroundColor: '#3b82f6',
            color: 'white',
            border: 'none',
            borderRadius: '6px',
            cursor: loading ? 'not-allowed' : 'pointer',
            fontSize: '14px',
            fontWeight: '500'
          }}
        >
          {loading ? '⏳ Loading...' : '🔄 Refresh Data'}
        </button>
      </div>

      {/* Message */}
      {message && (
        <div style={{
          padding: '12px 16px',
          backgroundColor: '#d1fae5',
          color: '#065f46',
          borderRadius: '6px',
          marginBottom: '20px'
        }}>
          {message}
        </div>
      )}

      {/* Stats */}
      <div style={{ 
        marginBottom: '20px',
        padding: '16px',
        backgroundColor: '#f3f4f6',
        borderRadius: '8px'
      }}>
        <p style={{ margin: 0, fontSize: '16px', fontWeight: '600' }}>
          Total Subscriptions: <span style={{ color: '#3b82f6' }}>{subscriptions.length}</span>
        </p>
      </div>

      {/* Table */}
      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px' }}>
          <p style={{ color: '#6b7280' }}>Loading...</p>
        </div>
      ) : subscriptions.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '40px' }}>
          <p style={{ color: '#6b7280', fontSize: '16px' }}>
            📋 No subscriptions found
          </p>
        </div>
      ) : (
        <div style={{ 
          overflow: 'auto',
          backgroundColor: 'white',
          borderRadius: '8px',
          boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
        }}>
          <table style={{ 
            width: '100%',
            borderCollapse: 'collapse'
          }}>
            <thead>
              <tr style={{ backgroundColor: '#f9fafb', borderBottom: '2px solid #e5e7eb' }}>
                <th style={{ padding: '12px', textAlign: 'left', fontSize: '12px', fontWeight: '600', color: '#374151' }}>
                  STUDENT NAME
                </th>
                <th style={{ padding: '12px', textAlign: 'left', fontSize: '12px', fontWeight: '600', color: '#374151' }}>
                  EMAIL
                </th>
                <th style={{ padding: '12px', textAlign: 'left', fontSize: '12px', fontWeight: '600', color: '#374151' }}>
                  AMOUNT
                </th>
                <th style={{ padding: '12px', textAlign: 'left', fontSize: '12px', fontWeight: '600', color: '#374151' }}>
                  TYPE
                </th>
                <th style={{ padding: '12px', textAlign: 'left', fontSize: '12px', fontWeight: '600', color: '#374151' }}>
                  STATUS
                </th>
                <th style={{ padding: '12px', textAlign: 'left', fontSize: '12px', fontWeight: '600', color: '#374151' }}>
                  START DATE
                </th>
                <th style={{ padding: '12px', textAlign: 'left', fontSize: '12px', fontWeight: '600', color: '#374151' }}>
                  END DATE
                </th>
              </tr>
            </thead>
            <tbody>
              {subscriptions.map((sub, index) => (
                <tr 
                  key={sub.id || index}
                  style={{ 
                    borderBottom: '1px solid #e5e7eb',
                    transition: 'background-color 0.2s'
                  }}
                  onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f9fafb'}
                  onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'white'}
                >
                  <td style={{ padding: '12px', fontSize: '14px', color: '#1f2937' }}>
                    {sub.studentName || 'N/A'}
                  </td>
                  <td style={{ padding: '12px', fontSize: '14px', color: '#6b7280' }}>
                    {sub.studentEmail || 'N/A'}
                  </td>
                  <td style={{ padding: '12px', fontSize: '14px', fontWeight: '600', color: '#059669' }}>
                    {formatAmount(sub.amount)}
                  </td>
                  <td style={{ padding: '12px', fontSize: '14px', color: '#6b7280' }}>
                    {sub.subscriptionType || 'monthly'}
                  </td>
                  <td style={{ padding: '12px' }}>
                    <span style={{
                      padding: '4px 12px',
                      borderRadius: '12px',
                      fontSize: '12px',
                      fontWeight: '500',
                      backgroundColor: sub.status === 'active' ? '#d1fae5' : '#fee2e2',
                      color: sub.status === 'active' ? '#065f46' : '#991b1b'
                    }}>
                      {sub.status || 'active'}
                    </span>
                  </td>
                  <td style={{ padding: '12px', fontSize: '14px', color: '#6b7280' }}>
                    {formatDate(sub.startDate || sub.confirmationDate)}
                  </td>
                  <td style={{ padding: '12px', fontSize: '14px', color: '#6b7280' }}>
                    {formatDate(sub.endDate || sub.renewalDate)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Total Revenue */}
      {subscriptions.length > 0 && (
        <div style={{ 
          marginTop: '20px',
          padding: '16px',
          backgroundColor: '#ecfdf5',
          borderRadius: '8px',
          border: '1px solid #a7f3d0'
        }}>
          <p style={{ 
            margin: 0,
            fontSize: '18px',
            fontWeight: '600',
            color: '#065f46'
          }}>
            💰 Total Revenue: {formatAmount(subscriptions.reduce((sum, sub) => sum + (sub.amount || 0), 0))}
          </p>
        </div>
      )}
    </div>
  );
}
NEWPAGE

echo "✅ صفحة جديدة تم إنشاؤها"
echo ""

# Verify syntax
cd /var/www/unitrans/frontend-new
echo -e "${YELLOW}3️⃣ التحقق من الـ syntax...${NC}"
node -e "require('./app/admin/subscriptions/page.js')" 2>&1 | head -5 || echo "✅ الملف صحيح"

echo ""

# Rebuild Frontend (بدون إنشاء process جديد!)
echo -e "${YELLOW}4️⃣ Rebuild Frontend...${NC}"

# إيقاف الحالي
pm2 stop unitrans-frontend

# Clean build
rm -rf .next

# Build
npm run build

# إعادة تشغيل نفس الـ process
pm2 restart unitrans-frontend
pm2 save

echo ""
echo -e "${GREEN}✅ الصفحة الجديدة جاهزة!${NC}"
echo ""
echo "=============================================="
echo "المميزات:"
echo "  ✅ تصميم بسيط واحترافي"
echo "  ✅ تعرض جميع الاشتراكات مباشرة"
echo "  ✅ بدون تعقيدات Students matching"
echo "  ✅ Total Revenue يُحسب تلقائياً"
echo "  ✅ Refresh Data يعمل"
echo ""
echo "في المتصفح:"
echo "1. أغلق Browser تماماً"
echo "2. Firefox/Edge (Incognito)"
echo "3. unibus.online/admin/subscriptions"
echo "4. Login + Refresh"
echo "5. ✅ الاشتراكات ستظهر!"
echo ""

