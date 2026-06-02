const router = require('express').Router();
const auth   = require('../middleware/auth.middleware');
const ctrl   = require('../controllers/transaction.controller');

router.use(auth);

// Order matters — specific paths before /:id
router.get('/summary',       ctrl.getSummary);
router.get('/monthly-stats', ctrl.getMonthlyStats);
router.get('/',              ctrl.getTransactions);
router.post('/',             ctrl.createTransaction);
router.put('/:id',           ctrl.updateTransaction);
router.delete('/:id',        ctrl.deleteTransaction);

module.exports = router;
