// Log Service - Centralized logging for all services
// This service receives and stores logs from other services

const express = require('express');
const app = express();
app.use(express.json());

// Import routes
const logRoutes = require('./routes/logRoutes');
app.use('/logs', logRoutes);

// Start server
const PORT = process.env.PORT || 3004;
app.listen(PORT, () => {
    console.log(`Log Service running on port ${PORT}`);
});
