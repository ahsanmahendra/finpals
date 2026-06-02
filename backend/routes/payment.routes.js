const router = require('express').Router();
const auth   = require('../middleware/auth.middleware');
const ctrl   = require('../controllers/payment.controller');

// Public — Midtrans calls this directly (no JWT)
router.post('/webhook', ctrl.handleWebhook);

// Protected
router.post('/create',      auth, ctrl.createPayment);
router.get('/history',      auth, ctrl.getPaymentHistory);
router.get('/subscription', auth, ctrl.getSubscription);

module.exports = router;
