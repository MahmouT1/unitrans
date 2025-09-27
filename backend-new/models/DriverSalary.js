// models/DriverSalary.js
const mongoose = require('mongoose');

const driverSalarySchema = new mongoose.Schema({
    driverName: {
        type: String,
        required: true,
        trim: true
    },
    date: {
        type: Date,
        required: true
    },
    amount: {
        type: Number,
        required: true,
        min: 0
    },
    hoursWorked: {
        type: Number,
        default: 0,
        min: 0
    },
    ratePerHour: {
        type: Number,
        default: 0,
        min: 0
    },
    paymentMethod: {
        type: String,
        enum: ['cash', 'bank_transfer', 'credit_card', 'debit_card'],
        default: 'bank_transfer'
    },
    status: {
        type: String,
        enum: ['paid', 'pending', 'cancelled'],
        default: 'paid'
    },
    notes: {
        type: String,
        trim: true
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    }
}, {
    timestamps: true
});

// Index for better query performance
driverSalarySchema.index({ date: -1 });
driverSalarySchema.index({ driverName: 1 });
driverSalarySchema.index({ status: 1 });

module.exports = mongoose.model('DriverSalary', driverSalarySchema);
