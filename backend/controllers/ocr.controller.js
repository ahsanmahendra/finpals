const path       = require('path');
const { pool }   = require('../config/db');
const ocrService = require('../services/ocr.service');
const aiService  = require('../services/ai.service');

// ── POST /api/ocr/scan ────────────────────
exports.scanReceipt = async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'File gambar wajib diupload' });
  }

  const userId   = req.user.userId;
  const filePath = req.file.path;
  const imageUrl = `/uploads/${req.file.filename}`;

  try {
    // Run OCR
    const ocrResult = await ocrService.processReceipt(filePath);

    // AI auto-categorization based on merchant name
    let suggestedCategoryId   = null;
    let suggestedCategoryName = null;
    try {
      const catResult = await aiService.suggestCategory(ocrResult.merchant, ocrResult.items);
      suggestedCategoryId   = catResult.categoryId;
      suggestedCategoryName = catResult.categoryName;
    } catch (_) {}

    // Save OCR log
    await pool.query(
      `INSERT INTO ocr_logs (user_id, image_url, raw_text, parsed_data, confidence, status)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        userId,
        imageUrl,
        ocrResult.rawText,
        JSON.stringify(ocrResult),
        ocrResult.confidence,
        ocrResult.total > 0 ? 'success' : 'partial',
      ]
    );

    res.json({
      data: {
        merchant:              ocrResult.merchant,
        total:                 ocrResult.total,
        date:                  ocrResult.date,
        items:                 ocrResult.items,
        confidence:            ocrResult.confidence,
        rawText:               ocrResult.rawText,
        image_url:             imageUrl,
        suggestedCategoryId,
        suggestedCategory:     suggestedCategoryName,
      },
    });
  } catch (err) {
    console.error('scanReceipt error:', err);
    res.status(500).json({ error: 'Gagal memproses struk: ' + err.message });
  }
};
