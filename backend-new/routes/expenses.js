// routes/expenses.js
const express = require('express');
const mongoose = require('mongoose');
const Expense = require('../models/Expense');
const router = express.Router();

// GET - Retrieve expenses with optional filtering
router.get('/', async (req, res) => {
  try {
    const { startDate, endDate, category, status, vendor, limit = 100 } = req.query;

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
    
    if (category) {
      query.category = category;
    }
    
    if (status) {
      query.status = status;
    }

    if (vendor) {
      query.vendor = { $regex: vendor, $options: 'i' };
    }

    // Fetch expenses
    const expenses = await Expense.find(query)
      .sort({ date: -1 })
      .limit(parseInt(limit))
      .populate('createdBy', 'email')
      .populate('approvedBy', 'email');

    // Calculate total amount
    const totalAmount = expenses.reduce((sum, expense) => sum + expense.amount, 0);

    // Get statistics by category
    const categoryStats = await Expense.aggregate([
      { $match: query },
      {
        $group: {
          _id: '$category',
          total: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      }
    ]);

    res.json({
      success: true,
      expenses,
      totalAmount,
      count: expenses.length,
      categoryStats
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
    const { 
      title,
      description,
      amount, 
      category,
      date,
      paymentMethod, 
      status,
      vendor,
      reference,
      receipts,
      createdBy 
    } = req.body;

    if (!title || !amount || !date || !createdBy) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: title, amount, date, createdBy'
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

    const expense = new Expense({
      title,
      description,
      amount: parseFloat(amount),
      category: category || 'other',
      date: new Date(date),
      paymentMethod: paymentMethod || 'cash',
      status: status || 'paid',
      vendor,
      reference,
      receipts: receipts || [],
      createdBy: createdByObjectId
    });

    await expense.save();

    res.status(201).json({
      success: true,
      message: 'Expense created successfully',
      expense
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

// PUT - Update expense
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      title,
      description,
      amount, 
      category,
      date,
      paymentMethod, 
      status,
      vendor,
      reference,
      receipts
    } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid expense ID'
      });
    }

    const updateData = {};
    if (title) updateData.title = title;
    if (description !== undefined) updateData.description = description;
    if (amount) updateData.amount = parseFloat(amount);
    if (category) updateData.category = category;
    if (date) updateData.date = new Date(date);
    if (paymentMethod) updateData.paymentMethod = paymentMethod;
    if (status) updateData.status = status;
    if (vendor !== undefined) updateData.vendor = vendor;
    if (reference !== undefined) updateData.reference = reference;
    if (receipts) updateData.receipts = receipts;

    const expense = await Expense.findByIdAndUpdate(
      id,
      updateData,
      { new: true }
    ).populate('createdBy', 'email')
     .populate('approvedBy', 'email');

    if (!expense) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found'
      });
    }

    res.json({
      success: true,
      message: 'Expense updated successfully',
      expense
    });

  } catch (error) {
    console.error('Error updating expense:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update expense',
      error: error.message
    });
  }
});

// DELETE - Delete expense
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid expense ID'
      });
    }

    const expense = await Expense.findByIdAndDelete(id);

    if (!expense) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found'
      });
    }

    res.json({
      success: true,
      message: 'Expense deleted successfully'
    });

  } catch (error) {
    console.error('Error deleting expense:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete expense',
      error: error.message
    });
  }
});

// PUT - Approve expense
router.put('/:id/approve', async (req, res) => {
  try {
    const { id } = req.params;
    const { approvedBy } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid expense ID'
      });
    }

    if (!approvedBy) {
      return res.status(400).json({
        success: false,
        message: 'Approver ID is required'
      });
    }

    const expense = await Expense.findByIdAndUpdate(
      id,
      { 
        approvedBy,
        approvedAt: new Date(),
        status: 'paid'
      },
      { new: true }
    ).populate('createdBy', 'email')
     .populate('approvedBy', 'email');

    if (!expense) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found'
      });
    }

    res.json({
      success: true,
      message: 'Expense approved successfully',
      expense
    });

  } catch (error) {
    console.error('Error approving expense:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to approve expense',
      error: error.message
    });
  }
});

module.exports = router;
