#!/bin/bash

echo "🔧 Fixing QR Code Generation Issue"

cd /home/unitrans/frontend-new

# Backup current files
cp services/api.js services/api.js.backup
cp app/student/portal/page.js app/student/portal/page.js.backup
cp app/student/registration/page.js app/student/registration/page.js.backup

# Fix services/api.js - replace profile-simple with correct endpoints
cat > services/api.js << 'EOF'
// API service for frontend
const baseURL = process.env.NEXT_PUBLIC_BACKEND_URL || (typeof window !== 'undefined' && window.location.hostname === 'unibus.online' ? 'https://unibus.online:3001' : 'http://localhost:3001');

class ApiService {
  constructor() {
    this.baseURL = baseURL;
  }

  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`;
    const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
    
    const config = {
      headers: {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` }),
        ...options.headers,
      },
      ...options,
    };

    try {
      const response = await fetch(url, config);
      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.message || `HTTP error! status: ${response.status}`);
      }
      
      return data;
    } catch (error) {
      console.error('API request failed:', error);
      throw error;
    }
  }

  // Auth API
  async login(credentials) {
    return await this.request('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify(credentials),
    });
  }

  async register(userData) {
    return await this.request('/api/auth/register', {
      method: 'POST',
      body: JSON.stringify(userData),
    });
  }

  // Student API
  async getStudentProfile(email) {
    return await this.request(`/api/students/data?email=${encodeURIComponent(email)}`);
  }

  async updateStudentProfile(profileData) {
    return await this.request('/api/students/data', {
      method: 'PUT',
      body: JSON.stringify(profileData),
    });
  }

  async generateQRCode(studentData) {
    return await this.request('/api/students/generate-qr', {
      method: 'POST',
      body: JSON.stringify({ studentData }),
    });
  }

  // Admin API
  async getStudentsForAdmin() {
    return await this.request('/api/admin/students');
  }

  async getDashboardStats() {
    return await this.request('/api/admin/dashboard/stats');
  }

  // Attendance API
  async getAttendanceRecords(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    return await this.request(`/api/attendance/all-records?${queryString}`);
  }

  // Subscription API
  async getSubscriptions() {
    return await this.request('/api/admin/subscriptions');
  }

  async createSubscription(subscriptionData) {
    return await this.request('/api/subscription/payment', {
      method: 'POST',
      body: JSON.stringify(subscriptionData),
    });
  }

  // Reports API
  async getFinancialSummary() {
    return await this.request('/api/reports/financial-summary');
  }

  // Transportation API
  async getTransportationSchedules() {
    return await this.request('/api/transportation/active/schedules');
  }

  async createTransportationSchedule(scheduleData) {
    return await this.request('/api/transportation', {
      method: 'POST',
      body: JSON.stringify(scheduleData),
    });
  }

  // Health check
  async healthCheck() {
    return await this.request('/api/health');
  }
}

const api = new ApiService();
export default api;
EOF

# Fix student portal page
cat > app/student/portal/page.js << 'EOF'
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function StudentPortal() {
  const [user, setUser] = useState(null);
  const [student, setStudent] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const router = useRouter();

  useEffect(() => {
    const loadUserData = async () => {
      try {
        const userData = localStorage.getItem('user');
        if (userData) {
          const parsedUser = JSON.parse(userData);
          setUser(parsedUser);
          
          // Load student profile from backend
          const response = await fetch(`/api/students/data?email=${encodeURIComponent(parsedUser.email)}`, {
            headers: {
              'Authorization': `Bearer ${localStorage.getItem('token')}`,
              'Content-Type': 'application/json'
            }
          });

          if (response.ok) {
            const data = await response.json();
            if (data.success && data.student) {
              setStudent(data.student);
              localStorage.setItem('student', JSON.stringify(data.student));
            }
          } else {
            console.log('Student profile not found, will need to register');
          }
        } else {
          router.push('/auth');
        }
      } catch (error) {
        console.error('Error loading user data:', error);
        setError('Failed to load user data');
      } finally {
        setLoading(false);
      }
    };

    loadUserData();
  }, [router]);

  const handleLogout = () => {
    localStorage.removeItem('user');
    localStorage.removeItem('token');
    localStorage.removeItem('student');
    router.push('/auth');
  };

  if (loading) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
      }}>
        <div style={{ 
          background: 'white', 
          padding: '40px', 
          borderRadius: '12px',
          textAlign: 'center'
        }}>
          <div style={{ fontSize: '18px', color: '#666' }}>Loading...</div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
      }}>
        <div style={{ 
          background: 'white', 
          padding: '40px', 
          borderRadius: '12px',
          textAlign: 'center'
        }}>
          <div style={{ fontSize: '18px', color: '#e74c3c', marginBottom: '20px' }}>{error}</div>
          <button 
            onClick={() => window.location.reload()}
            style={{
              padding: '10px 20px',
              background: '#3498db',
              color: 'white',
              border: 'none',
              borderRadius: '6px',
              cursor: 'pointer'
            }}
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div style={{ 
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      padding: '20px'
    }}>
      <div style={{ 
        maxWidth: '1200px', 
        margin: '0 auto',
        background: 'white',
        borderRadius: '12px',
        boxShadow: '0 10px 30px rgba(0,0,0,0.1)',
        overflow: 'hidden'
      }}>
        {/* Header */}
        <div style={{ 
          background: 'linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%)',
          color: 'white',
          padding: '30px',
          textAlign: 'center'
        }}>
          <h1 style={{ margin: '0 0 10px 0', fontSize: '28px' }}>Student Portal</h1>
          <p style={{ margin: '0', opacity: '0.9' }}>Welcome, {user?.fullName || user?.email}</p>
        </div>

        {/* Navigation */}
        <div style={{ 
          background: '#f8fafc',
          padding: '20px',
          borderBottom: '1px solid #e2e8f0'
        }}>
          <div style={{ 
            display: 'flex', 
            gap: '15px', 
            flexWrap: 'wrap',
            justifyContent: 'center'
          }}>
            <Link href="/student/portal" style={{
              padding: '12px 24px',
              background: '#4f46e5',
              color: 'white',
              textDecoration: 'none',
              borderRadius: '8px',
              fontWeight: '600'
            }}>
              🏠 Dashboard
            </Link>
            
            <Link href="/student/registration" style={{
              padding: '12px 24px',
              background: '#10b981',
              color: 'white',
              textDecoration: 'none',
              borderRadius: '8px',
              fontWeight: '600'
            }}>
              📝 Registration
            </Link>
            
            <Link href="/student/qr-generator" style={{
              padding: '12px 24px',
              background: '#f59e0b',
              color: 'white',
              textDecoration: 'none',
              borderRadius: '8px',
              fontWeight: '600'
            }}>
              📱 QR Code
            </Link>
            
            <Link href="/student/transportation" style={{
              padding: '12px 24px',
              background: '#8b5cf6',
              color: 'white',
              textDecoration: 'none',
              borderRadius: '8px',
              fontWeight: '600'
            }}>
              🚌 Transportation
            </Link>
            
            <button 
              onClick={handleLogout}
              style={{
                padding: '12px 24px',
                background: '#ef4444',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                fontWeight: '600',
                cursor: 'pointer'
              }}
            >
              🚪 Logout
            </button>
          </div>
        </div>

        {/* Content */}
        <div style={{ padding: '30px' }}>
          {student ? (
            <div>
              <h2 style={{ color: '#1f2937', marginBottom: '20px' }}>Your Profile</h2>
              <div style={{ 
                display: 'grid', 
                gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', 
                gap: '20px' 
              }}>
                <div style={{ 
                  background: '#f8fafc', 
                  padding: '20px', 
                  borderRadius: '8px',
                  border: '1px solid #e2e8f0'
                }}>
                  <h3 style={{ color: '#374151', margin: '0 0 15px 0' }}>Personal Information</h3>
                  <div style={{ display: 'grid', gap: '10px' }}>
                    <div><strong>Name:</strong> {student.fullName}</div>
                    <div><strong>Email:</strong> {student.email}</div>
                    <div><strong>Phone:</strong> {student.phoneNumber || 'Not provided'}</div>
                    <div><strong>Student ID:</strong> {student.studentId || 'Not assigned'}</div>
                  </div>
                </div>
                
                <div style={{ 
                  background: '#f8fafc', 
                  padding: '20px', 
                  borderRadius: '8px',
                  border: '1px solid #e2e8f0'
                }}>
                  <h3 style={{ color: '#374151', margin: '0 0 15px 0' }}>Academic Information</h3>
                  <div style={{ display: 'grid', gap: '10px' }}>
                    <div><strong>College:</strong> {student.college || 'Not specified'}</div>
                    <div><strong>Grade:</strong> {student.grade || 'Not specified'}</div>
                    <div><strong>Major:</strong> {student.major || 'Not specified'}</div>
                    <div><strong>Address:</strong> {student.address || 'Not provided'}</div>
                  </div>
                </div>
              </div>
              
              <div style={{ marginTop: '30px', textAlign: 'center' }}>
                <Link href="/student/qr-generator" style={{
                  display: 'inline-block',
                  padding: '15px 30px',
                  background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                  color: 'white',
                  textDecoration: 'none',
                  borderRadius: '8px',
                  fontSize: '16px',
                  fontWeight: '600',
                  boxShadow: '0 4px 15px rgba(16, 185, 129, 0.3)'
                }}>
                  📱 Generate Your QR Code
                </Link>
              </div>
            </div>
          ) : (
            <div style={{ textAlign: 'center', padding: '40px' }}>
              <h2 style={{ color: '#1f2937', marginBottom: '20px' }}>Complete Your Registration</h2>
              <p style={{ color: '#6b7280', marginBottom: '30px' }}>
                You need to complete your student registration to access all features.
              </p>
              <Link href="/student/registration" style={{
                display: 'inline-block',
                padding: '15px 30px',
                background: 'linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%)',
                color: 'white',
                textDecoration: 'none',
                borderRadius: '8px',
                fontSize: '16px',
                fontWeight: '600',
                boxShadow: '0 4px 15px rgba(59, 130, 246, 0.3)'
              }}>
                📝 Complete Registration
              </Link>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
EOF

# Fix student registration page
cat > app/student/registration/page.js << 'EOF'
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function StudentRegistration() {
  const [user, setUser] = useState(null);
  const [formData, setFormData] = useState({
    fullName: '',
    phoneNumber: '',
    college: '',
    grade: '',
    major: '',
    address: '',
    profilePhoto: null
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);
  const router = useRouter();

  useEffect(() => {
    const userData = localStorage.getItem('user');
    if (userData) {
      const parsedUser = JSON.parse(userData);
      setUser(parsedUser);
      setFormData(prev => ({
        ...prev,
        fullName: parsedUser.fullName || '',
        email: parsedUser.email || ''
      }));
    } else {
      router.push('/auth');
    }
  }, [router]);

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
      const reader = new FileReader();
      reader.onload = (e) => {
        setFormData(prev => ({
          ...prev,
          profilePhoto: e.target.result
        }));
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/students/data', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          ...formData,
          email: user.email
        })
      });

      const data = await response.json();

      if (data.success) {
        setSuccess(true);
        localStorage.setItem('student', JSON.stringify(data.student));
        setTimeout(() => {
          router.push('/student/portal');
        }, 2000);
      } else {
        setError(data.message || 'Registration failed');
      }
    } catch (error) {
      console.error('Registration error:', error);
      setError('Registration failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  if (!user) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh' 
      }}>
        <div>Loading...</div>
      </div>
    );
  }

  return (
    <div style={{ 
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      padding: '20px'
    }}>
      <div style={{ 
        maxWidth: '800px', 
        margin: '0 auto',
        background: 'white',
        borderRadius: '12px',
        boxShadow: '0 10px 30px rgba(0,0,0,0.1)',
        overflow: 'hidden'
      }}>
        {/* Header */}
        <div style={{ 
          background: 'linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%)',
          color: 'white',
          padding: '30px',
          textAlign: 'center'
        }}>
          <h1 style={{ margin: '0 0 10px 0', fontSize: '28px' }}>Student Registration</h1>
          <p style={{ margin: '0', opacity: '0.9' }}>Complete your profile to get started</p>
        </div>

        {/* Form */}
        <div style={{ padding: '30px' }}>
          {success ? (
            <div style={{ textAlign: 'center', padding: '40px' }}>
              <div style={{ fontSize: '48px', marginBottom: '20px' }}>✅</div>
              <h2 style={{ color: '#10b981', marginBottom: '10px' }}>Registration Successful!</h2>
              <p style={{ color: '#6b7280' }}>Redirecting to your portal...</p>
            </div>
          ) : (
            <form onSubmit={handleSubmit}>
              {error && (
                <div style={{ 
                  background: '#fee2e2', 
                  color: '#dc2626', 
                  padding: '12px', 
                  borderRadius: '6px', 
                  marginBottom: '20px',
                  border: '1px solid #fecaca'
                }}>
                  {error}
                </div>
              )}

              <div style={{ display: 'grid', gap: '20px' }}>
                <div>
                  <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600', color: '#374151' }}>
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
                      padding: '12px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      fontSize: '16px'
                    }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600', color: '#374151' }}>
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
                      padding: '12px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      fontSize: '16px'
                    }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600', color: '#374151' }}>
                    College *
                  </label>
                  <select
                    name="college"
                    value={formData.college}
                    onChange={handleInputChange}
                    required
                    style={{
                      width: '100%',
                      padding: '12px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      fontSize: '16px'
                    }}
                  >
                    <option value="">Select College</option>
                    <option value="الشروق">الشروق</option>
                    <option value="القاهرة">القاهرة</option>
                    <option value="عين شمس">عين شمس</option>
                    <option value="الأزهر">الأزهر</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600', color: '#374151' }}>
                    Grade *
                  </label>
                  <select
                    name="grade"
                    value={formData.grade}
                    onChange={handleInputChange}
                    required
                    style={{
                      width: '100%',
                      padding: '12px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      fontSize: '16px'
                    }}
                  >
                    <option value="">Select Grade</option>
                    <option value="first-year">First Year</option>
                    <option value="second-year">Second Year</option>
                    <option value="third-year">Third Year</option>
                    <option value="fourth-year">Fourth Year</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600', color: '#374151' }}>
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
                      padding: '12px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      fontSize: '16px'
                    }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600', color: '#374151' }}>
                    Address *
                  </label>
                  <textarea
                    name="address"
                    value={formData.address}
                    onChange={handleInputChange}
                    required
                    rows="3"
                    style={{
                      width: '100%',
                      padding: '12px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      fontSize: '16px',
                      resize: 'vertical'
                    }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600', color: '#374151' }}>
                    Profile Photo
                  </label>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleFileChange}
                    style={{
                      width: '100%',
                      padding: '12px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                      fontSize: '16px'
                    }}
                  />
                  {formData.profilePhoto && (
                    <div style={{ marginTop: '10px' }}>
                      <img 
                        src={formData.profilePhoto} 
                        alt="Preview" 
                        style={{ 
                          width: '100px', 
                          height: '100px', 
                          objectFit: 'cover', 
                          borderRadius: '6px',
                          border: '1px solid #d1d5db'
                        }} 
                      />
                    </div>
                  )}
                </div>
              </div>

              <div style={{ marginTop: '30px', textAlign: 'center' }}>
                <button
                  type="submit"
                  disabled={loading}
                  style={{
                    padding: '15px 30px',
                    background: loading ? '#9ca3af' : 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                    color: 'white',
                    border: 'none',
                    borderRadius: '8px',
                    fontSize: '16px',
                    fontWeight: '600',
                    cursor: loading ? 'not-allowed' : 'pointer',
                    boxShadow: '0 4px 15px rgba(16, 185, 129, 0.3)'
                  }}
                >
                  {loading ? 'Registering...' : 'Complete Registration'}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
EOF

# Create missing API route for students data
mkdir -p app/api/students

cat > app/api/students/data/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const email = searchParams.get('email');
    
    if (!email) {
      return NextResponse.json(
        { success: false, message: 'Email parameter is required' },
        { status: 400 }
      );
    }

    const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';
    const response = await fetch(`${backendUrl}/api/students/data?email=${encodeURIComponent(email)}`, {
      headers: {
        'Authorization': request.headers.get('authorization') || '',
        'Content-Type': 'application/json'
      }
    });

    if (response.ok) {
      const data = await response.json();
      return NextResponse.json(data);
    } else {
      const errorData = await response.json();
      return NextResponse.json(
        { success: false, message: errorData.message || 'Failed to fetch student data' },
        { status: response.status }
      );
    }
  } catch (error) {
    console.error('Student data API error:', error);
    return NextResponse.json(
      { success: false, message: 'Internal server error' },
      { status: 500 }
    );
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    
    const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';
    const response = await fetch(`${backendUrl}/api/students/data`, {
      method: 'POST',
      headers: {
        'Authorization': request.headers.get('authorization') || '',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body)
    });

    if (response.ok) {
      const data = await response.json();
      return NextResponse.json(data);
    } else {
      const errorData = await response.json();
      return NextResponse.json(
        { success: false, message: errorData.message || 'Failed to create student data' },
        { status: response.status }
      );
    }
  } catch (error) {
    console.error('Student data creation error:', error);
    return NextResponse.json(
      { success: false, message: 'Internal server error' },
      { status: 500 }
    );
  }
}

export async function PUT(request) {
  try {
    const body = await request.json();
    
    const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';
    const response = await fetch(`${backendUrl}/api/students/data`, {
      method: 'PUT',
      headers: {
        'Authorization': request.headers.get('authorization') || '',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body)
    });

    if (response.ok) {
      const data = await response.json();
      return NextResponse.json(data);
    } else {
      const errorData = await response.json();
      return NextResponse.json(
        { success: false, message: errorData.message || 'Failed to update student data' },
        { status: response.status }
      );
    }
  } catch (error) {
    console.error('Student data update error:', error);
    return NextResponse.json(
      { success: false, message: 'Internal server error' },
      { status: 500 }
    );
  }
}
EOF

# Rebuild frontend
echo "🏗️ Rebuilding frontend..."
npm run build

# Restart frontend
echo "🔄 Restarting frontend..."
pm2 stop unitrans-frontend
pm2 start "npm run start" --name "unitrans-frontend"

echo "✅ QR Code generation fix complete!"
echo "🌍 Test at: https://unibus.online/student/portal"
