// models/Expense.js
const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
        trim: true
    },
    description: {
        type: String,
        trim: true
    },
    amount: {
        type: Number,
        required: true,
        min: 0
    },
    category: {
        type: String,
        enum: ['fuel', 'maintenance', 'salary', 'insurance', 'office', 'transport', 'other'],
        default: 'other'
    },
    date: {
        type: Date,
        required: true
    },
    paymentMethod: {
        type: String,
        enum: ['cash', 'bank_transfer', 'credit_card', 'debit_card', 'check'],
        default: 'cash'
    },
    status: {
        type: String,
        enum: ['paid', 'pending', 'cancelled'],
        default: 'paid'
    },
    receipts: [{
        filename: String,
        url: String,
        uploadDate: {
            type: Date,
            default: Date.now
        }
    }],
    vendor: {
        type: String,
        trim: true
    },
    reference: {
        type: String,
        trim: true
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    approvedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    approvedAt: {
        type: Date
    }
}, {
    timestamps: true
});

// Index for better query performance
expenseSchema.index({ date: -1 });
expenseSchema.index({ category: 1 });
expenseSchema.index({ status: 1 });
expenseSchema.index({ createdBy: 1 });

module.exports = mongoose.model('Expense', expenseSchema);
