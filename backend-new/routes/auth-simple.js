const express = require('express');
const router = express.Router();
const { MongoClient } = require('mongodb');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const dbName = process.env.MONGODB_DB_NAME || 'student_portal';

// Simple login endpoint
router.post('/login', async (req, res) => {
  let client;
  
  try {
    console.log('🔐 Auth Simple: Login attempt for', req.body.email);
    
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    // Connect to MongoDB
    client = new MongoClient(mongoUri);
    await client.connect();
    const db = client.db(dbName);
    
    // Find user in users collection
    const user = await db.collection('users').findOne({ email: email.toLowerCase() });
    
    if (!user) {
      console.log('❌ Auth Simple: User not found:', email);
      return res.status(401).json({
        success: false,
        message: 'Account not found. Please check your email or register first.'
      });
    }

    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password);
    
    if (!isValidPassword) {
      console.log('❌ Auth Simple: Invalid password for:', email);
      return res.status(401).json({
        success: false,
        message: 'Invalid password. Please try again.'
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user._id, 
        email: user.email, 
        role: user.role 
      },
      process.env.JWT_SECRET || 'fallback-secret-key',
      { expiresIn: '7d' }
    );

    console.log('✅ Auth Simple: Login successful for', email, 'with role', user.role);

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        role: user.role
      }
    });

  } catch (error) {
    console.error('❌ Auth Simple: Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login'
    });
  } finally {
    if (client) {
      await client.close();
    }
  }
});

// Simple register endpoint
router.post('/register', async (req, res) => {
  let client;
  
  try {
    console.log('📝 Auth Simple: Register attempt for', req.body.email);
    
    const { email, password, fullName, role = 'student' } = req.body;
    
    if (!email || !password || !fullName) {
      return res.status(400).json({
        success: false,
        message: 'All fields are required'
      });
    }

    // Connect to MongoDB
    client = new MongoClient(mongoUri);
    await client.connect();
    const db = client.db(dbName);
    
    // Check if user already exists
    const existingUser = await db.collection('users').findOne({ email: email.toLowerCase() });
    
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'Account already exists with this email'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);
    
    // Create new user
    const newUser = {
      email: email.toLowerCase(),
      password: hashedPassword,
      fullName,
      role,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    const result = await db.collection('users').insertOne(newUser);
    
    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: result.insertedId, 
        email: newUser.email, 
        role: newUser.role 
      },
      process.env.JWT_SECRET || 'fallback-secret-key',
      { expiresIn: '7d' }
    );

    console.log('✅ Auth Simple: Registration successful for', email);

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      token,
      user: {
        id: result.insertedId,
        email: newUser.email,
        fullName: newUser.fullName,
        role: newUser.role
      }
    });

  } catch (error) {
    console.error('❌ Auth Simple: Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during registration'
    });
  } finally {
    if (client) {
      await client.close();
    }
  }
});

module.exports = router;
