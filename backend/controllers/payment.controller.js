const crypto     = require('crypto');
const { pool }   = require('../config/db');
const midtransSvc = require('../services/midtrans.service');

// ── POST /api/payment/create ──────────────
exports.createPayment = async (req, res) => {
  const userId = req.user.userId;
  const amount = parseInt(process.env.PREMIUM_PRICE_IDR || '29000');

  try {
    const [[user]] = await pool.query('SELECT * FROM users WHERE user_id = ?', [userId]);
    if (!user) return res.status(404).json({ error: 'User tidak ditemukan' });

    const orderId = `FINPALS-${userId}-${Date.now()}`;

    const snapToken = await midtransSvc.createSnapToken({
      orderId,
      amount,
      user: { name: user.name, email: user.email || '', phone: user.phone || '' },
    });

    await pool.query(
      `INSERT INTO payments (user_id, order_id, amount, status, snap_token)
       VALUES (?, ?, ?, 'pending', ?)`,
      [userId, orderId, amount, snapToken]
    );

    res.json({ snapToken, orderId, amount });
  } catch (err) {
    console.error('createPayment:', err);
    res.status(500).json({ error: 'Gagal membuat pembayaran: ' + err.message });
  }
};

// ── POST /api/payment/webhook ─────────────
// Midtrans will call this with payment status updates
exports.handleWebhook = async (req, res) => {
  try {
    const {
      order_id,
      transaction_status,
      fraud_status,
      signature_key,
      gross_amount,
      status_code,
      payment_type,
    } = req.body;

    // Verify Midtrans signature
    const expected = crypto
      .createHash('sha512')
      .update(`${order_id}${status_code}${gross_amount}${process.env.MIDTRANS_SERVER_KEY}`)
      .digest('hex');

    if (signature_key !== expected) {
      console.warn('Invalid Midtrans signature for order:', order_id);
      return res.status(401).json({ error: 'Invalid signature' });
    }

    // Determine final status
    let status = 'pending';
    if (
      (transaction_status === 'settlement' || transaction_status === 'capture') &&
      fraud_status !== 'deny'
    ) {
      status = 'success';
    } else if (['cancel', 'deny', 'expire'].includes(transaction_status)) {
      status = 'failed';
    } else if (transaction_status === 'expire') {
      status = 'expired';
    }

    await pool.query(
      `UPDATE payments
       SET status = ?, payment_method = ?, paid_at = IF(? = 'success', NOW(), NULL)
       WHERE order_id = ?`,
      [status, payment_type || null, status, order_id]
    );

    if (status === 'success') {
      // Get user_id from payment
      const [[payment]] = await pool.query(
        'SELECT user_id FROM payments WHERE order_id = ?', [order_id]
      );
      if (payment) {
        const uid = payment.user_id;
        // Activate premium for 30 days
        await pool.query('UPDATE users SET is_premium = TRUE WHERE user_id = ?', [uid]);
        await pool.query(
          `INSERT INTO subscriptions (user_id, plan, started_at, expires_at, status)
           VALUES (?, 'premium', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 'active')
           ON DUPLICATE KEY UPDATE
             plan = 'premium',
             started_at = NOW(),
             expires_at = DATE_ADD(NOW(), INTERVAL 30 DAY),
             status = 'active',
             updated_at = NOW()`,
          [uid]
        );
        // Notify user
        await pool.query(
          `INSERT INTO notifications (user_id, type, title, message)
           VALUES (?, 'push', '🎉 Premium Aktif!',
             'Selamat! Akun Finpals Premium kamu sudah aktif selama 30 hari.')`,
          [uid]
        );
      }
    }

    res.json({ status: 'ok' });
  } catch (err) {
    console.error('webhook error:', err);
    res.status(500).json({ error: 'Webhook error' });
  }
};

// ── GET /api/payment/history ──────────────
exports.getPaymentHistory = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM payments WHERE user_id = ? ORDER BY created_at DESC LIMIT 20`,
      [req.user.userId]
    );
    res.json({ data: rows });
  } catch (err) {
    res.status(500).json({ error: 'Gagal mengambil riwayat pembayaran' });
  }
};

// ── GET /api/payment/subscription ─────────
exports.getSubscription = async (req, res) => {
  try {
    const [[sub]] = await pool.query(
      'SELECT * FROM subscriptions WHERE user_id = ?', [req.user.userId]
    );
    if (!sub) {
      return res.json({ plan: 'free', status: 'active', isActive: true });
    }
    // Auto-expire if past expiry
    if (sub.expires_at && new Date(sub.expires_at) < new Date() && sub.plan === 'premium') {
      await pool.query(
        'UPDATE subscriptions SET plan = "free", status = "expired" WHERE user_id = ?',
        [req.user.userId]
      );
      await pool.query('UPDATE users SET is_premium = FALSE WHERE user_id = ?', [req.user.userId]);
      return res.json({ plan: 'free', status: 'expired', isActive: false });
    }
    res.json({
      plan:      sub.plan,
      status:    sub.status,
      expiresAt: sub.expires_at,
      isActive:  sub.status === 'active',
    });
  } catch (err) {
    res.status(500).json({ error: 'Gagal mengambil status langganan' });
  }
};
