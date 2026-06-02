// ── categories ────────────────────────────
const catRouter = require('express').Router();
const auth      = require('../middleware/auth.middleware');
const misc      = require('../controllers/misc.controller');

catRouter.use(auth);
catRouter.get('/', misc.getCategories);

module.exports.categoryRouter = catRouter;

// ── budgets ───────────────────────────────
const budgetRouter = require('express').Router();
budgetRouter.use(auth);
budgetRouter.get('/',      misc.getBudgets);
budgetRouter.post('/',     misc.upsertBudget);
budgetRouter.put('/:id',   misc.upsertBudget);
budgetRouter.delete('/:id', misc.deleteBudget);

module.exports.budgetRouter = budgetRouter;

// ── OCR ───────────────────────────────────
const ocrRouter  = require('express').Router();
const upload     = require('../middleware/upload.middleware');
const ocrCtrl    = require('../controllers/ocr.controller');
ocrRouter.use(auth);
ocrRouter.post('/scan', upload.single('receipt'), ocrCtrl.scanReceipt);

module.exports.ocrRouter = ocrRouter;

// ── AI ────────────────────────────────────
const aiRouter = require('express').Router();
const aiCtrl   = require('../controllers/ai.controller');
aiRouter.use(auth);
aiRouter.get('/insights',      aiCtrl.getInsights);
aiRouter.post('/analyze',      aiCtrl.analyzeSpending);
aiRouter.get('/recommend',     aiCtrl.getRecommendations);
aiRouter.get('/budget-suggest', aiCtrl.getBudgetSuggestions);

module.exports.aiRouter = aiRouter;

// ── Payment ───────────────────────────────
const payRouter  = require('express').Router();
const payCtrl    = require('../controllers/payment.controller');
// Webhook — no auth (Midtrans calls this)
payRouter.post('/webhook', payCtrl.handleWebhook);
// Protected
payRouter.post('/create',      auth, payCtrl.createPayment);
payRouter.get('/history',      auth, payCtrl.getPaymentHistory);
payRouter.get('/subscription', auth, payCtrl.getSubscription);

module.exports.paymentRouter = payRouter;

// ── Notifications ─────────────────────────
const notifRouter = require('express').Router();
notifRouter.use(auth);
notifRouter.get('/',         misc.getNotifications);
notifRouter.put('/read',     misc.markAllRead);

module.exports.notifRouter = notifRouter;
