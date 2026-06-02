const { pool }  = require('../config/db');
const aiService = require('../services/ai.service');

// ── GET /api/ai/insights ──────────────────
exports.getInsights = async (req, res) => {
  const userId = req.user.userId;
  try {
    // Return latest 10 insights
    const [rows] = await pool.query(
      `SELECT * FROM ai_insights
       WHERE user_id = ?
       ORDER BY generated_at DESC LIMIT 10`,
      [userId]
    );

    // If no insights yet, generate them on-the-fly
    if (!rows.length) {
      try {
        const newInsights = await aiService.generateInsightsForUser(userId);
        return res.json({ data: newInsights });
      } catch (_) {
        return res.json({ data: [] });
      }
    }

    res.json({ data: rows });
  } catch (err) {
    console.error('getInsights:', err);
    res.status(500).json({ error: 'Gagal mengambil insight' });
  }
};

// ── POST /api/ai/analyze ──────────────────
exports.analyzeSpending = async (req, res) => {
  const userId = req.user.userId;
  try {
    const insights = await aiService.generateInsightsForUser(userId);
    res.json({ data: insights[0] || null });
  } catch (err) {
    console.error('analyzeSpending:', err);
    res.status(500).json({ error: 'Gagal menganalisis pengeluaran' });
  }
};

// ── GET /api/ai/recommend ─────────────────
exports.getRecommendations = async (req, res) => {
  const userId = req.user.userId;
  try {
    const recs = await aiService.getSpendingRecommendations(userId);
    res.json({ recommendations: recs });
  } catch (err) {
    res.status(500).json({ error: 'Gagal mengambil rekomendasi' });
  }
};

// ── GET /api/ai/budget-suggest ────────────
exports.getBudgetSuggestions = async (req, res) => {
  const userId = req.user.userId;
  try {
    const suggestions = await aiService.suggestBudgets(userId);
    res.json(suggestions);
  } catch (err) {
    res.status(500).json({ error: 'Gagal mengambil saran budget' });
  }
};
