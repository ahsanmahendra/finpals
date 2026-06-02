const Tesseract = require('tesseract.js');

/**
 * Process receipt image with Tesseract.js
 * Returns: { merchant, total, date, items, confidence, rawText }
 */
exports.processReceipt = async (imagePath) => {
  let worker;
  try {
    worker = await Tesseract.createWorker(['ind', 'eng'], 1, {
      logger: () => {},  // suppress progress logs
    });

    const { data } = await worker.recognize(imagePath);
    const rawText  = data.text || '';
    const conf     = data.confidence || 0;

    const parsed = _parseReceiptText(rawText);
    return {
      ...parsed,
      confidence: conf,
      rawText,
    };
  } finally {
    if (worker) await worker.terminate();
  }
};

// ─────────────────────────────────────────
// PARSER
// ─────────────────────────────────────────
function _parseReceiptText(text) {
  const lines = text
    .split('\n')
    .map(l => l.trim())
    .filter(l => l.length > 0);

  return {
    merchant: _extractMerchant(lines),
    total:    _extractTotal(lines, text),
    date:     _extractDate(text),
    items:    _extractItems(lines),
  };
}

function _extractMerchant(lines) {
  // First non-numeric line of length > 3 is likely the merchant
  for (const line of lines.slice(0, 6)) {
    if (line.length >= 3 && !/^\d/.test(line) && !/total|subtotal|bayar|tagihan/i.test(line)) {
      return line.replace(/[^a-zA-Z0-9\s\-&.]/g, '').trim() || 'Merchant Tidak Terdeteksi';
    }
  }
  return 'Merchant Tidak Terdeteksi';
}

function _extractTotal(lines, fullText) {
  // Strategy 1: Look for keyword followed by amount
  const totalKeyword = /(?:total|grand total|jumlah|tagihan|bayar|pembayaran|amount due)/i;
  for (const line of lines) {
    if (totalKeyword.test(line)) {
      const nums = line.replace(/[.,]/g, '').match(/\d{4,10}/g);
      if (nums) {
        const candidates = nums.map(Number).filter(n => n >= 1000 && n <= 99_000_000);
        if (candidates.length) return Math.max(...candidates);
      }
    }
  }

  // Strategy 2: Largest plausible number in the receipt
  const allNums = fullText.replace(/[.,]/g, '').match(/\d{4,8}/g) || [];
  const plausible = allNums
    .map(Number)
    .filter(n => n >= 1000 && n <= 10_000_000)
    .sort((a, b) => b - a);

  return plausible[0] || 0;
}

function _extractDate(text) {
  const today = new Date();
  const fmt   = d => `${d.getFullYear()}-${String(d.getMonth()+1).padLeft(2,'0')}-${String(d.getDate()).padLeft(2,'0')}`;

  // Extend String prototype locally
  String.prototype.padLeft = function(n, c) { return this.padStart(n, c); };

  // Patterns: dd/mm/yyyy | dd-mm-yyyy | yyyy-mm-dd | dd Mon yyyy
  const patterns = [
    { re: /(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})/, fn: m => `${m[3]}-${m[2].padLeft(2,'0')}-${m[1].padLeft(2,'0')}` },
    { re: /(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})/, fn: m => `${m[1]}-${m[2].padLeft(2,'0')}-${m[3].padLeft(2,'0')}` },
    {
      re: /(\d{1,2})\s+(jan|feb|mar|apr|mei|may|jun|jul|agu|aug|sep|okt|oct|nov|des|dec)[a-z]*\.?\s*(\d{2,4})/i,
      fn: (m) => {
        const monthMap = { jan:1,feb:2,mar:3,apr:4,mei:5,may:5,jun:6,jul:7,agu:8,aug:8,sep:9,okt:10,oct:10,nov:11,des:12,dec:12 };
        const mo = monthMap[m[2].toLowerCase().slice(0,3)] || 1;
        const yr = m[3].length === 2 ? `20${m[3]}` : m[3];
        return `${yr}-${String(mo).padLeft(2,'0')}-${m[1].padLeft(2,'0')}`;
      },
    },
  ];

  for (const { re, fn } of patterns) {
    const m = text.match(re);
    if (m) {
      try {
        const dateStr = fn(m);
        const d = new Date(dateStr);
        if (!isNaN(d) && d <= today) return dateStr;
      } catch (_) {}
    }
  }

  // Default to today
  return `${today.getFullYear()}-${String(today.getMonth()+1).padStart(2,'0')}-${String(today.getDate()).padStart(2,'0')}`;
}

function _extractItems(lines) {
  const items = [];
  const skip  = /total|subtotal|bayar|tagihan|diskon|discount|tax|pajak|ppn|cash|tunai|kembalian|change/i;

  for (const line of lines) {
    if (skip.test(line)) continue;
    // Pattern: "Item Name   12.000" or "2x Item Name   24.000"
    const match = line.match(/^(\d+\s*[xX])?\s*(.{3,30}?)\s{2,}([\d.,]{4,})$/);
    if (match) {
      const price = parseInt(match[3].replace(/[.,]/g, ''));
      if (price >= 500 && price <= 5_000_000) {
        const qty  = match[1] ? parseInt(match[1]) : 1;
        items.push({ name: match[2].trim(), price, qty });
      }
    }
  }
  return items.slice(0, 20); // cap at 20 items
}
