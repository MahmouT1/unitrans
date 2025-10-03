// routes/subscriptions.js
const express = require('express');
const Subscription = require('../models/Subscription');
const Student = require('../models/Student');
const authMiddleware = require('../middleware/auth');
const { body, validationResult } = require('express-validator');

const router = express.Router();

// Get all subscriptions (for admin page)
router.get('/', async (req, res) => {
    try {
        const { getDatabase } = require('../lib/mongodb-simple-connection');
        const db = await getDatabase();
        
        // Fetch all subscriptions
        const subscriptions = await db.collection('subscriptions')
            .find({})
            .sort({ createdAt: -1 })
            .toArray();
        
        res.json({
            success: true,
            subscriptions: subscriptions
        });
        
    } catch (error) {
        console.error('Error fetching all subscriptions:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch subscriptions',
            error: error.message
        });
    }
});

// Create new subscription (for payment form)
router.post('/', async (req, res) => {
    try {
        const { getDatabase } = require('../lib/mongodb-simple-connection');
        const db = await getDatabase();
        
        const {
            studentEmail,
            studentName,
            amount,
            subscriptionType,
            paymentMethod,
            status = 'active'
        } = req.body;
        
        if (!studentEmail || !studentName || !amount) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: studentEmail, studentName, amount'
            });
        }
        
        const subscription = {
            studentEmail,
            studentName,
            amount: parseFloat(amount),
            subscriptionType: subscriptionType || 'monthly',
            paymentMethod: paymentMethod || 'Cash',
            status: status,
            startDate: new Date(),
            endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // +30 days
            confirmationDate: new Date(),
            renewalDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            remainingDays: 30,
            createdAt: new Date(),
            updatedAt: new Date()
        };
        
        const result = await db.collection('subscriptions').insertOne(subscription);
        
        res.status(201).json({
            success: true,
            message: 'Subscription created successfully',
            subscription: {
                ...subscription,
                _id: result.insertedId
            }
        });
        
    } catch (error) {
        console.error('Error creating subscription:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create subscription',
            error: error.message
        });
    }
});

// Get student's subscription
router.get('/my-subscription', authMiddleware, async (req, res) => {
    try {
        if (req.user.role !== 'student') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Students only.'
            });
        }

        const student = await Student.findOne({ userId: req.user._id });
        if (!student) {
            return res.status(404).json({
                success: false,
                message: 'Student profile not found'
            });
        }

        const subscription = await Subscription.findOne({ studentId: student._id })
            .sort({ createdAt: -1 }); // Get latest subscription

        if (!subscription) {
            return res.json({
                success: true,
                subscription: null,
                message: 'No subscription found'
            });
        }

        res.json({
            success: true,
            subscription
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to get subscription',
            error: error.message
        });
    }
});

// Request new subscription
router.post('/request', [
    authMiddleware,
    body('planType').isIn(['Basic', 'Standard', 'Premium']),
    body('amount').isNumeric().isFloat({ min: 0 }),
    body('paymentMethod').isIn(['cash', 'bank_transfer', 'credit_card', 'debit_card'])
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: 'Validation errors',
                errors: errors.array()
            });
        }

        if (req.user.role !== 'student') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Students only.'
            });
        }

        const student = await Student.findOne({ userId: req.user._id });
        if (!student) {
            return res.status(404).json({
                success: false,
                message: 'Student profile not found'
            });
        }

        const { planType, amount, paymentMethod } = req.body;

        // Check if there's already a pending subscription
        const existingPendingSubscription = await Subscription.findOne({
            studentId: student._id,
            status: 'Pending'
        });

        if (existingPendingSubscription) {
            return res.status(400).json({
                success: false,
                message: 'You already have a pending subscription request'
            });
        }

        const subscription = new Subscription({
            studentId: student._id,
            planType,
            amount,
            paymentMethod,
            status: 'Pending'
        });

        await subscription.save();

        res.status(201).json({
            success: true,
            message: 'Subscription request submitted successfully',
            subscription
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to submit subscription request',
            error: error.message
        });
    }
});

// Get all subscription applications (Admin only)
router.get('/applications', authMiddleware, async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admins only.'
            });
        }

        const { status, page = 1, limit = 10 } = req.query;

        const query = {};
        if (status) {
            query.status = status;
        }

        const subscriptions = await Subscription.find(query)
            .populate({
                path: 'studentId',
                select: 'fullName studentId userId',
                populate: {
                    path: 'userId',
                    select: 'email'
                }
            })
            .sort({ createdAt: -1 })
            .limit(limit * 1)
            .skip((page - 1) * limit);

        const total = await Subscription.countDocuments(query);

        res.json({
            success: true,
            subscriptions,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / limit)
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to get subscription applications',
            error: error.message
        });
    }
});

// Confirm subscription (Admin only)
router.put('/confirm/:subscriptionId', [
    authMiddleware,
    body('startDate').isISO8601(),
    body('renewalDate').isISO8601()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: 'Validation errors',
                errors: errors.array()
            });
        }

        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admins only.'
            });
        }

        const { subscriptionId } = req.params;
        const { startDate, renewalDate } = req.body;

        const subscription = await Subscription.findById(subscriptionId);
        if (!subscription) {
            return res.status(404).json({
                success: false,
                message: 'Subscription not found'
            });
        }

        if (subscription.status !== 'Pending') {
            return res.status(400).json({
                success: false,
                message: 'Subscription is not in pending status'
            });
        }

        subscription.status = 'Active';
        subscription.confirmationDate = new Date(startDate);
        subscription.renewalDate = new Date(renewalDate);
        subscription.paymentHistory.push({
            amount: subscription.amount,
            paymentDate: new Date(),
            method: subscription.paymentMethod,
            status: 'completed'
        });

        await subscription.save();

        res.json({
            success: true,
            message: 'Subscription confirmed successfully',
            subscription
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to confirm subscription',
            error: error.message
        });
    }
});

// Cancel subscription (Admin only)
router.put('/cancel/:subscriptionId', authMiddleware, async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admins only.'
            });
        }

        const { subscriptionId } = req.params;

        const subscription = await Subscription.findById(subscriptionId);
        if (!subscription) {
            return res.status(404).json({
                success: false,
                message: 'Subscription not found'
            });
        }

        subscription.status = 'Cancelled';
        await subscription.save();

        res.json({
            success: true,
            message: 'Subscription cancelled successfully',
            subscription
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to cancel subscription',
            error: error.message
        });
    }
});

// Process payment (Admin only)
router.post('/payment/:subscriptionId', [
    authMiddleware,
    body('amount').isNumeric().isFloat({ min: 0 }),
    body('paymentMethod').isIn(['cash', 'bank_transfer', 'credit_card', 'debit_card'])
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: 'Validation errors',
                errors: errors.array()
            });
        }

        if (req.user.role !== 'admin' && req.user.role !== 'supervisor') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admins and supervisors only.'
            });
        }

        const { subscriptionId } = req.params;
        const { amount, paymentMethod } = req.body;

        const subscription = await Subscription.findById(subscriptionId);
        if (!subscription) {
            return res.status(404).json({
                success: false,
                message: 'Subscription not found'
            });
        }

        subscription.paymentHistory.push({
            amount,
            paymentDate: new Date(),
            method: paymentMethod,
            status: 'completed'
        });

        // Extend renewal date by one month
        const currentRenewalDate = subscription.renewalDate || new Date();
        const newRenewalDate = new Date(currentRenewalDate);
        newRenewalDate.setMonth(newRenewalDate.getMonth() + 1);
        subscription.renewalDate = newRenewalDate;

        if (subscription.status === 'Expired') {
            subscription.status = 'Active';
        }

        await subscription.save();

        res.json({
            success: true,
            message: 'Payment processed successfully',
            subscription
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to process payment',
            error: error.message
        });
    }
});

// Delete subscription by ID
router.delete('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { getDatabase } = require('../lib/mongodb-simple-connection');
        const { ObjectId } = require('mongodb');
        const db = await getDatabase();
        
        // Delete subscription
        const result = await db.collection('subscriptions').deleteOne({
            _id: new ObjectId(id)
        });
        
        if (result.deletedCount === 1) {
            res.json({
                success: true,
                message: 'Subscription deleted successfully'
            });
        } else {
            res.status(404).json({
                success: false,
                message: 'Subscription not found'
            });
        }
        
    } catch (error) {
        console.error('Error deleting subscription:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete subscription',
            error: error.message
        });
    }
});

// Get student subscription summary by email
router.get('/student', async (req, res) => {
    try {
        const { email } = req.query;
        
        if (!email) {
            return res.status(400).json({
                success: false,
                message: 'Email parameter is required'
            });
        }

        const { getDatabase } = require('../lib/mongodb-simple-connection');
        const db = await getDatabase();
        
        // Find all subscriptions for this student email
        const subscriptions = await db.collection('subscriptions')
            .find({ studentEmail: email })
            .sort({ createdAt: -1 })
            .toArray();
        
        if (!subscriptions || subscriptions.length === 0) {
            return res.json({
                success: true,
                subscription: null,
                message: 'No subscriptions found for this student'
            });
        }
        
        // Calculate totals
        const totalPaid = subscriptions.reduce((sum, sub) => sum + (sub.amount || 0), 0);
        const totalPayments = subscriptions.length;
        
        // Get latest subscription for dates
        const latestSub = subscriptions[0];
        
        // Determine status
        let status = 'active';
        if (totalPaid < 2000) {
            status = 'partial';
        }
        
        const subscriptionSummary = {
            totalPaid: totalPaid,
            confirmationDate: latestSub.startDate || latestSub.createdAt,
            renewalDate: latestSub.endDate,
            status: status,
            totalPayments: totalPayments,
            subscriptions: subscriptions
        };
        
        res.json({
            success: true,
            subscription: subscriptionSummary
        });
        
    } catch (error) {
        console.error('Error fetching student subscription:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch student subscription',
            error: error.message
        });
    }
});

// Get subscription statistics (Admin only)
router.get('/stats', authMiddleware, async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Admins only.'
            });
        }

        const stats = await Subscription.aggregate([
            {
                $group: {
                    _id: '$status',
                    count: { $sum: 1 },
                    totalRevenue: { $sum: '$amount' }
                }
            }
        ]);

        const planStats = await Subscription.aggregate([
            {
                $match: { status: 'Active' }
            },
            {
                $group: {
                    _id: '$planType',
                    count: { $sum: 1 },
                    revenue: { $sum: '$amount' }
                }
            }
        ]);

        const monthlyRevenue = await Subscription.aggregate([
            {
                $match: {
                    status: 'Active',
                    confirmationDate: { $gte: new Date(new Date().getFullYear(), 0, 1) }
                }
            },
            {
                $group: {
                    _id: {
                        year: { $year: '$confirmationDate' },
                        month: { $month: '$confirmationDate' }
                    },
                    revenue: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            },
            {
                $sort: { '_id.year': 1, '_id.month': 1 }
            }
        ]);

        res.json({
            success: true,
            stats: {
                statusBreakdown: stats,
                planBreakdown: planStats,
                monthlyRevenue
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to get subscription statistics',
            error: error.message
        });
    }
});

module.exports = router;