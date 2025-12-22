// Log Routes
// Define endpoints for logging

const express = require('express');
const router = express.Router();
const logController = require('../controllers/logController');

// Log endpoint
router.post('/', logController.captureLog);

module.exports = router;
