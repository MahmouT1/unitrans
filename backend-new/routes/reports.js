// routes/reports.js
const express = require('express');
const router = express.Router();

// Get financial summary report
router.get('/financial-summary', async (req, res) => {
    try {
        const { startDate, endDate } = req.query;
        const db = req.app.locals.db;
        
        if (!db) {
            return res.status(500).json({
                success: false,
                message: 'Database connection not available'
            });
        }

        // Set default date range (current month if not provided)
        let start, end;
        if (startDate && endDate) {
            start = new Date(startDate);
            end = new Date(endDate);
        } else {
            // Default to current month
            const now = new Date();
            start = new Date(now.getFullYear(), now.getMonth(), 1);
            end = new Date(now.getFullYear(), now.getMonth() + 1, 0);
        }

        // Ensure end date includes the entire day
        end.setHours(23, 59, 59, 999);

        console.log('📊 Generating financial report for:', { start: start.toISOString(), end: end.toISOString() });

        // Get subscription revenue
        const subscriptions = await db.collection('subscriptions').find({}).toArray();
        const totalRevenue = subscriptions.reduce((sum, sub) => sum + (sub.totalPaid || 0), 0);

        // Get expenses in date range
        const expenses = await db.collection('expenses').find({
            date: { $gte: start, $lte: end }
        }).toArray();
        const totalExpenses = expenses.reduce((sum, exp) => sum + (exp.amount || 0), 0);

        // Get driver salaries in date range
        const driverSalaries = await db.collection('driversalaries').find({
            date: { $gte: start, $lte: end }
        }).toArray();
        const totalDriverSalaries = driverSalaries.reduce((sum, sal) => sum + (sal.amount || 0), 0);

        // Calculate net profit
        const netProfit = totalRevenue - totalExpenses - totalDriverSalaries;

        // Get detailed breakdown
        const expensesByCategory = await db.collection('expenses').aggregate([
            { $match: { date: { $gte: start, $lte: end } } },
            {
                $group: {
                    _id: '$category',
                    total: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            }
        ]).toArray();

        const revenueByStatus = await db.collection('subscriptions').aggregate([
            {
                $group: {
                    _id: '$status',
                    total: { $sum: '$totalPaid' },
                    count: { $sum: 1 }
                }
            }
        ]).toArray();

        res.json({
            success: true,
            report: {
                dateRange: {
                    start: start.toISOString(),
                    end: end.toISOString()
                },
                summary: {
                    totalRevenue,
                    totalExpenses,
                    totalDriverSalaries,
                    netProfit,
                    profitMargin: totalRevenue > 0 ? ((netProfit / totalRevenue) * 100).toFixed(2) : 0
                },
                breakdown: {
                    expensesByCategory,
                    revenueByStatus,
                    subscriptionsCount: subscriptions.length,
                    expensesCount: expenses.length,
                    driverSalariesCount: driverSalaries.length
                },
                details: {
                    subscriptions: subscriptions.slice(0, 10), // Latest 10
                    expenses: expenses.slice(0, 10), // Latest 10
                    driverSalaries: driverSalaries.slice(0, 10) // Latest 10
                }
            }
        });

    } catch (error) {
        console.error('Financial report error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to generate financial report',
            error: error.message
        });
    }
});

// Get revenue trend (monthly)
router.get('/revenue-trend', async (req, res) => {
    try {
        const db = req.app.locals.db;
        
        if (!db) {
            return res.status(500).json({
                success: false,
                message: 'Database connection not available'
            });
        }

        // Get revenue by month for the last 6 months
        const sixMonthsAgo = new Date();
        sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

        const revenueTrend = await db.collection('subscriptions').aggregate([
            {
                $addFields: {
                    month: { $dateToString: { format: "%Y-%m", date: "$createdAt" } }
                }
            },
            {
                $group: {
                    _id: "$month",
                    revenue: { $sum: "$totalPaid" },
                    count: { $sum: 1 }
                }
            },
            { $sort: { _id: 1 } }
        ]).toArray();

        res.json({
            success: true,
            trend: revenueTrend
        });

    } catch (error) {
        console.error('Revenue trend error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get revenue trend',
            error: error.message
        });
    }
});

// Get expense analysis
router.get('/expense-analysis', async (req, res) => {
    try {
        const { startDate, endDate } = req.query;
        const db = req.app.locals.db;
        
        if (!db) {
            return res.status(500).json({
                success: false,
                message: 'Database connection not available'
            });
        }

        // Set default date range
        let start = startDate ? new Date(startDate) : new Date(new Date().getFullYear(), new Date().getMonth(), 1);
        let end = endDate ? new Date(endDate) : new Date();
        end.setHours(23, 59, 59, 999);

        // Get expenses by category
        const expensesByCategory = await db.collection('expenses').aggregate([
            { $match: { date: { $gte: start, $lte: end } } },
            {
                $group: {
                    _id: '$category',
                    total: { $sum: '$amount' },
                    count: { $sum: 1 },
                    avgAmount: { $avg: '$amount' }
                }
            },
            { $sort: { total: -1 } }
        ]).toArray();

        // Get top expenses
        const topExpenses = await db.collection('expenses')
            .find({ date: { $gte: start, $lte: end } })
            .sort({ amount: -1 })
            .limit(10)
            .toArray();

        res.json({
            success: true,
            analysis: {
                byCategory: expensesByCategory,
                topExpenses,
                dateRange: {
                    start: start.toISOString(),
                    end: end.toISOString()
                }
            }
        });

    } catch (error) {
        console.error('Expense analysis error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to analyze expenses',
            error: error.message
        });
    }
});

module.exports = router;
