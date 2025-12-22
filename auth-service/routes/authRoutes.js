// Auth Routes
// Define endpoints for user registration and login

const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// Register endpoint
router.post('/register', authController.register);
// Login endpoint
router.post('/login', authController.login);
// Verify endpoint
router.get('/verify', authController.verify);

module.exports = router;
