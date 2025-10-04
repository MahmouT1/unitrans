'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function TransportationManagement() {
  const [transportationData, setTransportationData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingSchedule, setEditingSchedule] = useState(null);
  const [formData, setFormData] = useState({
    name: '',
    time: '',
    location: '',
    googleMapsLink: '',
    parking: '',
    capacity: '',
    status: 'Active',
    days: [],
    description: ''
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const router = useRouter();

  useEffect(() => {
    fetchTransportationData();
  }, []);

  const fetchTransportationData = async () => {
    try {
      setLoading(true);
      const response = await fetch('/api/transportation');

      if (response.ok) {
        const data = await response.json();
        if (data.success) {
          setTransportationData(data.transportation || data.data || []);
        } else {
          console.error('Transportation fetch error:', data.message);
          setTransportationData([]);
        }
      } else {
        console.error('Transportation fetch failed:', response.status);
        setTransportationData([]);
      }
    } catch (error) {
      console.error('Error fetching transportation data:', error);
      setTransportationData([]);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    
    if (name === 'days') {
      const currentDays = formData.days || [];
      if (checked) {
        setFormData(prev => ({
          ...prev,
          days: [...currentDays, value]
        }));
      } else {
        setFormData(prev => ({
          ...prev,
          days: currentDays.filter(day => day !== value)
        }));
      }
    } else {
      setFormData(prev => ({
        ...prev,
        [name]: value
      }));
    }
    
    // Clear messages when user starts typing
    if (error) setError('');
    if (success) setSuccess('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setError('');
    setSuccess('');

    // Validate required fields
    if (!formData.name || !formData.time || !formData.location || !formData.parking || !formData.capacity) {
      setError('Please fill in all required fields');
      setSubmitting(false);
      return;
    }

    try {
      const method = editingSchedule ? 'PUT' : 'POST';
      const url = editingSchedule 
        ? `/api/transportation/${editingSchedule._id}` 
        : '/api/transportation';

      const submitData = {
        ...formData,
        capacity: parseInt(formData.capacity),
        days: formData.days || []
      };

      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(submitData),
      });

      const data = await response.json();

      if (response.ok && data.success) {
        setSuccess(editingSchedule ? 'Transportation schedule updated successfully!' : 'Transportation schedule added successfully!');
        
        // Reset form
        setFormData({
          name: '',
          time: '',
          location: '',
          googleMapsLink: '',
          parking: '',
          capacity: '',
          status: 'Active',
          days: [],
          description: ''
        });
        setShowForm(false);
        setEditingSchedule(null);
        
        // Refresh the data
        fetchTransportationData();
      } else {
        setError(data.message || data.error || 'Failed to save transportation schedule');
      }
    } catch (error) {
      console.error('Error saving transportation schedule:', error);
      setError('Network error. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleEdit = (schedule) => {
    setEditingSchedule(schedule);
    setFormData({
      name: schedule.name || '',
      time: schedule.time || '',
      location: schedule.location || '',
      googleMapsLink: schedule.googleMapsLink || '',
      parking: schedule.parking || '',
      capacity: schedule.capacity?.toString() || '',
      status: schedule.status || 'Active',
      days: schedule.days || [],
      description: schedule.description || ''
    });
    setShowForm(true);
  };

  const handleDelete = async (id) => {
    if (!confirm('Are you sure you want to delete this transportation schedule?')) {
      return;
    }

    try {
      let response;
      try {
        response = await fetch(`http://localhost:3001/api/transportation/${id}`, {
          method: 'DELETE',
        });
      } catch (backendError) {
        response = await fetch(`/api/transportation/${id}`, {
          method: 'DELETE',
        });
      }

      if (response.ok) {
        setSuccess('Transportation schedule deleted successfully!');
        fetchTransportationData();
      } else {
        setError('Failed to delete transportation schedule');
      }
    } catch (error) {
      console.error('Error deleting transportation schedule:', error);
      setError('Network error. Please try again.');
    }
  };

  const cancelForm = () => {
    setShowForm(false);
    setEditingSchedule(null);
    setFormData({
      name: '',
      time: '',
      location: '',
      googleMapsLink: '',
      parking: '',
      capacity: '',
      status: 'Active',
      days: [],
      description: ''
    });
    setError('');
    setSuccess('');
  };

  const openGoogleMaps = (link) => {
    if (link) {
      window.open(link, '_blank');
    }
  };

  const dayOptions = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

  if (loading) {
    return (
      <div style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#f3f4f6'
      }}>
        <div style={{
          textAlign: 'center',
          padding: '40px',
          backgroundColor: 'white',
          borderRadius: '12px',
          boxShadow: '0 4px 12px rgba(0, 0, 0, 0.1)'
        }}>
          <div style={{
            width: '50px',
            height: '50px',
            border: '4px solid #e2e8f0',
            borderTop: '4px solid #3b82f6',
            borderRadius: '50%',
            animation: 'spin 1s linear infinite',
            margin: '0 auto 20px'
          }} />
          <h3 style={{ margin: '0 0 10px 0', color: '#1f2937' }}>Loading Transportation Data...</h3>
          <p style={{ margin: '0', color: '#6b7280' }}>Please wait while we fetch the schedules.</p>
        </div>
      </div>
    );
  }

  return (
    <div style={{
      minHeight: '100vh',
      backgroundColor: '#f8fafc',
      padding: '24px'
    }}>
      {/* Header */}
      <div style={{
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        borderRadius: '16px',
        padding: '32px',
        marginBottom: '30px',
        color: 'white',
        position: 'relative',
        overflow: 'hidden'
      }}>
        <div style={{
          position: 'absolute',
          top: '-50%',
          right: '-50%',
          width: '200%',
          height: '200%',
          background: 'radial-gradient(circle, rgba(255, 255, 255, 0.1) 0%, transparent 70%)',
          pointerEvents: 'none'
        }} />
        
        <div style={{ textAlign: 'center', position: 'relative', zIndex: 1 }}>
          <h1 style={{ margin: '0', fontSize: '28px' }}>🚌 Transportation Management</h1>
          <p style={{ margin: '5px 0 0 0', opacity: '0.9' }}>
            Manage bus schedules, station locations, and Google Maps links
          </p>
        </div>
      </div>

      {/* Main Content */}
      <div style={{ 
        maxWidth: '1200px',
        margin: '0 auto'
      }}>
        {/* Success/Error Messages */}
        {success && (
          <div style={{
            backgroundColor: '#d1fae5',
            border: '1px solid #a7f3d0',
            color: '#065f46',
            padding: '12px 16px',
            borderRadius: '8px',
            marginBottom: '20px',
            fontSize: '14px'
          }}>
            ✅ {success}
          </div>
        )}

        {error && (
          <div style={{
            backgroundColor: '#fed7d7',
            border: '1px solid #feb2b2',
            color: '#c53030',
            padding: '12px 16px',
            borderRadius: '8px',
            marginBottom: '20px',
            fontSize: '14px'
          }}>
            ❌ {error}
          </div>
        )}

        {/* Add New Schedule Button */}
        <div style={{
          backgroundColor: 'white',
          borderRadius: '12px',
          padding: '24px',
          marginBottom: '30px',
          boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}>
          <div>
            <h2 style={{ margin: '0 0 8px 0', fontSize: '20px', color: '#1f2937' }}>
              Transportation Schedules & Stations
            </h2>
            <p style={{ margin: '0', color: '#6b7280' }}>
              Add and manage transportation schedules with Google Maps integration
            </p>
          </div>
          <button
            onClick={() => setShowForm(!showForm)}
            style={{
              padding: '12px 24px',
              backgroundColor: '#3b82f6',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              fontSize: '16px',
              fontWeight: '500',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '8px'
            }}
          >
            <span>{showForm ? '❌' : '➕'}</span>
            {showForm ? 'Cancel' : 'Add New Schedule'}
          </button>
        </div>

        {/* Add/Edit Form */}
        {showForm && (
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '30px',
            marginBottom: '30px',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
          }}>
            <h3 style={{ margin: '0 0 20px 0', fontSize: '18px', color: '#1f2937' }}>
              {editingSchedule ? 'Edit Transportation Schedule' : 'Add New Transportation Schedule'}
            </h3>
            
            <form onSubmit={handleSubmit}>
              <div style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
                gap: '20px',
                marginBottom: '20px'
              }}>
                {/* Schedule Name */}
                <div>
                  <label style={{
                    display: 'block',
                    marginBottom: '8px',
                    fontSize: '14px',
                    fontWeight: '600',
                    color: '#374151'
                  }}>
                    Schedule Name *
                  </label>
                  <input
                    type="text"
                    name="name"
                    value={formData.name}
                    onChange={handleInputChange}
                    required
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: '2px solid #e5e7eb',
                      borderRadius: '8px',
                      fontSize: '16px',
                      boxSizing: 'border-box'
                    }}
                    placeholder="e.g., Morning Route to Campus"
                  />
                </div>

                {/* Departure Time */}
                <div>
                  <label style={{
                    display: 'block',
                    marginBottom: '8px',
                    fontSize: '14px',
                    fontWeight: '600',
                    color: '#374151'
                  }}>
                    Departure Time *
                  </label>
                  <input
                    type="time"
                    name="time"
                    value={formData.time}
                    onChange={handleInputChange}
                    required
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: '2px solid #e5e7eb',
                      borderRadius: '8px',
                      fontSize: '16px',
                      boxSizing: 'border-box'
                    }}
                  />
                </div>

                {/* Location */}
                <div>
                  <label style={{
                    display: 'block',
                    marginBottom: '8px',
                    fontSize: '14px',
                    fontWeight: '600',
                    color: '#374151'
                  }}>
                    Station Location *
                  </label>
                  <input
                    type="text"
                    name="location"
                    value={formData.location}
                    onChange={handleInputChange}
                    required
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: '2px solid #e5e7eb',
                      borderRadius: '8px',
                      fontSize: '16px',
                      boxSizing: 'border-box'
                    }}
                    placeholder="e.g., Downtown Central Station"
                  />
                </div>

                {/* Google Maps Link */}
                <div>
                  <label style={{
                    display: 'block',
                    marginBottom: '8px',
                    fontSize: '14px',
                    fontWeight: '600',
                    color: '#374151'
                  }}>
                    Google Maps Link
                  </label>
                  <input
                    type="url"
                    name="googleMapsLink"
                    value={formData.googleMapsLink}
                    onChange={handleInputChange}
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: '2px solid #e5e7eb',
                      borderRadius: '8px',
                      fontSize: '16px',
                      boxSizing: 'border-box'
                    }}
                    placeholder="https://maps.google.com/..."
                  />
                </div>

                {/* Parking Area */}
                <div>
                  <label style={{
                    display: 'block',
                    marginBottom: '8px',
                    fontSize: '14px',
                    fontWeight: '600',
                    color: '#374151'
                  }}>
                    Parking Area *
                  </label>
                  <input
                    type="text"
                    name="parking"
                    value={formData.parking}
                    onChange={handleInputChange}
                    required
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: '2px solid #e5e7eb',
                      borderRadius: '8px',
                      fontSize: '16px',
                      boxSizing: 'border-box'
                    }}
                    placeholder="e.g., Main Parking Lot A"
                  />
                </div>

                {/* Capacity */}
                <div>
                  <label style={{
                    display: 'block',
                    marginBottom: '8px',
                    fontSize: '14px',
                    fontWeight: '600',
                    color: '#374151'
                  }}>
                    Bus Capacity *
                  </label>
                  <input
                    type="number"
                    name="capacity"
                    value={formData.capacity}
                    onChange={handleInputChange}
                    required
                    min="1"
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: '2px solid #e5e7eb',
                      borderRadius: '8px',
                      fontSize: '16px',
                      boxSizing: 'border-box'
                    }}
                    placeholder="e.g., 150"
                  />
                </div>

                {/* Status */}
                <div>
                  <label style={{
                    display: 'block',
                    marginBottom: '8px',
                    fontSize: '14px',
                    fontWeight: '600',
                    color: '#374151'
                  }}>
                    Status
                  </label>
                  <select
                    name="status"
                    value={formData.status}
                    onChange={handleInputChange}
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: '2px solid #e5e7eb',
                      borderRadius: '8px',
                      fontSize: '16px',
                      boxSizing: 'border-box'
                    }}
                  >
                    <option value="Active">🟢 Active</option>
                    <option value="Inactive">🔴 Inactive</option>
                    <option value="Maintenance">🔧 Under Maintenance</option>
                  </select>
                </div>
              </div>

              {/* Days of Week */}
              <div style={{ marginBottom: '20px' }}>
                <label style={{
                  display: 'block',
                  marginBottom: '12px',
                  fontSize: '14px',
                  fontWeight: '600',
                  color: '#374151'
                }}>
                  Operating Days
                </label>
                <div style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(100px, 1fr))',
                  gap: '10px'
                }}>
                  {dayOptions.map(day => (
                    <label key={day} style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px',
                      cursor: 'pointer',
                      padding: '8px 12px',
                      backgroundColor: formData.days?.includes(day) ? '#dbeafe' : '#f9fafb',
                      border: '1px solid #e5e7eb',
                      borderRadius: '6px',
                      fontSize: '14px'
                    }}>
                      <input
                        type="checkbox"
                        name="days"
                        value={day}
                        checked={formData.days?.includes(day) || false}
                        onChange={handleInputChange}
                        style={{ margin: 0 }}
                      />
                      {day}
                    </label>
                  ))}
                </div>
              </div>

              {/* Description */}
              <div style={{ marginBottom: '20px' }}>
                <label style={{
                  display: 'block',
                  marginBottom: '8px',
                  fontSize: '14px',
                  fontWeight: '600',
                  color: '#374151'
                }}>
                  Additional Notes
                </label>
                <textarea
                  name="description"
                  value={formData.description}
                  onChange={handleInputChange}
                  rows="3"
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    border: '2px solid #e5e7eb',
                    borderRadius: '8px',
                    fontSize: '16px',
                    boxSizing: 'border-box',
                    resize: 'vertical'
                  }}
                  placeholder="Any additional information about this route..."
                />
              </div>

              <div style={{ display: 'flex', gap: '12px' }}>
                <button
                  type="submit"
                  disabled={submitting}
                  style={{
                    padding: '12px 24px',
                    backgroundColor: submitting ? '#9ca3af' : '#3b82f6',
                    color: 'white',
                    border: 'none',
                    borderRadius: '8px',
                    fontSize: '16px',
                    fontWeight: '500',
                    cursor: submitting ? 'not-allowed' : 'pointer'
                  }}
                >
                  {submitting ? 'Saving...' : (editingSchedule ? 'Update Schedule' : 'Add Schedule')}
                </button>
                <button
                  type="button"
                  onClick={cancelForm}
                  style={{
                    padding: '12px 24px',
                    backgroundColor: '#6b7280',
                    color: 'white',
                    border: 'none',
                    borderRadius: '8px',
                    fontSize: '16px',
                    fontWeight: '500',
                    cursor: 'pointer'
                  }}
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Transportation Schedules List */}
        <div style={{
          backgroundColor: 'white',
          borderRadius: '12px',
          padding: '30px',
          boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
        }}>
          <h3 style={{ margin: '0 0 20px 0', fontSize: '18px', color: '#1f2937' }}>
            Current Transportation Schedules ({transportationData.length})
          </h3>
          
          {transportationData.length === 0 ? (
            <div style={{
              textAlign: 'center',
              padding: '40px',
              color: '#6b7280'
            }}>
              <div style={{ fontSize: '48px', marginBottom: '16px' }}>🚌</div>
              <p>No transportation schedules found. Add your first schedule above.</p>
            </div>
          ) : (
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))',
              gap: '20px'
            }}>
              {transportationData.map((schedule, index) => (
                <div key={schedule._id || index} style={{
                  border: '1px solid #e5e7eb',
                  borderRadius: '12px',
                  padding: '20px',
                  transition: 'all 0.2s ease',
                  backgroundColor: '#fafafa'
                }}>
                  <div style={{ marginBottom: '16px' }}>
                    <h4 style={{ 
                      margin: '0 0 8px 0', 
                      fontSize: '18px', 
                      color: '#1f2937',
                      fontWeight: '600'
                    }}>
                      🚌 {schedule.name}
                    </h4>
                    
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                      <span style={{ fontSize: '14px' }}>🕒</span>
                      <span style={{ fontSize: '14px', color: '#6b7280' }}>{schedule.time}</span>
                    </div>
                    
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                      <span style={{ fontSize: '14px' }}>📍</span>
                      <span style={{ fontSize: '14px', color: '#6b7280' }}>{schedule.location}</span>
                    </div>

                    {schedule.googleMapsLink && (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                        <span style={{ fontSize: '14px' }}>🗺️</span>
                        <button
                          onClick={() => openGoogleMaps(schedule.googleMapsLink)}
                          style={{
                            fontSize: '14px',
                            color: '#3b82f6',
                            background: 'none',
                            border: 'none',
                            cursor: 'pointer',
                            textDecoration: 'underline'
                          }}
                        >
                          View on Google Maps
                        </button>
                      </div>
                    )}
                    
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                      <span style={{ fontSize: '14px' }}>🅿️</span>
                      <span style={{ fontSize: '14px', color: '#6b7280' }}>{schedule.parking}</span>
                    </div>
                    
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                      <span style={{ fontSize: '14px' }}>👥</span>
                      <span style={{ fontSize: '14px', color: '#6b7280' }}>{schedule.capacity} students</span>
                    </div>

                    {schedule.days && schedule.days.length > 0 && (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                        <span style={{ fontSize: '14px' }}>📅</span>
                        <span style={{ fontSize: '14px', color: '#6b7280' }}>
                          {schedule.days.join(', ')}
                        </span>
                      </div>
                    )}
                    
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px' }}>
                      <span style={{ fontSize: '14px' }}>
                        {schedule.status === 'Active' ? '🟢' : schedule.status === 'Maintenance' ? '🔧' : '🔴'}
                      </span>
                      <span style={{ 
                        fontSize: '14px', 
                        color: schedule.status === 'Active' ? '#10b981' : schedule.status === 'Maintenance' ? '#f59e0b' : '#ef4444',
                        fontWeight: '500' 
                      }}>
                        {schedule.status}
                      </span>
                    </div>

                    {schedule.description && (
                      <div style={{
                        backgroundColor: '#f3f4f6',
                        padding: '8px 12px',
                        borderRadius: '6px',
                        marginBottom: '16px'
                      }}>
                        <span style={{ fontSize: '14px', color: '#4b5563' }}>
                          {schedule.description}
                        </span>
                      </div>
                    )}
                  </div>
                  
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button
                      onClick={() => handleEdit(schedule)}
                      style={{
                        flex: 1,
                        padding: '10px 16px',
                        backgroundColor: '#3b82f6',
                        color: 'white',
                        border: 'none',
                        borderRadius: '8px',
                        fontSize: '14px',
                        fontWeight: '500',
                        cursor: 'pointer'
                      }}
                    >
                      ✏️ Edit
                    </button>
                    <button
                      onClick={() => handleDelete(schedule._id)}
                      style={{
                        flex: 1,
                        padding: '10px 16px',
                        backgroundColor: '#ef4444',
                        color: 'white',
                        border: 'none',
                        borderRadius: '8px',
                        fontSize: '14px',
                        fontWeight: '500',
                        cursor: 'pointer'
                      }}
                    >
                      🗑️ Delete
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      <style jsx>{`
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
}