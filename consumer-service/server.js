// Consumer Service - Consumers buy and share gift cards
// This service provides endpoints for consumers to buy and share gift cards

const express = require('express');
const app = express();
app.use(express.json());

// Import routes
const consumerRoutes = require('./routes/consumerRoutes');
app.use('/consumer', consumerRoutes);

// Start server
const PORT = process.env.PORT || 3003;
app.listen(PORT, () => {
    console.log(`Consumer Service running on port ${PORT}`);
});
