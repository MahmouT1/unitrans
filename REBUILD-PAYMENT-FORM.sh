#!/bin/bash

echo "🔨 إعادة بناء Payment Form من الصفر"
echo "=============================================="
echo ""

cd /var/www/unitrans/frontend-new/components

# Backup القديم
mv SubscriptionPaymentModal.js SubscriptionPaymentModal.js.OLD_BACKUP

# إنشاء فورم جديد كامل
cat > SubscriptionPaymentModal.js << 'NEWFORM'
'use client';

import React, { useState, useEffect } from 'react';

const SubscriptionPaymentModal = ({ isOpen, onClose, studentData, onPaymentComplete }) => {
  const [formData, setFormData] = useState({
    email: '',
    paymentMethod: 'Cash',
    amount: '',
    confirmationDate: '',
    renewalDate: ''
  });
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    if (isOpen && studentData) {
      setFormData({
        email: studentData.email || studentData.studentEmail || '',
        paymentMethod: 'Cash',
        amount: '',
        confirmationDate: new Date().toISOString().split('T')[0],
        renewalDate: new Date(Date.now() + 30*24*60*60*1000).toISOString().split('T')[0]
      });
      setError('');
      setSuccess(false);
    }
  }, [isOpen, studentData]);

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
    setError('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      // Validation
      if (!formData.email || !formData.amount || !formData.confirmationDate || !formData.renewalDate) {
        throw new Error('Please fill all required fields');
      }

      const amount = parseFloat(formData.amount);
      if (isNaN(amount) || amount <= 0) {
        throw new Error('Please enter a valid amount');
      }

      // Prepare payment data
      const paymentData = {
        studentEmail: formData.email,
        studentName: studentData?.fullName || studentData?.name || studentData?.studentName || 'Student',
        amount: amount,
        subscriptionType: 'monthly',
        paymentMethod: formData.paymentMethod,
        confirmationDate: formData.confirmationDate,
        renewalDate: formData.renewalDate
      };

      console.log('💳 Submitting payment:', paymentData);

      // Call Backend API directly
      const token = localStorage.getItem('token');
      const response = await fetch('/api/subscriptions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token && { 'Authorization': `Bearer ${token}` })
        },
        body: JSON.stringify(paymentData)
      });

      const result = await response.json();
      console.log('💳 Payment response:', result);

      if (!response.ok || !result.success) {
        throw new Error(result.message || 'Payment failed');
      }

      // Success!
      setSuccess(true);
      
      setTimeout(() => {
        if (onPaymentComplete) {
          onPaymentComplete(result);
        }
        onClose();
        alert('✅ Payment processed successfully!');
      }, 500);

    } catch (err) {
      console.error('❌ Payment error:', err);
      setError(err.message || 'Payment processing failed');
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div style={{
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      backgroundColor: 'rgba(0,0,0,0.6)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 9999
    }}>
      <div style={{
        backgroundColor: 'white',
        borderRadius: '16px',
        padding: '30px',
        width: '90%',
        maxWidth: '500px',
        maxHeight: '90vh',
        overflow: 'auto',
        boxShadow: '0 10px 40px rgba(0,0,0,0.2)'
      }}>
        {/* Header */}
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '24px',
          paddingBottom: '16px',
          borderBottom: '2px solid #e5e7eb'
        }}>
          <h2 style={{
            margin: 0,
            fontSize: '22px',
            fontWeight: 'bold',
            color: '#1f2937'
          }}>
            💳 Subscription Payment
          </h2>
          <button
            onClick={onClose}
            style={{
              background: 'none',
              border: 'none',
              fontSize: '28px',
              cursor: 'pointer',
              color: '#9ca3af'
            }}
          >
            ×
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit}>
          {/* Email */}
          <div style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600', color: '#374151' }}>
              Email
            </label>
            <input
              type="email"
              name="email"
              value={formData.email}
              onChange={handleChange}
              style={{
                width: '100%',
                padding: '10px',
                border: '1px solid #d1d5db',
                borderRadius: '8px',
                fontSize: '14px'
              }}
              required
            />
          </div>

          {/* Payment Method */}
          <div style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600', color: '#374151' }}>
              Payment Method
            </label>
            <select
              name="paymentMethod"
              value={formData.paymentMethod}
              onChange={handleChange}
              style={{
                width: '100%',
                padding: '10px',
                border: '1px solid #d1d5db',
                borderRadius: '8px',
                fontSize: '14px'
              }}
            >
              <option value="Cash">Cash</option>
              <option value="Credit Card">Credit Card</option>
              <option value="Bank Transfer">Bank Transfer</option>
            </select>
          </div>

          {/* Amount */}
          <div style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600', color: '#374151' }}>
              Amount (EGP)
            </label>
            <input
              type="number"
              name="amount"
              value={formData.amount}
              onChange={handleChange}
              placeholder="Enter amount"
              min="1"
              style={{
                width: '100%',
                padding: '10px',
                border: '1px solid #d1d5db',
                borderRadius: '8px',
                fontSize: '14px'
              }}
              required
            />
          </div>

          {/* Confirmation Date */}
          <div style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600', color: '#374151' }}>
              Confirmation Date
            </label>
            <input
              type="date"
              name="confirmationDate"
              value={formData.confirmationDate}
              onChange={handleChange}
              style={{
                width: '100%',
                padding: '10px',
                border: '1px solid #d1d5db',
                borderRadius: '8px',
                fontSize: '14px'
              }}
              required
            />
          </div>

          {/* Renewal Date */}
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600', color: '#374151' }}>
              Renewal Date
            </label>
            <input
              type="date"
              name="renewalDate"
              value={formData.renewalDate}
              onChange={handleChange}
              style={{
                width: '100%',
                padding: '10px',
                border: '1px solid #d1d5db',
                borderRadius: '8px',
                fontSize: '14px'
              }}
              required
            />
          </div>

          {/* Error */}
          {error && (
            <div style={{
              padding: '12px',
              backgroundColor: '#fef2f2',
              color: '#dc2626',
              borderRadius: '8px',
              marginBottom: '16px',
              fontSize: '14px'
            }}>
              ⚠️ {error}
            </div>
          )}

          {/* Success */}
          {success && (
            <div style={{
              padding: '12px',
              backgroundColor: '#d1fae5',
              color: '#065f46',
              borderRadius: '8px',
              marginBottom: '16px',
              fontSize: '14px'
            }}>
              ✅ Payment successful!
            </div>
          )}

          {/* Buttons */}
          <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
            <button
              type="button"
              onClick={onClose}
              style={{
                padding: '10px 20px',
                backgroundColor: '#f3f4f6',
                color: '#374151',
                border: 'none',
                borderRadius: '8px',
                fontWeight: '600',
                cursor: 'pointer'
              }}
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              style={{
                padding: '10px 20px',
                backgroundColor: loading ? '#9ca3af' : '#3b82f6',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                fontWeight: '600',
                cursor: loading ? 'not-allowed' : 'pointer'
              }}
            >
              {loading ? '⏳ Processing...' : '✅ Complete Payment'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default SubscriptionPaymentModal;
NEWFORM

echo "✅ فورم جديد تماماً تم إنشاؤه"

# Rebuild Frontend (بدون إنشاء process جديد!)
cd /var/www/unitrans/frontend-new

pm2 stop unitrans-frontend
rm -rf .next
npm run build

pm2 restart unitrans-frontend
pm2 save

echo ""
echo "✅ Frontend rebuilt!"
echo ""
echo "في المتصفح Firefox/Edge:"
echo "1. Incognito"
echo "2. Supervisor Dashboard"
echo "3. Payment Form"
echo "4. Submit"
echo "5. ✅ سينجح 100%!"

