'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function SubscriptionsPage() {
  const router = useRouter();
  const [subscriptions, setSubscriptions] = useState([]);
  const [filteredSubscriptions, setFilteredSubscriptions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) {
      router.push('/login');
      return;
    }
    fetchSubscriptions();
  }, []);

  useEffect(() => {
    // Filter subscriptions when search term changes
    if (searchTerm.trim() === '') {
      setFilteredSubscriptions(subscriptions);
    } else {
      const filtered = subscriptions.filter(sub => {
        const name = (sub.studentName || '').toLowerCase();
        const email = (sub.studentEmail || '').toLowerCase();
        const search = searchTerm.toLowerCase();
        return name.includes(search) || email.includes(search);
      });
      setFilteredSubscriptions(filtered);
    }
  }, [searchTerm, subscriptions]);

  const fetchSubscriptions = async () => {
    try {
      setLoading(true);
      const response = await fetch('/api/subscriptions');
      const data = await response.json();
      
      if (data.success && data.subscriptions) {
        setSubscriptions(data.subscriptions);
        setFilteredSubscriptions(data.subscriptions);
      }
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (subscriptionId) => {
    if (!confirm('هل أنت متأكد من حذف هذا الاشتراك؟')) {
      return;
    }

    try {
      const response = await fetch(`/api/subscriptions/${subscriptionId}`, {
        method: 'DELETE'
      });

      const data = await response.json();

      if (data.success) {
        alert('تم حذف الاشتراك بنجاح!');
        fetchSubscriptions(); // Refresh list
      } else {
        alert('فشل حذف الاشتراك: ' + data.message);
      }
    } catch (error) {
      console.error('Error deleting subscription:', error);
      alert('حدث خطأ أثناء حذف الاشتراك');
    }
  };

  return (
    <div style={{ padding: '20px' }}>
      <h1 style={{ fontSize: '28px', marginBottom: '20px' }}>💳 Subscription Management</h1>
      
      <div style={{ display: 'flex', gap: '12px', marginBottom: '20px', flexWrap: 'wrap' }}>
        <button onClick={fetchSubscriptions} style={{
          padding: '10px 20px',
          backgroundColor: '#3b82f6',
          color: 'white',
          border: 'none',
          borderRadius: '6px',
          cursor: 'pointer',
          fontWeight: '500'
        }}>
          🔄 Refresh Data
        </button>

        <input
          type="text"
          placeholder="🔍 Search by name or email..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          style={{
            flex: '1',
            minWidth: '300px',
            padding: '10px 16px',
            border: '2px solid #e5e7eb',
            borderRadius: '6px',
            fontSize: '14px',
            outline: 'none'
          }}
          onFocus={(e) => e.target.style.borderColor = '#3b82f6'}
          onBlur={(e) => e.target.style.borderColor = '#e5e7eb'}
        />
      </div>

      <p style={{ marginBottom: '20px', fontSize: '16px', fontWeight: '600' }}>
        Showing {filteredSubscriptions.length} of {subscriptions.length} subscriptions
      </p>

      {loading ? (
        <p>Loading...</p>
      ) : filteredSubscriptions.length === 0 ? (
        <p>No subscriptions found</p>
      ) : (
        <div style={{ overflow: 'auto', backgroundColor: 'white', borderRadius: '8px' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead style={{ backgroundColor: '#f9fafb' }}>
              <tr>
                <th style={{ padding: '12px', textAlign: 'left' }}>STUDENT NAME</th>
                <th style={{ padding: '12px', textAlign: 'left' }}>EMAIL</th>
                <th style={{ padding: '12px', textAlign: 'left' }}>AMOUNT</th>
                <th style={{ padding: '12px', textAlign: 'left' }}>TYPE</th>
                <th style={{ padding: '12px', textAlign: 'left' }}>STATUS</th>
                <th style={{ padding: '12px', textAlign: 'left' }}>START DATE</th>
                <th style={{ padding: '12px', textAlign: 'left' }}>END DATE</th>
                <th style={{ padding: '12px', textAlign: 'center' }}>ACTION</th>
              </tr>
            </thead>
            <tbody>
              {filteredSubscriptions.map((sub, i) => (
                <tr key={i} style={{ borderBottom: '1px solid #e5e7eb' }}>
                  <td style={{ padding: '12px' }}>{sub.studentName}</td>
                  <td style={{ padding: '12px' }}>{sub.studentEmail}</td>
                  <td style={{ padding: '12px', fontWeight: '600', color: '#059669' }}>
                    {sub.amount} EGP
                  </td>
                  <td style={{ padding: '12px' }}>{sub.subscriptionType}</td>
                  <td style={{ padding: '12px' }}>
                    <span style={{
                      padding: '4px 12px',
                      borderRadius: '12px',
                      backgroundColor: '#d1fae5',
                      color: '#065f46'
                    }}>
                      {sub.status}
                    </span>
                  </td>
                  <td style={{ padding: '12px' }}>
                    {new Date(sub.startDate || sub.confirmationDate).toLocaleDateString()}
                  </td>
                  <td style={{ padding: '12px' }}>
                    {new Date(sub.endDate || sub.renewalDate).toLocaleDateString()}
                  </td>
                  <td style={{ padding: '12px', textAlign: 'center' }}>
                    <button
                      onClick={() => handleDelete(sub._id)}
                      style={{
                        padding: '6px 12px',
                        backgroundColor: '#ef4444',
                        color: 'white',
                        border: 'none',
                        borderRadius: '6px',
                        cursor: 'pointer',
                        fontSize: '14px',
                        fontWeight: '500'
                      }}
                      onMouseOver={(e) => e.target.style.backgroundColor = '#dc2626'}
                      onMouseOut={(e) => e.target.style.backgroundColor = '#ef4444'}
                    >
                      🗑️ Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          
          <div style={{
            marginTop: '20px',
            padding: '16px',
            backgroundColor: '#ecfdf5',
            borderRadius: '8px'
          }}>
            <p style={{ margin: 0, fontSize: '18px', fontWeight: '600', color: '#065f46' }}>
              💰 Total Revenue: {filteredSubscriptions.reduce((sum, sub) => sum + (sub.amount || 0), 0)} EGP
            </p>
          </div>
        </div>
      )}
    </div>
  );
}