const router  = require('express').Router();
const auth    = require('../middleware/auth.middleware');
const upload  = require('../middleware/upload.middleware');
const misc    = require('../controllers/misc.controller');

router.use(auth);

router.get('/',                  misc.getProfile);
router.get('/profile',           misc.getProfile);
router.put('/profile',           misc.updateProfile);
router.post('/avatar',           upload.single('avatar'), misc.uploadAvatar);
router.put('/change-password',   misc.changePassword);

module.exports = router;
