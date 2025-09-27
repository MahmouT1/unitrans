const express = require('express');
const app = express();
const shiftsRouter = require('./routes/shifts');

app.use('/api/shifts', shiftsRouter);

console.log('Testing route...');

// Create mock request and response
const req = { 
    params: { shiftId: '1758980600858' } 
};

const res = { 
    json: (data) => console.log('Response:', JSON.stringify(data, null, 2)),
    status: (code) => ({ json: (data) => console.log('Response:', JSON.stringify(data, null, 2)) })
};

// Find the attendance route handler
const attendanceRoute = shiftsRouter.stack.find(layer => 
    layer.route && layer.route.path === '/:shiftId/attendance'
);

if (attendanceRoute) {
    console.log('Found attendance route');
    attendanceRoute.route.stack[0].handle(req, res);
} else {
    console.log('Attendance route not found');
}
