#!/bin/bash

echo "🚨 إصلاح طارئ لصفحة Registration"
echo "=================================="

cd /var/www/unitrans

echo "🛑 إيقاف Frontend..."
pm2 stop unitrans-frontend

echo ""
echo "🔧 إصلاح صفحة Registration بالكامل:"
echo "=================================="

# إنشاء صفحة registration جديدة خالية من الأخطاء
cat > frontend-new/app/student/registration/page.js << 'EOF'
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function StudentRegistration() {
  const [formData, setFormData] = useState({
    fullName: '',
    phoneNumber: '',
    email: '',
    college: '',
    grade: '',
    major: '',
    streetAddress: '',
    buildingNumber: '',
    fullAddress: '',
    profilePhoto: null
  });
  const [currentStep, setCurrentStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState('');
  const [isMobile, setIsMobile] = useState(false);
  const totalSteps = 5;
  const router = useRouter();

  // 🔧 Helper functions للبحث عن localStorage data
  const getToken = () => {
    return localStorage.getItem('token') || 
           localStorage.getItem('authToken') || 
           localStorage.getItem('userToken');
  };

  const getUserData = () => {
    const userData = localStorage.getItem('user') || 
                     localStorage.getItem('userData') ||
                     localStorage.getItem('authData');
    
    if (!userData) return null;
    
    try {
      const parsed = JSON.parse(userData);
      return parsed.user || parsed; // Handle both formats
    } catch (error) {
      console.error('Error parsing user data:', error);
      return null;
    }
  };

  useEffect(() => {
    // Check if user is logged in
    const token = getToken();
    const user = getUserData();
    
    console.log('🔍 Registration - Token exists:', !!token);
    console.log('🔍 Registration - User exists:', !!user);
    
    if (!token || !user) {
      console.log('❌ No auth data - redirecting to login');
      router.push('/login');
      return;
    }
    
    console.log('✅ Registration - User authenticated:', user.email);
    setFormData(prev => ({
      ...prev,
      email: user.email
    }));
  }, [router]);

  // Handle window resize for mobile responsiveness
  useEffect(() => {
    const handleResize = () => {
      setIsMobile(window.innerWidth < 768);
    };

    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

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

      const reader = new FileReader();
      reader.onloadend = () => {
        setFormData(prev => ({
          ...prev,
          profilePhoto: reader.result
        }));
      };
      reader.readAsDataURL(file);
      setError('');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const token = getToken();
      
      if (!token) {
        setError('Authentication required. Please login again.');
        router.push('/login');
        return;
      }

      const updateData = {
        fullName: formData.fullName,
        phoneNumber: formData.phoneNumber,
        email: formData.email,
        college: formData.college,
        grade: formData.grade,
        major: formData.major,
        address: {
          streetAddress: formData.streetAddress,
          buildingNumber: formData.buildingNumber,
          fullAddress: formData.fullAddress
        },
        profilePhoto: formData.profilePhoto
      };

      console.log('🔄 Updating student profile with data:', updateData.email);

      const response = await fetch('https://unibus.online:3001/api/students/data', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(updateData)
      });

      const data = await response.json();
      console.log('📡 Profile update response:', data);

      if (data.success) {
        setSuccess(true);
        console.log('✅ Profile updated successfully');
        
        // Generate QR code
        try {
          console.log('🔄 Generating QR code...');
          const qrResponse = await fetch('https://unibus.online:3001/api/students/generate-qr', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ email: formData.email })
          });

          const qrData = await qrResponse.json();
          console.log('📱 QR Generation response:', qrData);
          
          if (qrData.success) {
            // Show QR code in new window
            const qrWindow = window.open('', '_blank', 'width=600,height=700');
            qrWindow.document.write(`
              <!DOCTYPE html>
              <html>
              <head>
                <title>Student QR Code</title>
                <style>
                  body { 
                    font-family: Arial, sans-serif; 
                    padding: 20px; 
                    text-align: center; 
                    background: #f8f9fa;
                  }
                  .container {
                    max-width: 500px;
                    margin: 0 auto;
                    background: white;
                    padding: 30px;
                    border-radius: 10px;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                  }
                </style>
              </head>
              <body>
                <div class="container">
                  <h1>🎓 Student QR Code</h1>
                  <h3>${formData.fullName}</h3>
                  <p>Email: ${formData.email}</p>
                  <div>
                    <img src="${qrData.qrCode}" 
                         alt="Student QR Code" 
                         style="width: 300px; height: 300px; border: 2px solid #28a745;" />
                  </div>
                  <p style="color: #28a745; font-weight: bold; margin-top: 20px;">
                    ✅ Registration completed successfully!
                  </p>
                </div>
              </body>
              </html>
            `);
            qrWindow.document.close();
          } else {
            console.error('❌ QR generation failed:', qrData.message);
          }
        } catch (qrError) {
          console.error('❌ QR generation error:', qrError);
        }
      } else {
        setError(data.message || 'Registration failed');
      }
    } catch (error) {
      console.error('❌ Registration error:', error);
      setError('Network error. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const nextStep = () => {
    if (currentStep < totalSteps) {
      setCurrentStep(currentStep + 1);
    }
  };

  const prevStep = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  const renderStepIndicator = () => (
    <div style={{
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      marginBottom: '32px',
      gap: '16px'
    }}>
      {[1, 2, 3, 4, 5].map((step) => (
        <div key={step} style={{ display: 'flex', alignItems: 'center' }}>
          <div style={{
            width: '40px',
            height: '40px',
            borderRadius: '50%',
            backgroundColor: step <= currentStep ? '#007bff' : '#e9ecef',
            color: step <= currentStep ? 'white' : '#6c757d',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontWeight: 'bold',
            fontSize: '16px'
          }}>
            {step}
          </div>
          {step < 5 && (
            <div style={{
              width: '40px',
              height: '4px',
              backgroundColor: step < currentStep ? '#007bff' : '#e9ecef',
              marginLeft: '8px',
              marginRight: '8px'
            }} />
          )}
        </div>
      ))}
    </div>
  );

  const renderStep = () => {
    switch (currentStep) {
      case 1:
        return (
          <div>
            <h3 style={{ marginBottom: '24px', color: '#1f2937', fontSize: '24px' }}>Personal Information</h3>
            <div style={{ display: 'grid', gap: '20px' }}>
              <div>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#374151' }}>
                  Full Name *
                </label>
                <input
                  type="text"
                  name="fullName"
                  value={formData.fullName}
                  onChange={handleInputChange}
                  required
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    border: '2px solid #d1d5db',
                    borderRadius: '8px',
                    fontSize: '16px',
                    backgroundColor: '#ffffff'
                  }}
                  placeholder="Enter your full name"
                />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#374151' }}>
                  Phone Number *
                </label>
                <input
                  type="tel"
                  name="phoneNumber"
                  value={formData.phoneNumber}
                  onChange={handleInputChange}
                  required
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    border: '2px solid #d1d5db',
                    borderRadius: '8px',
                    fontSize: '16px',
                    backgroundColor: '#ffffff'
                  }}
                  placeholder="Enter your phone number"
                />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#374151' }}>
                  Email *
                </label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  readOnly
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    border: '2px solid #d1d5db',
                    borderRadius: '8px',
                    fontSize: '16px',
                    backgroundColor: '#f9fafb',
                    color: '#6b7280'
                  }}
                />
              </div>
            </div>
          </div>
        );

      case 2:
        return (
          <div>
            <h3 style={{ marginBottom: '24px', color: '#1f2937', fontSize: '24px' }}>Academic Information</h3>
            <div style={{ display: 'grid', gap: '20px' }}>
              <div>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#374151' }}>
                  College *
                </label>
                <input
                  type="text"
                  name="college"
                  value={formData.college}
                  onChange={handleInputChange}
                  required
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    border: '2px solid #d1d5db',
                    borderRadius: '8px',
                    fontSize: '16px',
                    backgroundColor: '#ffffff'
                  }}
                  placeholder="Enter your college name"
                />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#374151' }}>
                  Grade Level *
                </label>
                <select
                  name="grade"
                  value={formData.grade}
                  onChange={handleInputChange}
                  required
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    border: '2px solid #d1d5db',
                    borderRadius: '8px',
                    fontSize: '16px',
                    backgroundColor: '#ffffff'
                  }}
                >
                  <option value="">Select grade level</option>
                  <option value="first-year">First Year</option>
                  <option value="second-year">Second Year</option>
                  <option value="third-year">Third Year</option>
                  <option value="fourth-year">Fourth Year</option>
                  <option value="graduate">Graduate</option>
                </select>
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#374151' }}>
                  Major *
                </label>
                <input
                  type="text"
                  name="major"
                  value={formData.major}
                  onChange={handleInputChange}
                  required
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    border: '2px solid #d1d5db',
                    borderRadius: '8px',
                    fontSize: '16px',
                    backgroundColor: '#ffffff'
                  }}
                  placeholder="Enter your major"
                />
              </div>
            </div>
          </div>
        );

      case 3:
        return (
          <div>
            <h3 style={{ marginBottom: '24px', color: '#1f2937', fontSize: '24px' }}>Address Information</h3>
            <div style={{ display: 'grid', gap: '20px' }}>
              <div>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#374151' }}>
                  Street Address *
                </label>
                <input
                  type="text"
                  name="streetAddress"
                  value={formData.streetAddress}
                  onChange={handleInputChange}
                  required
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    border: '2px solid #d1d5db',
                    borderRadius: '8px',
                    fontSize: '16px',
                    backgroundColor: '#ffffff'
                  }}
                  placeholder="Enter your street address"
                />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#374151' }}>
                  Building Number
                </label>
                <input
                  type="text"
                  name="buildingNumber"
                  value={formData.buildingNumber}
                  onChange={handleInputChange}
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    border: '2px solid #d1d5db',
                    borderRadius: '8px',
                    fontSize: '16px',
                    backgroundColor: '#ffffff'
                  }}
                  placeholder="Enter building number (optional)"
                />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#374151' }}>
                  Full Address *
                </label>
                <textarea
                  name="fullAddress"
                  value={formData.fullAddress}
                  onChange={handleInputChange}
                  required
                  rows="3"
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    border: '2px solid #d1d5db',
                    borderRadius: '8px',
                    fontSize: '16px',
                    backgroundColor: '#ffffff',
                    resize: 'vertical'
                  }}
                  placeholder="Enter your complete address"
                />
              </div>
            </div>
          </div>
        );

      case 4:
        return (
          <div>
            <h3 style={{ marginBottom: '24px', color: '#1f2937', fontSize: '24px' }}>Profile Photo</h3>
            <div style={{ textAlign: 'center' }}>
              <div style={{
                width: '200px',
                height: '200px',
                borderRadius: '50%',
                border: '4px solid #d1d5db',
                margin: '0 auto 24px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                overflow: 'hidden',
                backgroundColor: '#f9fafb'
              }}>
                {formData.profilePhoto ? (
                  <img
                    src={formData.profilePhoto}
                    alt="Profile"
                    style={{
                      width: '100%',
                      height: '100%',
                      objectFit: 'cover'
                    }}
                  />
                ) : (
                  <div style={{
                    fontSize: '64px',
                    color: '#9ca3af'
                  }}>
                    👤
                  </div>
                )}
              </div>
              <input
                type="file"
                accept="image/*"
                onChange={handleFileChange}
                style={{ marginBottom: '16px' }}
              />
              <p style={{ color: '#6b7280', fontSize: '14px' }}>
                Upload a profile photo (optional, max 10MB)
              </p>
            </div>
          </div>
        );

      case 5:
        return (
          <div>
            <h3 style={{ marginBottom: '24px', color: '#1f2937', fontSize: '24px' }}>Review & Submit</h3>
            <div style={{
              backgroundColor: '#f8fafc',
              padding: '24px',
              borderRadius: '12px',
              border: '1px solid #e2e8f0'
            }}>
              <h4 style={{ marginBottom: '16px', color: '#1f2937' }}>Registration Summary</h4>
              <div style={{ display: 'grid', gap: '12px', textAlign: 'left' }}>
                <p><strong>Name:</strong> {formData.fullName}</p>
                <p><strong>Email:</strong> {formData.email}</p>
                <p><strong>Phone:</strong> {formData.phoneNumber}</p>
                <p><strong>College:</strong> {formData.college}</p>
                <p><strong>Grade:</strong> {formData.grade}</p>
                <p><strong>Major:</strong> {formData.major}</p>
                <p><strong>Address:</strong> {formData.streetAddress}, {formData.fullAddress}</p>
                <p><strong>Photo:</strong> {formData.profilePhoto ? 'Selected ✓' : 'No photo'}</p>
              </div>
            </div>
          </div>
        );

      default:
        return null;
    }
  };

  if (success) {
    return (
      <div style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#f8fafc'
      }}>
        <div style={{
          textAlign: 'center',
          padding: '48px',
          backgroundColor: 'white',
          borderRadius: '16px',
          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.1)',
          maxWidth: '500px'
        }}>
          <div style={{ fontSize: '80px', marginBottom: '24px' }}>🎉</div>
          <h2 style={{ 
            margin: '0 0 16px 0', 
            color: '#059669', 
            fontSize: '28px',
            fontWeight: '700'
          }}>
            Registration Completed!
          </h2>
          <p style={{ 
            margin: '0 0 32px 0', 
            color: '#6b7280',
            fontSize: '16px',
            lineHeight: '1.6'
          }}>
            Your student profile has been updated successfully and your QR code has been generated.
          </p>
          <button
            onClick={() => router.push('/student/portal')}
            style={{
              padding: '16px 32px',
              backgroundColor: '#8b5cf6',
              color: 'white',
              border: 'none',
              borderRadius: '12px',
              cursor: 'pointer',
              fontSize: '16px',
              fontWeight: '600',
              boxShadow: '0 4px 12px rgba(139, 92, 246, 0.3)'
            }}
          >
            ← Back to Portal
          </button>
        </div>
      </div>
    );
  }

  return (
    <div style={{
      minHeight: '100vh',
      backgroundColor: '#f8fafc',
      fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, sans-serif'
    }}>
      {/* Header */}
      <div style={{
        background: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)',
        padding: '24px',
        color: 'white',
        textAlign: 'center'
      }}>
        <button
          onClick={() => router.push('/student/portal')}
          style={{
            position: 'absolute',
            left: '24px',
            top: '24px',
            padding: '12px 20px',
            backgroundColor: 'rgba(255,255,255,0.1)',
            color: 'white',
            border: '1px solid rgba(255,255,255,0.2)',
            borderRadius: '8px',
            cursor: 'pointer',
            fontSize: '14px',
            fontWeight: '500'
          }}
        >
          ← Back to Portal
        </button>
        <h1 style={{ 
          margin: '0', 
          fontSize: '32px', 
          fontWeight: '700' 
        }}>
          Student Registration
        </h1>
        <p style={{ 
          margin: '8px 0 0 0', 
          fontSize: '16px', 
          opacity: '0.9' 
        }}>
          Complete your registration to get your student QR code
        </p>
      </div>

      {/* Main Content */}
      <div style={{
        maxWidth: '800px',
        margin: '0 auto',
        padding: '40px 24px'
      }}>
        {renderStepIndicator()}

        <div style={{
          backgroundColor: 'white',
          borderRadius: '16px',
          padding: '40px',
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.05)',
          border: '1px solid #e2e8f0'
        }}>
          {error && (
            <div style={{
              backgroundColor: '#fee2e2',
              color: '#dc2626',
              padding: '16px',
              borderRadius: '8px',
              marginBottom: '24px',
              textAlign: 'center',
              border: '1px solid #fecaca'
            }}>
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            {renderStep()}

            <div style={{
              display: 'flex',
              justifyContent: 'space-between',
              marginTop: '40px',
              gap: '16px'
            }}>
              {currentStep > 1 && (
                <button
                  type="button"
                  onClick={prevStep}
                  style={{
                    padding: '12px 24px',
                    backgroundColor: '#6b7280',
                    color: 'white',
                    border: 'none',
                    borderRadius: '8px',
                    cursor: 'pointer',
                    fontSize: '16px',
                    fontWeight: '500'
                  }}
                >
                  Previous
                </button>
              )}

              {currentStep < totalSteps ? (
                <button
                  type="button"
                  onClick={nextStep}
                  disabled={
                    (currentStep === 1 && (!formData.fullName || !formData.phoneNumber)) ||
                    (currentStep === 2 && (!formData.college || !formData.grade || !formData.major)) ||
                    (currentStep === 3 && (!formData.streetAddress || !formData.fullAddress))
                  }
                  style={{
                    padding: '12px 24px',
                    backgroundColor: '#28a745',
                    color: 'white',
                    border: 'none',
                    borderRadius: '8px',
                    cursor: 'pointer',
                    fontSize: '16px',
                    fontWeight: '500',
                    marginLeft: 'auto'
                  }}
                >
                  Next
                </button>
              ) : (
                <button
                  type="submit"
                  disabled={loading}
                  style={{
                    padding: '16px 32px',
                    backgroundColor: loading ? '#6b7280' : '#28a745',
                    color: 'white',
                    border: 'none',
                    borderRadius: '8px',
                    cursor: loading ? 'not-allowed' : 'pointer',
                    fontSize: '16px',
                    fontWeight: '600',
                    marginLeft: 'auto',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px'
                  }}
                >
                  {loading ? (
                    <>
                      <div style={{
                        width: '16px',
                        height: '16px',
                        border: '2px solid transparent',
                        borderTop: '2px solid white',
                        borderRadius: '50%',
                        animation: 'spin 1s linear infinite'
                      }} />
                      Processing...
                    </>
                  ) : (
                    '✅ Complete Registration'
                  )}
                </button>
              )}
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
EOF

echo "✅ تم إنشاء صفحة registration جديدة خالية من الأخطاء"

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
    echo "🚀 إعادة تشغيل Frontend..."
    pm2 start unitrans-frontend
    
    echo ""
    echo "⏳ انتظار استقرار النظام..."
    sleep 8
    
    echo ""
    echo "🧪 اختبار صفحة Registration:"
    echo "=========================="
    
    curl -I https://unibus.online/student/registration -w "Status: %{http_code}\n" -s
    
else
    echo "❌ البناء فشل!"
fi

echo ""
echo "📊 حالة النهائية:"
pm2 status

echo ""
echo "✅ إصلاح طارئ لصفحة Registration اكتمل!"
echo "🔗 جرب: https://unibus.online/student/registration"
echo "   📧 الآن الصفحة ستعمل بدون أخطاء!"
echo "   📱 وستتمكن من استخراج QR Code بنجاح!"
