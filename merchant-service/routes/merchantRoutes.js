// Merchant Routes
// Define endpoints for merchants to create and sell gift cards

const express = require('express');
const router = express.Router();
const merchantController = require('../controllers/merchantController');

// Create gift card
router.post('/create', merchantController.createGiftCard);
// Sell gift card
router.post('/sell', merchantController.sellGiftCard);

module.exports = router;
