-- ════════════════════════════════════════
-- FINPALS DATABASE SCHEMA
-- Run: mysql -u root -p < schema.sql
-- ════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS finpals CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE finpals;

-- ── Users ─────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  user_id     INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100)  NOT NULL,
  email       VARCHAR(100)  UNIQUE NOT NULL,
  phone       VARCHAR(20),
  password    VARCHAR(255),
  avatar_url  TEXT,
  provider    ENUM('local','google','whatsapp') DEFAULT 'local',
  is_verified BOOLEAN DEFAULT FALSE,
  is_premium  BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ── Sessions ──────────────────────────────
CREATE TABLE IF NOT EXISTS sessions (
  session_id  INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT NOT NULL,
  token       TEXT NOT NULL,
  device_info VARCHAR(255),
  ip_address  VARCHAR(45),
  expires_at  TIMESTAMP NOT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ── Email Verification ────────────────────
CREATE TABLE IF NOT EXISTS email_verifications (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT NOT NULL,
  token       VARCHAR(255) UNIQUE NOT NULL,
  expires_at  TIMESTAMP NOT NULL,
  used        BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ── OTP ───────────────────────────────────
CREATE TABLE IF NOT EXISTS otps (
  otp_id      INT AUTO_INCREMENT PRIMARY KEY,
  phone       VARCHAR(20) NOT NULL,
  otp_code    VARCHAR(6)  NOT NULL,
  expires_at  TIMESTAMP NOT NULL,
  used        BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ── Categories ────────────────────────────
CREATE TABLE IF NOT EXISTS categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT DEFAULT NULL,
  name        VARCHAR(50)  NOT NULL,
  icon        VARCHAR(50),
  color       VARCHAR(20),
  is_default  BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ── Transactions ──────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  transaction_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id        INT NOT NULL,
  merchant_name  VARCHAR(150),
  amount         DECIMAL(12,2) NOT NULL,
  category_id    INT,
  date           DATE NOT NULL,
  notes          TEXT,
  source         ENUM('manual','ocr','ai') DEFAULT 'manual',
  image_url      TEXT,
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id)      REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (category_id)  REFERENCES categories(category_id),
  INDEX idx_user_date (user_id, date),
  INDEX idx_user_category (user_id, category_id)
) ENGINE=InnoDB;

-- ── OCR Logs ──────────────────────────────
CREATE TABLE IF NOT EXISTS ocr_logs (
  ocr_id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id        INT NOT NULL,
  transaction_id INT,
  image_url      TEXT,
  raw_text       TEXT,
  parsed_data    JSON,
  confidence     DECIMAL(5,2),
  status         ENUM('success','failed','partial') DEFAULT 'partial',
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ── Budgets ───────────────────────────────
CREATE TABLE IF NOT EXISTS budgets (
  budget_id   INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT NOT NULL,
  category_id INT,
  amount      DECIMAL(12,2) NOT NULL,
  period      ENUM('weekly','monthly') DEFAULT 'monthly',
  month       INT,
  year        INT,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id)     REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(category_id)
) ENGINE=InnoDB;

-- ── AI Insights ───────────────────────────
CREATE TABLE IF NOT EXISTS ai_insights (
  insight_id   INT AUTO_INCREMENT PRIMARY KEY,
  user_id      INT NOT NULL,
  type         ENUM('tip','warning','prediction','summary') DEFAULT 'tip',
  title        VARCHAR(150),
  content      TEXT,
  is_read      BOOLEAN DEFAULT FALSE,
  generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ── Subscriptions ─────────────────────────
CREATE TABLE IF NOT EXISTS subscriptions (
  sub_id      INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT NOT NULL UNIQUE,
  plan        ENUM('free','premium') DEFAULT 'free',
  started_at  TIMESTAMP NULL,
  expires_at  TIMESTAMP NULL,
  status      ENUM('active','expired','cancelled') DEFAULT 'active',
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ── Payments ──────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
  payment_id      INT AUTO_INCREMENT PRIMARY KEY,
  user_id         INT NOT NULL,
  order_id        VARCHAR(100) UNIQUE NOT NULL,
  amount          DECIMAL(12,2),
  status          ENUM('pending','success','failed','expired') DEFAULT 'pending',
  snap_token      TEXT,
  payment_method  VARCHAR(50),
  paid_at         TIMESTAMP NULL,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ── Notifications ─────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  notif_id   INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT NOT NULL,
  type       ENUM('email','whatsapp','push') DEFAULT 'push',
  title      VARCHAR(150),
  message    TEXT,
  is_read    BOOLEAN DEFAULT FALSE,
  is_sent    BOOLEAN DEFAULT FALSE,
  sent_at    TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ════════════════════════════════════════
-- SEED DATA
-- ════════════════════════════════════════

INSERT IGNORE INTO categories (category_id, name, icon, color) VALUES
(1,  'Makanan',    'restaurant',    '#10b981'),
(2,  'Belanja',    'shopping_bag',  '#2dd4bf'),
(3,  'Transport',  'directions_car','#60a5fa'),
(4,  'Hiburan',    'celebration',   '#a78bfa'),
(5,  'Kesehatan',  'favorite',      '#f87171'),
(6,  'Pendidikan', 'school',        '#fbbf24'),
(7,  'Tagihan',    'receipt_long',  '#94a3b8'),
(8,  'Lainnya',    'more_horiz',    '#6b7280');
