const router = require('express').Router();
const auth   = require('../middleware/auth.middleware');
const misc   = require('../controllers/misc.controller');

router.use(auth);
router.get('/',        misc.getBudgets);
router.post('/',       misc.upsertBudget);
router.put('/:id',     misc.upsertBudget);
router.delete('/:id',  misc.deleteBudget);

module.exports = router;
