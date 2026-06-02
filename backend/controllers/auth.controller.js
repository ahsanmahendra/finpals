const bcrypt  = require('bcrypt');
const jwt     = require('jsonwebtoken');
const crypto  = require('crypto');
const { pool }   = require('../config/db');
const emailSvc   = require('../services/email.service');
const whatsappSvc = require('../services/whatsapp.service');

const SALT = 12;
const TOKEN_EXP = process.env.JWT_EXPIRES_IN || '30d';

function generateToken(payload) {
  return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: TOKEN_EXP });
}

async function saveSession(userId, token, ip) {
  await pool.query(
    `INSERT INTO sessions (user_id, token, ip_address, expires_at)
     VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))`,
    [userId, token, ip || null]
  );
}

function userPayload(user) {
  return {
    userId:     user.user_id,
    name:       user.name,
    email:      user.email,
    phone:      user.phone,
    avatarUrl:  user.avatar_url,
    isPremium:  !!user.is_premium,
    isVerified: !!user.is_verified,
    plan:       user.plan || 'free',
    createdAt:  user.created_at,
  };
}

// ── POST /api/auth/register ───────────────
exports.register = async (req, res) => {
  const { name, email, password, phone } = req.body;
  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Nama, email, dan password wajib diisi' });
  }
  try {
    const [ex] = await pool.query('SELECT user_id FROM users WHERE email = ?', [email]);
    if (ex.length) return res.status(409).json({ error: 'Email sudah terdaftar' });

    const hashed = await bcrypt.hash(password, SALT);
    const [result] = await pool.query(
      'INSERT INTO users (name, email, password, phone) VALUES (?, ?, ?, ?)',
      [name.trim(), email.toLowerCase().trim(), hashed, phone || null]
    );
    const uid = result.insertId;

    // Init free subscription
    await pool.query(
      'INSERT INTO subscriptions (user_id, plan, status) VALUES (?, "free", "active")',
      [uid]
    );

    // Send welcome email (non-blocking)
    emailSvc.sendWelcomeEmail(email, name).catch(console.error);

    const token = generateToken({ userId: uid, email });
    await saveSession(uid, token, req.ip);

    const [users] = await pool.query(
      `SELECT u.*, s.plan FROM users u
       LEFT JOIN subscriptions s ON u.user_id = s.user_id
       WHERE u.user_id = ?`, [uid]
    );

    res.status(201).json({ token, user: userPayload(users[0]) });
  } catch (err) {
    console.error('register error:', err);
    res.status(500).json({ error: 'Gagal mendaftar' });
  }
};

// ── POST /api/auth/login ──────────────────
exports.login = async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email dan password wajib diisi' });
  }
  try {
    const [rows] = await pool.query(
      `SELECT u.*, s.plan FROM users u
       LEFT JOIN subscriptions s ON u.user_id = s.user_id
       WHERE u.email = ?`,
      [email.toLowerCase().trim()]
    );
    if (!rows.length) {
      return res.status(401).json({ error: 'Email atau password salah' });
    }
    const user = rows[0];
    if (!user.password) {
      return res.status(401).json({ error: 'Akun ini terdaftar via Google/WhatsApp, gunakan metode tersebut' });
    }
    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ error: 'Email atau password salah' });

    const token = generateToken({ userId: user.user_id, email: user.email });
    await saveSession(user.user_id, token, req.ip);

    res.json({ token, user: userPayload(user) });
  } catch (err) {
    console.error('login error:', err);
    res.status(500).json({ error: 'Gagal login' });
  }
};

// ── POST /api/auth/logout ─────────────────
exports.logout = async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (token) {
      await pool.query('DELETE FROM sessions WHERE token = ?', [token]);
    }
    res.json({ message: 'Logout berhasil' });
  } catch (err) {
    res.status(500).json({ error: 'Gagal logout' });
  }
};

// ── POST /api/auth/google ─────────────────
exports.googleLogin = async (req, res) => {
  const { idToken } = req.body;
  if (!idToken) return res.status(400).json({ error: 'ID token wajib diisi' });
  try {
    const { OAuth2Client } = require('google-auth-library');
    const client  = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
    const ticket  = await client.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const { email, name, picture } = payload;

    let [rows] = await pool.query('SELECT u.*, s.plan FROM users u LEFT JOIN subscriptions s ON u.user_id = s.user_id WHERE u.email = ?', [email]);
    let user;

    if (rows.length) {
      user = rows[0];
      // Update avatar if changed
      await pool.query('UPDATE users SET avatar_url = ?, provider = "google", is_verified = TRUE WHERE user_id = ?', [picture, user.user_id]);
    } else {
      const [r] = await pool.query(
        'INSERT INTO users (name, email, avatar_url, provider, is_verified) VALUES (?, ?, ?, "google", TRUE)',
        [name, email, picture]
      );
      await pool.query('INSERT INTO subscriptions (user_id, plan, status) VALUES (?, "free", "active")', [r.insertId]);
      const [u] = await pool.query('SELECT u.*, s.plan FROM users u LEFT JOIN subscriptions s ON u.user_id = s.user_id WHERE u.user_id = ?', [r.insertId]);
      user = u[0];
    }

    const token = generateToken({ userId: user.user_id, email: user.email });
    await saveSession(user.user_id, token, req.ip);
    res.json({ token, user: userPayload(user) });
  } catch (err) {
    console.error('google login error:', err);
    res.status(401).json({ error: 'Google login gagal: ' + err.message });
  }
};

// ── POST /api/auth/send-otp ───────────────
exports.sendOtp = async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'Nomor HP wajib diisi' });
  try {
    // Rate limit: max 3 OTPs per phone per 10 minutes
    const [recent] = await pool.query(
      'SELECT COUNT(*) as cnt FROM otp_codes WHERE phone = ? AND created_at > DATE_SUB(NOW(), INTERVAL 10 MINUTE)',
      [phone]
    );
    if (recent[0].cnt >= 3) {
      return res.status(429).json({ error: 'Terlalu banyak permintaan OTP. Coba lagi dalam 10 menit.' });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    await pool.query(
      'INSERT INTO otp_codes (phone, otp, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 5 MINUTE))',
      [phone, otp]
    );

    // Send via Fonnte WhatsApp
    await whatsappSvc.sendOtp(phone, otp);
    res.json({ message: 'OTP berhasil dikirim ke WhatsApp' });
  } catch (err) {
    console.error('send-otp error:', err);
    res.status(500).json({ error: 'Gagal mengirim OTP' });
  }
};

// ── POST /api/auth/verify-otp ─────────────
exports.verifyOtp = async (req, res) => {
  const { phone, otp } = req.body;
  if (!phone || !otp) return res.status(400).json({ error: 'Phone dan OTP wajib diisi' });
  try {
    const [rows] = await pool.query(
      `SELECT * FROM otp_codes
       WHERE phone = ? AND otp = ? AND expires_at > NOW() AND used = FALSE
       ORDER BY created_at DESC LIMIT 1`,
      [phone, otp]
    );
    if (!rows.length) {
      // Increment attempt counter
      await pool.query('UPDATE otp_codes SET attempts = attempts + 1 WHERE phone = ? AND used = FALSE', [phone]);
      return res.status(401).json({ error: 'OTP tidak valid atau sudah kadaluarsa' });
    }

    await pool.query('UPDATE otp_codes SET used = TRUE WHERE otp_id = ?', [rows[0].otp_id]);

    // Upsert user
    let [users] = await pool.query('SELECT u.*, s.plan FROM users u LEFT JOIN subscriptions s ON u.user_id = s.user_id WHERE u.phone = ?', [phone]);
    let user;
    if (users.length) {
      user = users[0];
    } else {
      const name = `User_${phone.slice(-4)}`;
      const [r] = await pool.query(
        'INSERT INTO users (name, phone, provider, is_verified) VALUES (?, ?, "whatsapp", TRUE)',
        [name, phone]
      );
      await pool.query('INSERT INTO subscriptions (user_id, plan, status) VALUES (?, "free", "active")', [r.insertId]);
      const [u] = await pool.query('SELECT u.*, s.plan FROM users u LEFT JOIN subscriptions s ON u.user_id = s.user_id WHERE u.user_id = ?', [r.insertId]);
      user = u[0];
    }

    const token = generateToken({ userId: user.user_id, email: user.email || phone });
    await saveSession(user.user_id, token, req.ip);
    res.json({ token, user: userPayload(user) });
  } catch (err) {
    console.error('verify-otp error:', err);
    res.status(500).json({ error: 'Gagal verifikasi OTP' });
  }
};

// ── POST /api/auth/forgot-password ────────
exports.forgotPassword = async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ error: 'Email wajib diisi' });
  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email.toLowerCase()]);
    // Always return 200 to prevent email enumeration
    if (!rows.length) return res.json({ message: 'Jika email terdaftar, link reset akan dikirim' });

    const token     = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 3600 * 1000); // 1 hour

    await pool.query(
      'INSERT INTO password_resets (user_id, token, expires_at) VALUES (?, ?, ?)',
      [rows[0].user_id, token, expiresAt]
    );

    const resetUrl = `${process.env.APP_URL}/reset-password?token=${token}`;
    await emailSvc.sendPasswordResetEmail(email, rows[0].name, resetUrl);

    res.json({ message: 'Jika email terdaftar, link reset akan dikirim' });
  } catch (err) {
    console.error('forgot-password error:', err);
    res.status(500).json({ error: 'Gagal mengirim email reset' });
  }
};

// ── POST /api/auth/reset-password ─────────
exports.resetPassword = async (req, res) => {
  const { token, newPassword } = req.body;
  if (!token || !newPassword) {
    return res.status(400).json({ error: 'Token dan password baru wajib diisi' });
  }
  if (newPassword.length < 8) {
    return res.status(400).json({ error: 'Password minimal 8 karakter' });
  }
  try {
    const [rows] = await pool.query(
      'SELECT * FROM password_resets WHERE token = ? AND expires_at > NOW() AND used = FALSE',
      [token]
    );
    if (!rows.length) {
      return res.status(400).json({ error: 'Token tidak valid atau sudah kadaluarsa' });
    }

    const hashed = await bcrypt.hash(newPassword, SALT);
    await pool.query('UPDATE users SET password = ? WHERE user_id = ?', [hashed, rows[0].user_id]);
    await pool.query('UPDATE password_resets SET used = TRUE WHERE reset_id = ?', [rows[0].reset_id]);
    // Invalidate all sessions
    await pool.query('DELETE FROM sessions WHERE user_id = ?', [rows[0].user_id]);

    res.json({ message: 'Password berhasil diubah, silakan login kembali' });
  } catch (err) {
    console.error('reset-password error:', err);
    res.status(500).json({ error: 'Gagal reset password' });
  }
};
