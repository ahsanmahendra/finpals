const { pool } = require('../config/db');

// ── GET /api/transactions ─────────────────
exports.getTransactions = async (req, res) => {
  const userId = req.user.userId;
  const {
    page = 1, limit = 20,
    category_id, start_date, end_date, search,
  } = req.query;

  const offset = (parseInt(page) - 1) * parseInt(limit);
  const params = [userId];
  let where = 'WHERE t.user_id = ?';

  if (category_id) { where += ' AND t.category_id = ?'; params.push(category_id); }
  if (start_date)  { where += ' AND t.date >= ?';        params.push(start_date); }
  if (end_date)    { where += ' AND t.date <= ?';        params.push(end_date);   }
  if (search)      { where += ' AND t.merchant_name LIKE ?'; params.push(`%${search}%`); }

  try {
    const [rows] = await pool.query(
      `SELECT t.*, c.name AS category_name, c.color AS category_color, c.icon AS category_icon
       FROM transactions t
       LEFT JOIN categories c ON t.category_id = c.category_id
       ${where}
       ORDER BY t.date DESC, t.created_at DESC
       LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), offset]
    );

    const [[{ total }]] = await pool.query(
      `SELECT COUNT(*) AS total FROM transactions t ${where}`, params
    );

    res.json({
      data:        rows,
      pagination: { page: parseInt(page), limit: parseInt(limit), total },
    });
  } catch (err) {
    console.error('getTransactions:', err);
    res.status(500).json({ error: 'Gagal mengambil transaksi' });
  }
};

// ── POST /api/transactions ────────────────
exports.createTransaction = async (req, res) => {
  const userId = req.user.userId;
  const { merchant_name, amount, category_id, date, notes, source, image_url } = req.body;

  if (!merchant_name || !amount || !date) {
    return res.status(400).json({ error: 'Merchant, jumlah, dan tanggal wajib diisi' });
  }
  if (isNaN(amount) || parseFloat(amount) <= 0) {
    return res.status(400).json({ error: 'Jumlah tidak valid' });
  }

  try {
    const [result] = await pool.query(
      `INSERT INTO transactions (user_id, merchant_name, amount, category_id, date, notes, source, image_url)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [userId, merchant_name.trim(), parseFloat(amount),
       category_id || null, date, notes || null,
       source || 'manual', image_url || null]
    );

    const [[tx]] = await pool.query(
      `SELECT t.*, c.name AS category_name, c.color AS category_color
       FROM transactions t
       LEFT JOIN categories c ON t.category_id = c.category_id
       WHERE t.transaction_id = ?`,
      [result.insertId]
    );

    // Update budget alert (async, non-blocking)
    checkBudgetAlert(userId, category_id).catch(console.error);

    res.status(201).json({ data: tx });
  } catch (err) {
    console.error('createTransaction:', err);
    res.status(500).json({ error: 'Gagal menyimpan transaksi' });
  }
};

// ── PUT /api/transactions/:id ─────────────
exports.updateTransaction = async (req, res) => {
  const userId = req.user.userId;
  const { id }  = req.params;
  const { merchant_name, amount, category_id, date, notes } = req.body;

  try {
    const [[tx]] = await pool.query(
      'SELECT * FROM transactions WHERE transaction_id = ? AND user_id = ?',
      [id, userId]
    );
    if (!tx) return res.status(404).json({ error: 'Transaksi tidak ditemukan' });

    await pool.query(
      `UPDATE transactions SET
        merchant_name = ?, amount = ?, category_id = ?, date = ?, notes = ?, updated_at = NOW()
       WHERE transaction_id = ? AND user_id = ?`,
      [
        merchant_name ?? tx.merchant_name,
        amount        != null ? parseFloat(amount) : tx.amount,
        category_id   !== undefined ? (category_id || null) : tx.category_id,
        date          ?? tx.date,
        notes         !== undefined ? notes : tx.notes,
        id, userId,
      ]
    );

    const [[updated]] = await pool.query(
      `SELECT t.*, c.name AS category_name, c.color AS category_color
       FROM transactions t LEFT JOIN categories c ON t.category_id = c.category_id
       WHERE t.transaction_id = ?`, [id]
    );
    res.json({ data: updated });
  } catch (err) {
    console.error('updateTransaction:', err);
    res.status(500).json({ error: 'Gagal memperbarui transaksi' });
  }
};

// ── DELETE /api/transactions/:id ──────────
exports.deleteTransaction = async (req, res) => {
  const userId = req.user.userId;
  const { id }  = req.params;
  try {
    const [[tx]] = await pool.query(
      'SELECT * FROM transactions WHERE transaction_id = ? AND user_id = ?',
      [id, userId]
    );
    if (!tx) return res.status(404).json({ error: 'Transaksi tidak ditemukan' });
    await pool.query('DELETE FROM transactions WHERE transaction_id = ?', [id]);
    res.json({ message: 'Transaksi dihapus' });
  } catch (err) {
    console.error('deleteTransaction:', err);
    res.status(500).json({ error: 'Gagal menghapus transaksi' });
  }
};

// ── GET /api/transactions/summary ─────────
exports.getSummary = async (req, res) => {
  const userId = req.user.userId;
  const now    = new Date();
  const month  = parseInt(req.query.month) || now.getMonth() + 1;
  const year   = parseInt(req.query.year)  || now.getFullYear();

  try {
    // Monthly total
    const [[monthly]] = await pool.query(
      `SELECT COALESCE(SUM(amount), 0) AS total
       FROM transactions
       WHERE user_id = ? AND MONTH(date) = ? AND YEAR(date) = ?`,
      [userId, month, year]
    );

    // Weekly total (current week Mon–Sun)
    const [[weekly]] = await pool.query(
      `SELECT COALESCE(SUM(amount), 0) AS total
       FROM transactions
       WHERE user_id = ?
         AND date >= DATE(DATE_SUB(NOW(), INTERVAL WEEKDAY(NOW()) DAY))
         AND date <= DATE(NOW())`,
      [userId]
    );

    // Category breakdown
    const [categories] = await pool.query(
      `SELECT c.name AS category, c.color,
              SUM(t.amount) AS total,
              ROUND(SUM(t.amount) / (
                SELECT COALESCE(SUM(amount),1) FROM transactions
                WHERE user_id = ? AND MONTH(date) = ? AND YEAR(date) = ?
              ) * 100, 1) AS percent
       FROM transactions t
       LEFT JOIN categories c ON t.category_id = c.category_id
       WHERE t.user_id = ? AND MONTH(t.date) = ? AND YEAR(t.date) = ?
       GROUP BY t.category_id, c.name, c.color
       ORDER BY total DESC`,
      [userId, month, year, userId, month, year]
    );

    res.json({
      totalMonthly: parseFloat(monthly.total),
      totalWeekly:  parseFloat(weekly.total),
      categories,
    });
  } catch (err) {
    console.error('getSummary:', err);
    res.status(500).json({ error: 'Gagal mengambil ringkasan' });
  }
};

// ── GET /api/transactions/monthly-stats ───
exports.getMonthlyStats = async (req, res) => {
  const userId = req.user.userId;
  try {
    const [rows] = await pool.query(
      `SELECT
         DATE_FORMAT(date, '%Y-%m') AS month,
         COALESCE(SUM(amount), 0)   AS total,
         COUNT(*)                   AS count
       FROM transactions
       WHERE user_id = ? AND date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
       GROUP BY DATE_FORMAT(date, '%Y-%m')
       ORDER BY month ASC`,
      [userId]
    );
    res.json({ data: rows });
  } catch (err) {
    res.status(500).json({ error: 'Gagal mengambil statistik bulanan' });
  }
};

// ── Helper: check if over budget ──────────
async function checkBudgetAlert(userId, categoryId) {
  if (!categoryId) return;
  const now   = new Date();
  const month = now.getMonth() + 1;
  const year  = now.getFullYear();

  const [[budget]] = await pool.query(
    'SELECT * FROM budgets WHERE user_id = ? AND category_id = ? AND month = ? AND year = ?',
    [userId, categoryId, month, year]
  );
  if (!budget) return;

  const [[spent]] = await pool.query(
    `SELECT COALESCE(SUM(amount), 0) AS total
     FROM transactions
     WHERE user_id = ? AND category_id = ? AND MONTH(date) = ? AND YEAR(date) = ?`,
    [userId, categoryId, month, year]
  );

  const pct = parseFloat(spent.total) / budget.amount;
  if (pct >= 0.9) {
    const msg = pct >= 1
      ? `⚠️ Budget ${categoryId} habis! Kamu sudah melebihi anggaran bulan ini.`
      : `🔔 Budget ${categoryId} hampir habis (${Math.round(pct * 100)}% terpakai).`;

    await pool.query(
      'INSERT INTO notifications (user_id, type, title, message) VALUES (?, "push", ?, ?)',
      [userId, 'Budget Alert', msg]
    );
  }
}
