// ════════════════════════════════════════
// MIDTRANS SERVICE
// ════════════════════════════════════════
const midtransClient = require('midtrans-client');

const snap = new midtransClient.Snap({
  isProduction: false, // SANDBOX only
  serverKey:    process.env.MIDTRANS_SERVER_KEY,
  clientKey:    process.env.MIDTRANS_CLIENT_KEY,
});

exports.createSnapToken = async ({ orderId, amount, user }) => {
  const param = {
    transaction_details: {
      order_id:     orderId,
      gross_amount: parseInt(amount),
    },
    customer_details: {
      first_name: user.name || 'Finpals User',
      email:      user.email || 'user@finpals.app',
      phone:      user.phone || '',
    },
    item_details: [{
      id:       'FINPALS_PREMIUM_1M',
      price:    parseInt(amount),
      quantity: 1,
      name:     'Finpals Premium - 1 Bulan',
    }],
    callbacks: {
      finish:  `${process.env.APP_URL}/payment/finish`,
      error:   `${process.env.APP_URL}/payment/error`,
      pending: `${process.env.APP_URL}/payment/pending`,
    },
  };

  const transaction = await snap.createTransaction(param);
  return transaction.token;
};

// ════════════════════════════════════════
// EMAIL SERVICE (Brevo / SMTP fallback)
// ════════════════════════════════════════
const axios = require('axios');

async function _sendBrevoEmail({ to, toName, subject, htmlContent }) {
  if (!process.env.BREVO_API_KEY || process.env.BREVO_API_KEY.startsWith('REPLACE')) {
    console.log(`[Email MOCK] To: ${to} | Subject: ${subject}`);
    return;
  }
  try {
    await axios.post(
      'https://api.brevo.com/v3/smtp/email',
      {
        sender: {
          name:  process.env.BREVO_FROM_NAME  || 'Finpals',
          email: process.env.BREVO_FROM_EMAIL || 'noreply@finpals.app',
        },
        to: [{ email: to, name: toName || to }],
        subject,
        htmlContent,
      },
      {
        headers: {
          'api-key':      process.env.BREVO_API_KEY,
          'Content-Type': 'application/json',
        },
      }
    );
  } catch (err) {
    console.error('Brevo email error:', err.response?.data || err.message);
  }
}

exports.sendWelcomeEmail = async (email, name) => {
  await _sendBrevoEmail({
    to:          email,
    toName:      name,
    subject:     '🎉 Selamat datang di Finpals!',
    htmlContent: `
      <div style="font-family:Inter,sans-serif;max-width:520px;margin:auto;padding:32px;background:#f8fbfa;border-radius:16px;">
        <div style="text-align:center;margin-bottom:24px;">
          <div style="background:linear-gradient(135deg,#10b981,#047857);width:64px;height:64px;border-radius:16px;display:inline-flex;align-items:center;justify-content:center;margin-bottom:16px;">
            <span style="font-size:28px;">💰</span>
          </div>
          <h1 style="color:#1f2937;font-size:24px;margin:0;">Selamat datang, ${name}!</h1>
        </div>
        <p style="color:#4b5563;line-height:1.6;">
          Akun Finpals kamu sudah berhasil dibuat. Mulai pantau keuanganmu dengan fitur:
        </p>
        <ul style="color:#4b5563;line-height:2;">
          <li>📊 Dashboard pengeluaran real-time</li>
          <li>📸 Scan struk otomatis dengan OCR</li>
          <li>🤖 AI insight pengeluaran personal</li>
          <li>💰 Budget tracker pintar</li>
        </ul>
        <div style="text-align:center;margin-top:28px;">
          <a href="${process.env.APP_URL}" style="background:#10b981;color:white;padding:12px 28px;border-radius:12px;text-decoration:none;font-weight:700;">
            Buka Finpals
          </a>
        </div>
        <p style="color:#9ca3af;font-size:12px;text-align:center;margin-top:24px;">
          Finpals — Kelola keuanganmu lebih cerdas
        </p>
      </div>
    `,
  });
};

exports.sendPasswordResetEmail = async (email, name, resetUrl) => {
  await _sendBrevoEmail({
    to:          email,
    toName:      name,
    subject:     '🔐 Reset Password Finpals',
    htmlContent: `
      <div style="font-family:Inter,sans-serif;max-width:520px;margin:auto;padding:32px;background:#f8fbfa;border-radius:16px;">
        <h2 style="color:#1f2937;">Reset Password</h2>
        <p style="color:#4b5563;">Halo ${name}, klik tombol di bawah untuk mereset password akun Finpals kamu.</p>
        <p style="color:#ef4444;font-size:13px;">⚠️ Link ini akan kadaluarsa dalam 1 jam.</p>
        <div style="text-align:center;margin:28px 0;">
          <a href="${resetUrl}" style="background:#10b981;color:white;padding:12px 28px;border-radius:12px;text-decoration:none;font-weight:700;">
            Reset Password
          </a>
        </div>
        <p style="color:#9ca3af;font-size:12px;">Jika kamu tidak meminta reset password, abaikan email ini.</p>
      </div>
    `,
  });
};

exports.sendBudgetAlertEmail = async (email, name, categoryName, spent, budget) => {
  const pct = Math.round((spent / budget) * 100);
  await _sendBrevoEmail({
    to:          email,
    toName:      name,
    subject:     `⚠️ Budget ${categoryName} hampir habis — Finpals`,
    htmlContent: `
      <div style="font-family:Inter,sans-serif;max-width:520px;margin:auto;padding:32px;background:#fef9f0;border-radius:16px;border:1px solid #fbbf24;">
        <h2 style="color:#d97706;">⚠️ Peringatan Budget</h2>
        <p style="color:#4b5563;">Halo ${name}, budget kategori <strong>${categoryName}</strong> kamu sudah ${pct}% terpakai.</p>
        <div style="background:white;padding:16px;border-radius:12px;margin:16px 0;">
          <div style="display:flex;justify-content:space-between;">
            <span>Terpakai:</span><strong>Rp ${_fmtNum(spent)}</strong>
          </div>
          <div style="display:flex;justify-content:space-between;margin-top:8px;">
            <span>Budget:</span><strong>Rp ${_fmtNum(budget)}</strong>
          </div>
        </div>
      </div>
    `,
  });
};

// ════════════════════════════════════════
// WHATSAPP SERVICE (Fonnte)
// ════════════════════════════════════════
exports.sendOtp = async (phone, otp) => {
  if (!process.env.FONNTE_TOKEN || process.env.FONNTE_TOKEN.startsWith('REPLACE')) {
    console.log(`[WhatsApp MOCK] OTP ${otp} → ${phone}`);
    return;
  }
  try {
    await axios.post(
      'https://api.fonnte.com/send',
      {
        target:  phone,
        message: `🔐 Kode OTP Finpals kamu: *${otp}*\n\nBerlaku 5 menit. JANGAN bagikan kode ini ke siapapun.\n\n_Finpals — Kelola keuanganmu lebih cerdas_`,
      },
      { headers: { Authorization: process.env.FONNTE_TOKEN } }
    );
  } catch (err) {
    console.error('Fonnte error:', err.response?.data || err.message);
    throw new Error('Gagal mengirim OTP WhatsApp');
  }
};

exports.sendBudgetAlertWA = async (phone, name, categoryName, pct) => {
  if (!process.env.FONNTE_TOKEN || process.env.FONNTE_TOKEN.startsWith('REPLACE')) {
    console.log(`[WhatsApp MOCK] Budget alert → ${phone}`);
    return;
  }
  try {
    await axios.post(
      'https://api.fonnte.com/send',
      {
        target:  phone,
        message: `⚠️ *Finpals Budget Alert*\n\nHalo ${name}! Budget kategori *${categoryName}* kamu sudah ${pct}% terpakai bulan ini.\n\nYuk mulai hemat sebelum budget habis! 💪`,
      },
      { headers: { Authorization: process.env.FONNTE_TOKEN } }
    );
  } catch (err) {
    console.error('Fonnte alert error:', err.message);
  }
};

// helper
function _fmtNum(n) {
  return Math.round(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
}
