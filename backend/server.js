require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const path    = require('path');
const fs      = require('fs');

let cron;
try { cron = require('node-cron'); } catch(_) {}

const app  = express();
const PORT = process.env.PORT || 3000;

// uploads dir
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

app.use(cors({ origin: '*', methods: ['GET','POST','PUT','DELETE','PATCH','OPTIONS'], allowedHeaders: ['Content-Type','Authorization'] }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(uploadsDir));

// Routes
app.use('/api/auth',          require('./routes/auth.routes'));
app.use('/api/user',          require('./routes/user.routes'));
app.use('/api/transactions',  require('./routes/transaction.routes'));
app.use('/api/categories',    require('./routes/category.routes'));
app.use('/api/budgets',       require('./routes/budget.routes'));
app.use('/api/ocr',           require('./routes/ocr.routes'));
app.use('/api/ai',            require('./routes/ai.routes'));
app.use('/api/payment',       require('./routes/payment.routes'));
app.use('/api/notifications', require('./routes/notification.routes'));

app.get('/health', (_, res) => res.json({ status: 'ok', app: 'Finpals API', time: new Date().toISOString() }));
app.use((req, res) => res.status(404).json({ error: `Route ${req.path} not found` }));
app.use((err, req, res, _next) => { console.error(err); res.status(500).json({ error: 'Internal server error' }); });

// Clean expired sessions daily
if (cron) {
  cron.schedule('0 2 * * *', async () => {
    const { pool } = require('./config/db');
    const [r] = await pool.query('DELETE FROM sessions WHERE expires_at < NOW()').catch(() => [{}]);
    console.log(`Cleaned expired sessions`);
  });
}

app.listen(PORT, () => console.log(`Finpals API on port ${PORT} [${process.env.NODE_ENV||'dev'}]`));
