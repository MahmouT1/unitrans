const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');
const mongoose = require('mongoose');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:3001', 'http://72.60.185.100:3000', 'https://unibus.online', 'https://www.unibus.online'],
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// MongoDB connection
let db;
const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const mongoDbName = process.env.DB_NAME || 'student-portal';

// Connect to MongoDB using native driver (for existing functionality)
MongoClient.connect(mongoUri)
  .then(client => {
    console.log('📡 Connected to MongoDB (Native Driver)');
    db = client.db(mongoDbName);
    app.locals.db = db;
  })
  .catch(error => {
    console.error('❌ MongoDB connection error:', error);
  });

// Connect to MongoDB using Mongoose (for new models)
mongoose.connect(`${mongoUri}/${mongoDbName}`)
  .then(() => {
    console.log('📡 Connected to MongoDB (Mongoose)');
  })
  .catch(error => {
    console.error('❌ Mongoose connection error:', error);
  });

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    message: 'Backend API Server Running',
    database: db ? 'Connected' : 'Disconnected'
  });
});

// API Routes  
app.use('/api/auth-pro', require('./routes/auth-professional')); // Professional Auth System
app.use('/auth-api', require('./routes/auth-professional')); // Proxy for frontend compatibility
app.use('/api/admin', require('./routes/admin'));
app.use('/api/students', require('./routes/students'));
app.use('/api/attendance', require('./routes/attendance'));
app.use('/api/attendance', require('./routes/attendance-tracking'));
app.use('/api/subscriptions', require('./routes/subscriptions'));
app.use('/api/transportation', require('./routes/transportation'));
app.use('/api/shifts', require('./routes/shifts'));
app.use('/api/driver-salaries', require('./routes/driver-salaries'));
app.use('/api/expenses', require('./routes/expenses'));
app.use('/api/admin/dashboard', require('./routes/admin-dashboard'));
app.use('/api/reports', require('./routes/reports'));

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('❌ Server Error:', error);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? error.message : 'Server error'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`
  });
});

app.listen(PORT, () => {
  console.log('🚀 Backend API Server Started');
  console.log(`📍 Server: http://localhost:${PORT}`);
  console.log(`📊 Health: http://localhost:${PORT}/health`);
  console.log(`🔐 Auth API: http://localhost:${PORT}/api/auth/*`);
  console.log(`👤 Admin API: http://localhost:${PORT}/api/admin/*`);
  console.log(`🎓 Students API: http://localhost:${PORT}/api/students/*`);
  console.log(`📋 Attendance API: http://localhost:${PORT}/api/attendance/*`);
  console.log(`🚌 Transportation API: http://localhost:${PORT}/api/transportation/*`);
  console.log(`💳 Subscriptions API: http://localhost:${PORT}/api/subscriptions/*`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📡 Database: ${db ? 'Connected' : 'Connecting...'}`);
});

module.exports = app;