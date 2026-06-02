const router = require('express').Router();
const auth   = require('../middleware/auth.middleware');
const upload = require('../middleware/upload.middleware');
const ctrl   = require('../controllers/ocr.controller');

router.use(auth);
router.post('/scan', upload.single('receipt'), ctrl.scanReceipt);

module.exports = router;
