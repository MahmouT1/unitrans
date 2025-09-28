// Simple API service without axios dependency

// Base URL configuration
const getBaseUrl = () => {
  if (typeof window !== 'undefined' && window.location.hostname === 'unibus.online') {
    return 'https://unibus.online:3001';
  }
  return 'http://localhost:3001';
};

// Helper function for API calls
const apiRequest = async (endpoint, options = {}) => {
  const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
  
  const defaultOptions = {
    headers: {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` })
    },
  };
  
  const mergedOptions = {
    ...defaultOptions,
    ...options,
    headers: {
      ...defaultOptions.headers,
      ...options.headers,
    },
  };
  
  try {
    const response = await fetch(`${getBaseUrl()}${endpoint}`, mergedOptions);
    
    if (response.status === 401) {
      if (typeof window !== 'undefined') {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        window.location.href = '/auth';
      }
    }
    
    const data = await response.json();
    return { ...data, status: response.status, ok: response.ok };
  } catch (error) {
    console.error('API Request Error:', error);
    throw error;
  }
};

// Auth API
export const authAPI = {
  login: async (credentials) => {
    return apiRequest('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify(credentials)
    });
  },

  register: async (userData) => {
    return apiRequest('/api/auth/register', {
      method: 'POST', 
      body: JSON.stringify(userData)
    });
  },

  checkUser: async (email) => {
    return apiRequest(`/api/auth/check-user?email=${email}`);
  }
};

// Student API  
export const studentAPI = {
  getProfile: async (email) => {
    return apiRequest(`/api/students/data?email=${email}`);
  },

  updateProfile: async (studentData) => {
    return apiRequest('/api/students/data', {
      method: 'POST',
      body: JSON.stringify(studentData)
    });
  },

  generateQRCode: async (email) => {
    return apiRequest(`/api/students/generate-qr?email=${email}`);
  },

  getAttendance: async (email) => {
    return apiRequest(`/api/students/attendance?email=${email}`);
  }
};

// Admin API
export const adminAPI = {
  getDashboardStats: async () => {
    return apiRequest('/api/admin/dashboard/stats');
  },

  getStudents: async () => {
    return apiRequest('/api/admin/students');
  },

  searchStudents: async (query) => {
    return apiRequest(`/api/admin/students/search?q=${query}`);
  }
};

// Attendance API
export const attendanceAPI = {
  scanQR: async (qrData) => {
    return apiRequest('/api/attendance/scan', {
      method: 'POST',
      body: JSON.stringify(qrData)
    });
  },

  getRecords: async () => {
    return apiRequest('/api/attendance/records');
  },

  getTodayAttendance: async () => {
    return apiRequest('/api/attendance/today');
  }
};

// Transportation API  
export const transportationAPI = {
  getSchedule: async () => {
    return apiRequest('/api/transportation/schedule');
  },

  updateSchedule: async (scheduleData) => {
    return apiRequest('/api/transportation/schedule', {
      method: 'PUT',
      body: JSON.stringify(scheduleData)
    });
  }
};

// Default export
export default {
  authAPI,
  studentAPI, 
  adminAPI,
  attendanceAPI,
  transportationAPI
};
