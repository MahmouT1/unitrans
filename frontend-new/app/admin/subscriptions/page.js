'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function SubscriptionsPage() {
  const router = useRouter();
  const [subscriptions, setSubscriptions] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
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
      const response = await fetch('/api/subscriptions');
      const data = await response.json();
      
      if (data.success && data.subscriptions) {
        setSubscriptions(data.subscriptions);
      }
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ padding: '20px' }}>
      <h1 style={{ fontSize: '28px', marginBottom: '20px' }}>💳 Subscription Management</h1>
      
      <button onClick={fetchSubscriptions} style={{
        padding: '10px 20px',
        backgroundColor: '#3b82f6',
        color: 'white',
        border: 'none',
        borderRadius: '6px',
        cursor: 'pointer',
        marginBottom: '20px'
      }}>
        🔄 Refresh Data
      </button>

      <p style={{ marginBottom: '20px', fontSize: '16px', fontWeight: '600' }}>
        Total Subscriptions: {subscriptions.length}
      </p>

      {loading ? (
        <p>Loading...</p>
      ) : subscriptions.length === 0 ? (
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
              </tr>
            </thead>
            <tbody>
              {subscriptions.map((sub, i) => (
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
              💰 Total Revenue: {subscriptions.reduce((sum, sub) => sum + (sub.amount || 0), 0)} EGP
            </p>
          </div>
        </div>
      )}
    </div>
  );
}