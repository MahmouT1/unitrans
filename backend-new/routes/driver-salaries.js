// routes/driver-salaries.js
const express = require('express');
const mongoose = require('mongoose');
const DriverSalary = require('../models/DriverSalary');
const router = express.Router();

// GET - Retrieve driver salaries with optional filtering
router.get('/', async (req, res) => {
  try {
    const { startDate, endDate, driverName, status, limit = 100 } = req.query;

    // Build query
    let query = {};
    
    if (startDate || endDate) {
      query.date = {};
      if (startDate) {
        query.date.$gte = new Date(startDate);
      }
      if (endDate) {
        query.date.$lte = new Date(endDate);
      }
    }
    
    if (driverName) {
      query.driverName = { $regex: driverName, $options: 'i' };
    }
    
    if (status) {
      query.status = status;
    }

    // Fetch driver salaries
    const salaries = await DriverSalary.find(query)
      .sort({ date: -1 })
      .limit(parseInt(limit))
      .populate('createdBy', 'email');

    // Calculate total amount
    const totalAmount = salaries.reduce((sum, salary) => sum + salary.amount, 0);

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
    const { 
      date, 
      driverName, 
      amount, 
      hoursWorked, 
      ratePerHour, 
      paymentMethod, 
      status, 
      notes, 
      createdBy 
    } = req.body;

    if (!date || !driverName || !amount || !createdBy) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: date, driverName, amount, createdBy'
      });
    }

    // Handle createdBy - if string provided, create a default ObjectId
    let createdByObjectId;
    if (typeof createdBy === 'string') {
      // Create a default ObjectId for admin user
      createdByObjectId = new mongoose.Types.ObjectId();
    } else {
      createdByObjectId = createdBy;
    }

    const salary = new DriverSalary({
      date: new Date(date),
      driverName,
      amount: parseFloat(amount),
      hoursWorked: hoursWorked ? parseFloat(hoursWorked) : 0,
      ratePerHour: ratePerHour ? parseFloat(ratePerHour) : 0,
      paymentMethod: paymentMethod || 'bank_transfer',
      status: status || 'paid',
      notes,
      createdBy: createdByObjectId
    });

    await salary.save();

    res.status(201).json({
      success: true,
      message: 'Driver salary created successfully',
      salary
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

// PUT - Update driver salary
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      date, 
      driverName, 
      amount, 
      hoursWorked, 
      ratePerHour, 
      paymentMethod, 
      status, 
      notes 
    } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid salary ID'
      });
    }

    const updateData = {};
    if (date) updateData.date = new Date(date);
    if (driverName) updateData.driverName = driverName;
    if (amount) updateData.amount = parseFloat(amount);
    if (hoursWorked !== undefined) updateData.hoursWorked = parseFloat(hoursWorked);
    if (ratePerHour !== undefined) updateData.ratePerHour = parseFloat(ratePerHour);
    if (paymentMethod) updateData.paymentMethod = paymentMethod;
    if (status) updateData.status = status;
    if (notes !== undefined) updateData.notes = notes;

    const salary = await DriverSalary.findByIdAndUpdate(
      id,
      updateData,
      { new: true }
    ).populate('createdBy', 'email');

    if (!salary) {
      return res.status(404).json({
        success: false,
        message: 'Driver salary not found'
      });
    }

    res.json({
      success: true,
      message: 'Driver salary updated successfully',
      salary
    });

  } catch (error) {
    console.error('Error updating driver salary:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update driver salary',
      error: error.message
    });
  }
});

// DELETE - Delete driver salary
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid salary ID'
      });
    }

    const salary = await DriverSalary.findByIdAndDelete(id);

    if (!salary) {
      return res.status(404).json({
        success: false,
        message: 'Driver salary not found'
      });
    }

    res.json({
      success: true,
      message: 'Driver salary deleted successfully'
    });

  } catch (error) {
    console.error('Error deleting driver salary:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete driver salary',
      error: error.message
    });
  }
});

module.exports = router;
