const router = require('express').Router();
const ctrl   = require('../controllers/auth.controller');

// Public
router.post('/register',        ctrl.register);
router.post('/login',           ctrl.login);
router.post('/logout',          ctrl.logout);
router.post('/google',          ctrl.googleLogin);
router.post('/send-otp',        ctrl.sendOtp);
router.post('/verify-otp',      ctrl.verifyOtp);
router.post('/forgot-password', ctrl.forgotPassword);
router.post('/reset-password',  ctrl.resetPassword);

module.exports = router;
