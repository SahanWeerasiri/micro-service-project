// Auth Service - Handles user authentication
// This service provides endpoints for user registration and login

const express = require('express');
const app = express();
app.use(express.json());

// Import routes
const authRoutes = require('./routes/authRoutes');
app.use('/auth', authRoutes);

// Start server
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`Auth Service running on port ${PORT}`);
});
