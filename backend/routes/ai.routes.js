const router = require('express').Router();
const auth   = require('../middleware/auth.middleware');
const ctrl   = require('../controllers/ai.controller');

router.use(auth);
router.get('/insights',       ctrl.getInsights);
router.post('/analyze',       ctrl.analyzeSpending);
router.get('/recommend',      ctrl.getRecommendations);
router.get('/budget-suggest', ctrl.getBudgetSuggestions);

module.exports = router;
