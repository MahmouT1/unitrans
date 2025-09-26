// routes/admin-dashboard.js
const express = require('express');
const router = express.Router();

// Get dashboard statistics
router.get('/stats', async (req, res) => {
  try {
    const db = req.app.locals.db;
    if (!db) {
      return res.status(500).json({
        success: false,
        message: 'Database connection not available'
      });
    }

    // Get total students count
    const totalStudents = await db.collection('students').countDocuments({});

    // Get total attendance count
    const totalAttendance = await db.collection('attendance').countDocuments({});

    // Get today's attendance
    const today = new Date();
    const startOfDay = new Date(today);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(today);
    endOfDay.setHours(23, 59, 59, 999);

    const todayAttendance = await db.collection('attendance').countDocuments({
      date: {
        $gte: startOfDay,
        $lte: endOfDay
      }
    });

    // Get active shifts count
    const activeShifts = await db.collection('shifts').countDocuments({
      status: 'open'
    });

    // Get recent activity (last 10 attendance records)
    const recentActivity = await db.collection('attendance')
      .find({})
      .sort({ date: -1 })
      .limit(10)
      .toArray();

    res.json({
      success: true,
      stats: {
        totalStudents,
        totalAttendance,
        todayAttendance,
        activeShifts,
        recentActivity: recentActivity.map(record => ({
          student: record.studentName || 'Unknown Student',
          time: new Date(record.date).toLocaleString(),
          location: record.station || 'Unknown Station'
        }))
      }
    });

  } catch (error) {
    console.error('Dashboard stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to load dashboard statistics',
      error: error.message
    });
  }
});

module.exports = router;
