const bcrypt    = require('bcrypt');
const path      = require('path');
const { pool }  = require('../config/db');

// ════════════════════════════════════════
// USER CONTROLLER
// ════════════════════════════════════════
exports.getProfile = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT u.*, s.plan, s.expires_at AS sub_expires, s.status AS sub_status
       FROM users u
       LEFT JOIN subscriptions s ON u.user_id = s.user_id
       WHERE u.user_id = ?`,
      [req.user.userId]
    );
    if (!rows.length) return res.status(404).json({ error: 'User tidak ditemukan' });

    const u = rows[0];
    res.json({
      user: {
        userId:     u.user_id,
        name:       u.name,
        email:      u.email,
        phone:      u.phone,
        avatarUrl:  u.avatar_url,
        isPremium:  !!u.is_premium,
        isVerified: !!u.is_verified,
        plan:       u.plan || 'free',
        subExpires: u.sub_expires,
        createdAt:  u.created_at,
      },
    });
  } catch (err) {
    console.error('getProfile:', err);
    res.status(500).json({ error: 'Gagal mengambil profil' });
  }
};

exports.updateProfile = async (req, res) => {
  const { name, phone } = req.body;
  try {
    const fields = [];
    const vals   = [];
    if (name)  { fields.push('name = ?');  vals.push(name.trim()); }
    if (phone !== undefined) { fields.push('phone = ?'); vals.push(phone || null); }
    if (!fields.length) return res.status(400).json({ error: 'Tidak ada data yang diperbarui' });

    vals.push(req.user.userId);
    await pool.query(`UPDATE users SET ${fields.join(', ')} WHERE user_id = ?`, vals);

    const [rows] = await pool.query(
      'SELECT u.*, s.plan FROM users u LEFT JOIN subscriptions s ON u.user_id = s.user_id WHERE u.user_id = ?',
      [req.user.userId]
    );
    const u = rows[0];
    res.json({
      user: {
        userId: u.user_id, name: u.name, email: u.email,
        phone: u.phone, avatarUrl: u.avatar_url,
        isPremium: !!u.is_premium, plan: u.plan || 'free',
      },
    });
  } catch (err) {
    console.error('updateProfile:', err);
    res.status(500).json({ error: 'Gagal memperbarui profil' });
  }
};

exports.uploadAvatar = async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'File avatar wajib diupload' });
  try {
    const avatarUrl = `/uploads/${req.file.filename}`;
    await pool.query('UPDATE users SET avatar_url = ? WHERE user_id = ?',
      [avatarUrl, req.user.userId]);
    res.json({ avatarUrl });
  } catch (err) {
    console.error('uploadAvatar:', err);
    res.status(500).json({ error: 'Gagal upload avatar' });
  }
};

exports.changePassword = async (req, res) => {
  const { oldPassword, newPassword } = req.body;
  if (!oldPassword || !newPassword) {
    return res.status(400).json({ error: 'Password lama dan baru wajib diisi' });
  }
  if (newPassword.length < 8) {
    return res.status(400).json({ error: 'Password baru minimal 8 karakter' });
  }
  try {
    const [[user]] = await pool.query('SELECT password FROM users WHERE user_id = ?', [req.user.userId]);
    if (!user.password) {
      return res.status(400).json({ error: 'Akun OAuth tidak memiliki password' });
    }
    const valid = await bcrypt.compare(oldPassword, user.password);
    if (!valid) return res.status(401).json({ error: 'Password lama salah' });

    const hashed = await bcrypt.hash(newPassword, 12);
    await pool.query('UPDATE users SET password = ? WHERE user_id = ?', [hashed, req.user.userId]);
    res.json({ message: 'Password berhasil diubah' });
  } catch (err) {
    console.error('changePassword:', err);
    res.status(500).json({ error: 'Gagal mengubah password' });
  }
};

// ════════════════════════════════════════
// CATEGORY CONTROLLER
// ════════════════════════════════════════
exports.getCategories = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM categories WHERE user_id IS NULL OR user_id = ? ORDER BY category_id',
      [req.user.userId]
    );
    res.json({ data: rows });
  } catch (err) {
    res.status(500).json({ error: 'Gagal mengambil kategori' });
  }
};

exports.createCategory = async (req, res) => {
  const { name, icon, color } = req.body;
  if (!name) return res.status(400).json({ error: 'Nama kategori wajib diisi' });
  try {
    const [result] = await pool.query(
      'INSERT INTO categories (user_id, name, icon, color, is_default) VALUES (?, ?, ?, ?, FALSE)',
      [req.user.userId, name.trim(), icon || 'more_horiz', color || '#6b7280']
    );
    const [[cat]] = await pool.query(
      'SELECT * FROM categories WHERE category_id = ?', [result.insertId]
    );
    res.status(201).json({ data: cat });
  } catch (err) {
    console.error('createCategory error:', err);
    res.status(500).json({ error: 'Gagal membuat kategori' });
  }
};

exports.deleteCategory = async (req, res) => {
  try {
    await pool.query(
      'DELETE FROM categories WHERE category_id = ? AND is_default = FALSE AND user_id = ?',
      [req.params.id, req.user.userId]
    );
    res.json({ message: 'Kategori dihapus' });
  } catch (err) {
    res.status(500).json({ error: 'Gagal menghapus kategori' });
  }
};

// ════════════════════════════════════════
// BUDGET CONTROLLER
// ════════════════════════════════════════
exports.getBudgets = async (req, res) => {
  const userId = req.user.userId;
  const now    = new Date();
  const month  = parseInt(req.query.month) || now.getMonth() + 1;
  const year   = parseInt(req.query.year)  || now.getFullYear();

  try {
    const [rows] = await pool.query(
      `SELECT b.*, c.name AS category_name, c.color,
              COALESCE((
                SELECT SUM(t.amount)
                FROM transactions t
                WHERE t.user_id = b.user_id
                  AND t.category_id = b.category_id
                  AND MONTH(t.date) = ? AND YEAR(t.date) = ?
              ), 0) AS spent
       FROM budgets b
       LEFT JOIN categories c ON b.category_id = c.category_id
       WHERE b.user_id = ? AND b.month = ? AND b.year = ?`,
      [month, year, userId, month, year]
    );
    res.json({ data: rows });
  } catch (err) {
    console.error('getBudgets:', err);
    res.status(500).json({ error: 'Gagal mengambil budget' });
  }
};

exports.upsertBudget = async (req, res) => {
  const userId = req.user.userId;
  const { category_id, amount, period, month, year } = req.body;

  if (!amount || isNaN(amount) || parseFloat(amount) <= 0) {
    return res.status(400).json({ error: 'Jumlah budget tidak valid' });
  }
  const now = new Date();
  const m   = parseInt(month) || now.getMonth() + 1;
  const y   = parseInt(year)  || now.getFullYear();

  try {
    await pool.query(
      `INSERT INTO budgets (user_id, category_id, amount, period, month, year)
       VALUES (?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE amount = VALUES(amount), period = VALUES(period)`,
      [userId, category_id || null, parseFloat(amount), period || 'monthly', m, y]
    );
    res.json({ message: 'Budget berhasil disimpan' });
  } catch (err) {
    console.error('upsertBudget:', err);
    res.status(500).json({ error: 'Gagal menyimpan budget' });
  }
};

exports.deleteBudget = async (req, res) => {
  try {
    await pool.query(
      'DELETE FROM budgets WHERE budget_id = ? AND user_id = ?',
      [req.params.id, req.user.userId]
    );
    res.json({ message: 'Budget dihapus' });
  } catch (err) {
    res.status(500).json({ error: 'Gagal menghapus budget' });
  }
};

// ════════════════════════════════════════
// NOTIFICATION CONTROLLER
// ════════════════════════════════════════
exports.getNotifications = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM notifications
       WHERE user_id = ?
       ORDER BY created_at DESC LIMIT 50`,
      [req.user.userId]
    );
    res.json({ data: rows });
  } catch (err) {
    res.status(500).json({ error: 'Gagal mengambil notifikasi' });
  }
};

exports.markAllRead = async (req, res) => {
  try {
    await pool.query(
      'UPDATE notifications SET is_read = TRUE WHERE user_id = ?',
      [req.user.userId]
    );
    res.json({ message: 'Semua notifikasi dibaca' });
  } catch (err) {
    res.status(500).json({ error: 'Gagal memperbarui notifikasi' });
  }
};