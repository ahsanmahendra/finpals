const jwt  = require('jsonwebtoken');
const { pool } = require('../config/db');

module.exports = async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token tidak ditemukan' });
  }

  const token = header.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Validate session is still alive in DB
    const [rows] = await pool.query(
      'SELECT session_id FROM sessions WHERE token = ? AND expires_at > NOW()',
      [token]
    );
    if (rows.length === 0) {
      return res.status(401).json({ error: 'Sesi habis, silakan login ulang' });
    }

    req.user = decoded; // { userId, email }
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    return res.status(401).json({ error: 'Token tidak valid' });
  }
};
