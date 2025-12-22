// Merchant Service - Merchants create and sell gift cards
// This service provides endpoints for merchants to manage gift cards

const express = require('express');
const app = express();
app.use(express.json());

// Import routes
const merchantRoutes = require('./routes/merchantRoutes');
app.use('/merchant', merchantRoutes);

// Start server
const PORT = process.env.PORT || 3002;
app.listen(PORT, () => {
    console.log(`Merchant Service running on port ${PORT}`);
});
