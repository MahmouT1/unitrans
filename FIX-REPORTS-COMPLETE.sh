#!/bin/bash

echo "🔧 إصلاح صفحة Reports كاملة"
echo "=============================================="

cd /var/www/unitrans/backend-new/routes

# Fix expenses.js to use MongoDB directly
cat > expenses.js << 'EOF'
const express = require('express');
const router = express.Router();

// GET - Retrieve expenses
router.get('/', async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const { getDatabase } = require('../lib/mongodb-simple-connection');
    const db = await getDatabase();
    
    let query = {};
    if (startDate || endDate) {
      query.date = {};
      if (startDate) query.date.$gte = new Date(startDate);
      if (endDate) query.date.$lte = new Date(endDate);
    }
    
    const expenses = await db.collection('expenses')
      .find(query)
      .sort({ date: -1 })
      .toArray();
    
    const totalAmount = expenses.reduce((sum, exp) => sum + (exp.amount || 0), 0);
    
    res.json({
      success: true,
      expenses,
      totalAmount,
      count: expenses.length
    });
    
  } catch (error) {
    console.error('Error fetching expenses:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch expenses',
      error: error.message
    });
  }
});

// POST - Create new expense
router.post('/', async (req, res) => {
  try {
    const {  title, description, amount, category, date, paymentMethod, vendor } = req.body;
    
    if (!amount || !date) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: amount, date'
      });
    }
    
    const { getDatabase } = require('../lib/mongodb-simple-connection');
    const db = await getDatabase();
    
    const expense = {
      title: title || 'Side Expense',
      description,
      amount: parseFloat(amount),
      category: category || 'other',
      date: new Date(date),
      paymentMethod: paymentMethod || 'cash',
      status: 'paid',
      vendor,
      createdAt: new Date()
    };
    
    const result = await db.collection('expenses').insertOne(expense);
    
    res.status(201).json({
      success: true,
      message: 'Expense created successfully',
      expense: { ...expense, _id: result.insertedId }
    });
    
  } catch (error) {
    console.error('Error creating expense:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create expense',
      error: error.message
    });
  }
});

module.exports = router;
EOF

# Fix driver-salaries.js to use MongoDB directly
cat > driver-salaries.js << 'EOF'
const express = require('express');
const router = express.Router();

// GET - Retrieve driver salaries
router.get('/', async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const { getDatabase } = require('../lib/mongodb-simple-connection');
    const db = await getDatabase();
    
    let query = {};
    if (startDate || endDate) {
      query.date = {};
      if (startDate) query.date.$gte = new Date(startDate);
      if (endDate) query.date.$lte = new Date(endDate);
    }
    
    const salaries = await db.collection('salaries')
      .find(query)
      .sort({ date: -1 })
      .toArray();
    
    const totalAmount = salaries.reduce((sum, sal) => sum + (sal.amount || 0), 0);
    
    res.json({
      success: true,
      salaries,
      totalAmount,
      count: salaries.length
    });
    
  } catch (error) {
    console.error('Error fetching driver salaries:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch driver salaries',
      error: error.message
    });
  }
});

// POST - Create new driver salary
router.post('/', async (req, res) => {
  try {
    const { date, driverName, amount, hoursWorked, ratePerHour, paymentMethod, notes } = req.body;
    
    if (!date || !driverName || !amount) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: date, driverName, amount'
      });
    }
    
    const { getDatabase } = require('../lib/mongodb-simple-connection');
    const db = await getDatabase();
    
    const salary = {
      date: new Date(date),
      driverName,
      amount: parseFloat(amount),
      hoursWorked: hoursWorked ? parseFloat(hoursWorked) : 0,
      ratePerHour: ratePerHour ? parseFloat(ratePerHour) : 0,
      paymentMethod: paymentMethod || 'bank_transfer',
      status: 'paid',
      notes,
      createdAt: new Date()
    };
    
    const result = await db.collection('salaries').insertOne(salary);
    
    res.status(201).json({
      success: true,
      message: 'Driver salary created successfully',
      salary: { ...salary, _id: result.insertedId }
    });
    
  } catch (error) {
    console.error('Error creating driver salary:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create driver salary',
      error: error.message
    });
  }
});

module.exports = router;
EOF

echo "✅ Backend routes updated"

# Create frontend API routes
cd /var/www/unitrans/frontend-new/app/api

mkdir -p expenses
cat > expenses/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get('startDate');
    const endDate = searchParams.get('endDate');
    
    const backendUrl = 'http://localhost:3001';
    let url = `${backendUrl}/api/expenses`;
    
    if (startDate || endDate) {
      const params = new URLSearchParams();
      if (startDate) params.append('startDate', startDate);
      if (endDate) params.append('endDate', endDate);
      url += `?${params.toString()}`;
    }
    
    const response = await fetch(url);
    const data = await response.json();
    return NextResponse.json(data);
    
  } catch (error) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    const backendUrl = 'http://localhost:3001';
    
    const response = await fetch(`${backendUrl}/api/expenses`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    
    const data = await response.json();
    return NextResponse.json(data);
    
  } catch (error) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
EOF

mkdir -p driver-salaries
cat > driver-salaries/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get('startDate');
    const endDate = searchParams.get('endDate');
    
    const backendUrl = 'http://localhost:3001';
    let url = `${backendUrl}/api/driver-salaries`;
    
    if (startDate || endDate) {
      const params = new URLSearchParams();
      if (startDate) params.append('startDate', startDate);
      if (endDate) params.append('endDate', endDate);
      url += `?${params.toString()}`;
    }
    
    const response = await fetch(url);
    const data = await response.json();
    return NextResponse.json(data);
    
  } catch (error) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    const backendUrl = 'http://localhost:3001';
    
    const response = await fetch(`${backendUrl}/api/driver-salaries`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    
    const data = await response.json();
    return NextResponse.json(data);
    
  } catch (error) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
EOF

echo "✅ Frontend API routes created"

# Restart services
cd /var/www/unitrans

pm2 restart unitrans-backend && \
sleep 2 && \
cd frontend-new && \
pm2 stop unitrans-frontend && \
rm -rf .next && \
npm run build && \
pm2 restart unitrans-frontend && \
pm2 save && \
echo "" && \
echo "✅ Reports Page Fixed!" && \
echo "" && \
echo "📸 افتح المتصفح واختبر:" && \
echo "1. unibus.online/admin/reports" && \
echo "2. يجب أن تظهر الاشتراكات في Revenue" && \
echo "3. Forms: Side Expenses & Driver Salaries تعمل"
