const router  = require('express').Router();
const auth    = require('../middleware/auth.middleware');
const ctrl    = require('../controllers/ai.controller');
const groqSvc = require('../services/groq.service');

router.use(auth);

router.get('/insights',       ctrl.getInsights);
router.post('/analyze',       ctrl.analyzeSpending);
router.get('/recommend',      ctrl.getRecommendations);
router.get('/budget-suggest', ctrl.getBudgetSuggestions);

router.post('/chat', async (req, res) => {
  const { messages } = req.body;
  const userId = req.user.userId;

  if (!messages || !messages.length) {
    return res.status(400).json({ error: 'Messages wajib diisi' });
  }

  try {
    const { pool } = require('../config/db');
    const now = new Date();
    const month = now.getMonth() + 1;
    const year = now.getFullYear();

    const [[summary]] = await pool.query(
      `SELECT COALESCE(SUM(amount), 0) AS total, COUNT(*) AS count
       FROM transactions WHERE user_id = ? AND MONTH(date) = ? AND YEAR(date) = ?`,
      [userId, month, year]
    );

    const [categories] = await pool.query(
      `SELECT c.name, SUM(t.amount) AS total
       FROM transactions t JOIN categories c ON t.category_id = c.category_id
       WHERE t.user_id = ? AND MONTH(t.date) = ? AND YEAR(t.date) = ?
       GROUP BY t.category_id ORDER BY total DESC LIMIT 5`,
      [userId, month, year]
    );

    const [recent] = await pool.query(
      `SELECT merchant_name, amount, date FROM transactions
       WHERE user_id = ? ORDER BY date DESC LIMIT 5`,
      [userId]
    );

    const context = `
    console.log('Context:', context);
Data keuangan user bulan ini:
- Total pengeluaran: Rp ${Math.round(summary.total).toLocaleString('id-ID')}
- Jumlah transaksi: ${summary.count}
- Kategori terbesar: ${categories.map(c => `${c.name} (Rp ${Math.round(c.total).toLocaleString('id-ID')})`).join(', ')}
- Transaksi terbaru: ${recent.map(t => `${t.merchant_name} Rp ${Math.round(t.amount).toLocaleString('id-ID')}`).join(', ')}
    `.trim();

    const reply = await groqSvc.chatWithContext(messages, context);
    res.json({ reply });
  } catch (err) {
    console.error('Groq error:', err.response?.data || err.message);
    res.status(500).json({ error: 'Gagal menghubungi AI' });
  }
});

module.exports = router;