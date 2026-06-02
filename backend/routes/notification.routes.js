const router = require('express').Router();
const auth   = require('../middleware/auth.middleware');
const misc   = require('../controllers/misc.controller');

router.use(auth);
router.get('/',      misc.getNotifications);
router.put('/read',  misc.markAllRead);

module.exports = router;
