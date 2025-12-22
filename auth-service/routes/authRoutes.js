// Auth Routes
// Define endpoints for user registration and login

const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

// Register endpoint
router.post('/register', authController.register);
// Login endpoint
router.post('/login', authController.login);
// Logout endpoint (protected)
router.post('/logout', authMiddleware, authController.logout);
// Verify token endpoint (protected)
router.post('/verify', authMiddleware, authController.verifyToken);

module.exports = router;
