const express = require('express');
const app = express();

// Load shifts routes
const shiftsRouter = require('./routes/shifts');
app.use('/api/shifts', shiftsRouter);

// Print all routes
console.log('Available routes:');
shiftsRouter.stack.forEach((layer) => {
  if (layer.route) {
    const methods = Object.keys(layer.route.methods).join(', ').toUpperCase();
    console.log(`${methods} /api/shifts${layer.route.path}`);
  }
});
