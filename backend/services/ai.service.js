const { pool } = require('../config/db');

// ─────────────────────────────────────────
// CATEGORY SUGGESTION (rule-based)
// ─────────────────────────────────────────
const CATEGORY_KEYWORDS = {
  1: ['makan', 'food', 'resto', 'restaurant', 'kafe', 'cafe', 'warung', 'kedai',
      'mcdonald', 'kfc', 'pizza', 'burger', 'bakery', 'indomaret', 'alfamart',
      'supermarket', 'minimarket', 'swalayan', 'rice', 'nasi', 'sate', 'bakso'],
  2: ['shop', 'belanja', 'toko', 'market', 'mall', 'fashion', 'clothing', 'baju',
      'sepatu', 'shoes', 'tokopedia', 'shopee', 'lazada', 'olshop', 'store'],
  3: ['transport', 'gojek', 'grab', 'ojek', 'taksi', 'taxi', 'bus', 'krl',
      'mrt', 'bensin', 'bbm', 'parkir', 'toll', 'tol', 'pertamina', 'shell'],
  4: ['hiburan', 'cinema', 'bioskop', 'game', 'netflix', 'spotify', 'youtube',
      'disney', 'konser', 'tiket', 'ticket', 'entertainment', 'leisure'],
  5: ['apotek', 'apotik', 'pharmacy', 'klinik', 'clinic', 'rumah sakit', 'hospital',
      'dokter', 'doctor', 'obat', 'medicine', 'health', 'kesehatan', 'lab'],
  6: ['sekolah', 'kampus', 'universitas', 'buku', 'book', 'pendidikan', 'kursus',
      'course', 'les', 'education', 'stationery', 'alat tulis'],
  7: ['listrik', 'pln', 'air', 'pdam', 'internet', 'wifi', 'telkom', 'indihome',
      'tagihan', 'bill', 'pulsa', 'token', 'bpjs', 'cicilan', 'kredit'],
};

exports.suggestCategory = async (merchantName, items = []) => {
  const text = [
    merchantName,
    ...items.map(i => i.name || ''),
  ].join(' ').toLowerCase();

  let bestCat   = 8; // Lainnya
  let bestScore = 0;

  for (const [catId, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
    const score = keywords.filter(kw => text.includes(kw)).length;
    if (score > bestScore) {
      bestScore = score;
      bestCat   = parseInt(catId);
    }
  }

  const [[cat]] = await pool.query(
    'SELECT category_id, name FROM categories WHERE category_id = ?', [bestCat]
  );

  return {
    categoryId:   cat?.category_id || 8,
    categoryName: cat?.name || 'Lainnya',
    confidence:   bestScore > 0 ? Math.min(bestScore / 3, 1) : 0,
  };
};

// ─────────────────────────────────────────
// GENERATE INSIGHTS FOR USER
// ─────────────────────────────────────────
exports.generateInsightsForUser = async (userId) => {
  const now   = new Date();
  const month = now.getMonth() + 1;
  const year  = now.getFullYear();

  // Get this month's spending
  const [[monthly]] = await pool.query(
    `SELECT COALESCE(SUM(amount), 0) AS total,  COUNT(*) AS count
     FROM transactions WHERE user_id = ? AND MONTH(date) = ? AND YEAR(date) = ?`,
    [userId, month, year]
  );

  // Get last month's spending
  const lastMonth = month === 1 ? 12 : month - 1;
  const lastYear  = month === 1 ? year - 1 : year;
  const [[lastMonthly]] = await pool.query(
    `SELECT COALESCE(SUM(amount), 0) AS total
     FROM transactions WHERE user_id = ? AND MONTH(date) = ? AND YEAR(date) = ?`,
    [userId, lastMonth, lastYear]
  );

  // Category breakdown
  const [cats] = await pool.query(
    `SELECT c.name, SUM(t.amount) AS total
     FROM transactions t JOIN categories c ON t.category_id = c.category_id
     WHERE t.user_id = ? AND MONTH(t.date) = ? AND YEAR(t.date) = ?
     GROUP BY t.category_id ORDER BY total DESC LIMIT 3`,
    [userId, month, year]
  );

  const insights = [];
  const totalNow  = parseFloat(monthly.total);
  const totalLast = parseFloat(lastMonthly.total);

  // ── Insight 1: Month comparison ─────────
  if (totalLast > 0) {
    const diff = ((totalNow - totalLast) / totalLast) * 100;
    const type = diff > 20 ? 'warning' : diff < -10 ? 'tip' : 'summary';
    const title = diff > 20
      ? '⚠️ Pengeluaran Meningkat'
      : diff < -10
        ? '✅ Pengeluaran Menurun'
        : '📊 Ringkasan Bulanan';
    const content = diff > 20
      ? `Pengeluaran bulan ini ${Math.abs(diff).toFixed(0)}% lebih tinggi dari bulan lalu. Coba review pengeluaran tidak perlu.`
      : diff < -10
        ? `Bagus! Pengeluaran bulan ini berkurang ${Math.abs(diff).toFixed(0)}% dibanding bulan lalu. Terus pertahankan!`
        : `Pengeluaran bulan ini Rp ${_formatNum(totalNow)}, hampir sama dengan bulan lalu.`;

    insights.push({ type, title, content });
  } else if (totalNow > 0) {
    insights.push({
      type:    'tip',
      title:   '👋 Mulai Pantau Keuangan',
      content: `Kamu sudah mencatat ${monthly.count} transaksi bulan ini senilai Rp ${_formatNum(totalNow)}. Terus catat untuk mendapatkan insight lebih akurat!`,
    });
  }

  // ── Insight 2: Top spending category ────
  if (cats.length > 0) {
    const top = cats[0];
    const pct = totalNow > 0 ? ((top.total / totalNow) * 100).toFixed(0) : 0;
    insights.push({
      type:    pct > 50 ? 'warning' : 'tip',
      title:   `🍽️ Kategori Terbesar: ${top.name}`,
      content: `${pct}% pengeluaranmu bulan ini berasal dari kategori ${top.name} (Rp ${_formatNum(top.total)}). ${pct > 50 ? 'Pertimbangkan untuk menguranginya.' : 'Distribusi yang cukup baik!'}`,
    });
  }

  // ── Insight 3: Budget check ──────────────
  const [budgets] = await pool.query(
    `SELECT b.amount, COALESCE(SUM(t.amount), 0) AS spent, c.name AS cat_name
     FROM budgets b
     LEFT JOIN transactions t ON t.user_id = b.user_id
       AND t.category_id = b.category_id
       AND MONTH(t.date) = ? AND YEAR(t.date) = ?
     LEFT JOIN categories c ON b.category_id = c.category_id
     WHERE b.user_id = ? AND b.month = ? AND b.year = ?
     GROUP BY b.budget_id`,
    [month, year, userId, month, year]
  );

  const overBudget = budgets.filter(b => parseFloat(b.spent) > b.amount);
  if (overBudget.length > 0) {
    insights.push({
      type:    'warning',
      title:   '🚨 Budget Terlampaui',
      content: `Kamu telah melampaui budget di ${overBudget.length} kategori: ${overBudget.map(b => b.cat_name).join(', ')}. Waktunya mengerem pengeluaran!`,
    });
  }

  // ── Insight 4: Spending prediction ──────
  if (monthly.count >= 5 && totalNow > 0) {
    const dayOfMonth  = now.getDate();
    const daysInMonth = new Date(year, month, 0).getDate();
    const projected   = (totalNow / dayOfMonth) * daysInMonth;

    insights.push({
      type:    'prediction',
      title:   '🔮 Prediksi Akhir Bulan',
      content: `Berdasarkan pola sekarang, pengeluaran kamu akhir bulan diperkirakan sekitar Rp ${_formatNum(projected)}.`,
    });
  }

  // Save to DB (replace old insights for this month)
  if (insights.length) {
    await pool.query(
      'DELETE FROM ai_insights WHERE user_id = ? AND generated_at >= DATE_FORMAT(NOW(), "%Y-%m-01")',
      [userId]
    );
    for (const ins of insights) {
      await pool.query(
        'INSERT INTO ai_insights (user_id, type, title, content) VALUES (?, ?, ?, ?)',
        [userId, ins.type, ins.title, ins.content]
      );
    }
    // Re-fetch with IDs
    const [saved] = await pool.query(
      'SELECT * FROM ai_insights WHERE user_id = ? ORDER BY generated_at DESC LIMIT 10',
      [userId]
    );
    return saved;
  }

  return [];
};

// ─────────────────────────────────────────
// SPENDING RECOMMENDATIONS
// ─────────────────────────────────────────
exports.getSpendingRecommendations = async (userId) => {
  const now   = new Date();
  const month = now.getMonth() + 1;
  const year  = now.getFullYear();

  const [cats] = await pool.query(
    `SELECT c.name, SUM(t.amount) AS total
     FROM transactions t JOIN categories c ON t.category_id = c.category_id
     WHERE t.user_id = ? AND MONTH(t.date) = ? AND YEAR(t.date) = ?
     GROUP BY t.category_id ORDER BY total DESC`,
    [userId, month, year]
  );

  const recs = [];
  for (const cat of cats) {
    if (cat.name === 'Makanan' && cat.total > 1_500_000) {
      recs.push(`💡 Pengeluaran makanan bulan ini Rp ${_formatNum(cat.total)}. Coba masak sendiri beberapa hari untuk hemat hingga 40%.`);
    }
    if (cat.name === 'Transport' && cat.total > 500_000) {
      recs.push(`🚌 Transportasi menghabiskan Rp ${_formatNum(cat.total)} bulan ini. Pertimbangkan transportasi umum atau carpooling.`);
    }
    if (cat.name === 'Hiburan' && cat.total > 300_000) {
      recs.push(`🎮 Hiburan sudah Rp ${_formatNum(cat.total)}. Cek apakah ada langganan yang tidak terpakai.`);
    }
    if (cat.name === 'Belanja' && cat.total > 1_000_000) {
      recs.push(`🛍️ Belanja mencapai Rp ${_formatNum(cat.total)}. Buat daftar belanja sebelum berbelanja untuk mengurangi impulsif buying.`);
    }
  }

  if (!recs.length) {
    recs.push('✅ Pengeluaran kamu bulan ini terlihat terkontrol. Pertahankan!');
  }

  return recs;
};

// ─────────────────────────────────────────
// BUDGET SUGGESTIONS
// ─────────────────────────────────────────
exports.suggestBudgets = async (userId) => {
  // Use 3-month average per category as suggestion
  const [rows] = await pool.query(
    `SELECT c.category_id, c.name,
            AVG(monthly.total) AS avg_monthly
     FROM categories c
     JOIN (
       SELECT category_id, YEAR(date) AS yr, MONTH(date) AS mo,
              SUM(amount) AS total
       FROM transactions
       WHERE user_id = ? AND date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
       GROUP BY category_id, yr, mo
     ) monthly ON c.category_id = monthly.category_id
     GROUP BY c.category_id`,
    [userId]
  );

  const suggestions = rows.map(r => ({
    categoryId:   r.category_id,
    categoryName: r.name,
    suggested:    Math.ceil(parseFloat(r.avg_monthly) * 1.1 / 10000) * 10000, // round up to 10k
    basedOn:      'rata-rata 3 bulan terakhir',
  }));

  return { suggestions };
};

// ─────────────────────────────────────────
// MONTHLY BATCH (cron)
// ─────────────────────────────────────────
exports.generateMonthlyInsightsForAll = async () => {
  const [users] = await pool.query('SELECT user_id FROM users');
  for (const u of users) {
    try {
      await exports.generateInsightsForUser(u.user_id);
    } catch (e) {
      console.error(`AI cron failed for user ${u.user_id}:`, e.message);
    }
  }
};

// ─── Helpers ──────────────────────────────
function _formatNum(n) {
  return Math.round(n)
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, '.');
}
