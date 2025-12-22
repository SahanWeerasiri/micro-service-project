// Consumer Routes
// Define endpoints for consumers to buy and share gift cards

const express = require('express');
const router = express.Router();
const consumerController = require('../controllers/consumerController');

// Buy gift card
router.post('/buy', consumerController.buyGiftCard);
// Share gift card
router.post('/share', consumerController.shareGiftCard);

module.exports = router;
