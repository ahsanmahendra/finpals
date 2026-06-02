# 💰 Finpals — AI-Powered Personal Finance App

> Migrasi dari React + Vite → **Flutter + Express.js + MySQL**  
> Production-ready | Android-first | AI-powered

---

## 🏗️ Tech Stack

| Layer       | Technology                                      |
|-------------|------------------------------------------------|
| Frontend    | Flutter 3.x, Riverpod, GoRouter, fl_chart      |
| Backend     | Express.js, JWT, bcrypt, Multer                |
| Database    | MySQL 8.0                                      |
| OCR         | Tesseract.js (cross-platform, no binary needed) |
| AI          | Rule-based engine + Gemini API ready           |
| Payment     | Midtrans Sandbox (Snap API)                    |
| Email       | Brevo (Sendinblue)                             |
| WhatsApp    | Fonnte OTP                                     |
| Auth        | JWT + Google OAuth + WhatsApp OTP              |

---

## 📁 Project Structure

```
finpals/
├── flutter_app/          ← Flutter frontend
│   ├── lib/
│   │   ├── core/         ← network, constants, errors
│   │   ├── models/       ← data models
│   │   ├── services/     ← API service classes
│   │   ├── providers/    ← Riverpod state
│   │   ├── routes/       ← GoRouter config
│   │   ├── screens/      ← all screens
│   │   ├── widgets/      ← reusable widgets
│   │   ├── themes/       ← colors, typography
│   │   └── utils/        ← helpers
│   └── pubspec.yaml
│
└── backend/              ← Express.js API
    ├── controllers/      ← request handlers
    ├── routes/           ← route definitions
    ├── middleware/        ← auth, upload
    ├── services/         ← OCR, AI, email, WA, Midtrans
    ├── database/         ← schema.sql + migrate.js
    ├── config/           ← db.js
    └── server.js
```

---

## ⚡ Quick Start

### 1. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Copy env file and fill in values
cp .env.example .env
# Edit .env with your credentials

# Create database & run migrations
npm run migrate

# Start development server
npm run dev
# → API running on http://localhost:3000
```

### 2. Flutter Setup

```bash
cd flutter_app

# Get dependencies
flutter pub get

# For emulator (uses 10.0.2.2 = localhost automatically)
flutter run

# For physical device — use ngrok:
# 1. ngrok http 3000
# 2. Copy the https://xxxx.ngrok.io URL
# 3. Edit lib/core/constants/api_constants.dart → baseUrl
# 4. flutter run
```

### 3. Physical Device with ngrok

```bash
# Install ngrok: https://ngrok.com
ngrok http 3000

# Update baseUrl in flutter_app/lib/core/constants/api_constants.dart:
# static const String baseUrl = 'https://xxxx.ngrok.io';
```

---

## 🔑 Environment Variables

Copy `backend/.env.example` to `backend/.env` and fill:

| Variable              | Description                          | Required |
|-----------------------|--------------------------------------|----------|
| `DB_PASSWORD`         | MySQL password                       | ✅       |
| `JWT_SECRET`          | Random secret string (min 32 chars)  | ✅       |
| `MIDTRANS_SERVER_KEY` | Midtrans sandbox server key          | ✅ Pay   |
| `MIDTRANS_CLIENT_KEY` | Midtrans sandbox client key          | ✅ Pay   |
| `BREVO_API_KEY`       | Brevo email API key                  | Optional |
| `FONNTE_TOKEN`        | Fonnte WhatsApp token                | Optional |
| `GOOGLE_CLIENT_ID`    | Google OAuth client ID               | Optional |
| `GEMINI_API_KEY`      | Google Gemini AI key                 | Optional |

> **Note:** Without optional keys, features gracefully degrade  
> (mock logs instead of real sends).

---

## 🔐 Auth Methods

| Method         | Status   | Notes                              |
|----------------|----------|------------------------------------|
| Email/Password | ✅ Ready | bcrypt hashed                      |
| Google OAuth   | ✅ Ready | Needs `GOOGLE_CLIENT_ID`           |
| WhatsApp OTP   | ✅ Ready | Needs `FONNTE_TOKEN`, uses Fonnte  |
| JWT Session    | ✅ Ready | 30 days, stored in secure storage  |

---

## 📊 API Endpoints

### Auth
```
POST /api/auth/register
POST /api/auth/login
POST /api/auth/logout
POST /api/auth/google
POST /api/auth/send-otp
POST /api/auth/verify-otp
POST /api/auth/forgot-password
POST /api/auth/reset-password
```

### Transactions
```
GET    /api/transactions           ?page,limit,category_id,search,start_date,end_date
POST   /api/transactions
PUT    /api/transactions/:id
DELETE /api/transactions/:id
GET    /api/transactions/summary   ?month,year
GET    /api/transactions/monthly-stats
```

### Budget
```
GET    /api/budgets    ?month,year
POST   /api/budgets
PUT    /api/budgets/:id
DELETE /api/budgets/:id
```

### OCR
```
POST /api/ocr/scan     multipart: receipt (image file)
```

### AI
```
GET  /api/ai/insights
POST /api/ai/analyze
GET  /api/ai/recommend
GET  /api/ai/budget-suggest
```

### Payment (Midtrans Sandbox)
```
POST /api/payment/create        → returns snapToken
GET  /api/payment/history
GET  /api/payment/subscription
POST /api/payment/webhook       (called by Midtrans, no auth)
```

---

## 💳 Payment Flow (Midtrans Sandbox)

```
Flutter App
  → POST /api/payment/create
    → Midtrans Sandbox API
    → returns snapToken
  → Open WebView with snapToken
  → User pays in Snap UI
  → Midtrans calls POST /api/payment/webhook
    → Verify signature
    → Update payment status
    → Activate premium (30 days)
    → Send notification
  → Flutter closes WebView → redirect to dashboard
```

---

## 🤖 AI Features

All AI is **rule-based** (no API cost) with easy upgrade path to Gemini:

- **Spending Analysis** — month-over-month comparison
- **Category Insight** — top spending category alert
- **Budget Warning** — over-budget detection  
- **Spending Prediction** — end-of-month projection
- **Smart Categorization** — keyword-based OCR category detection
- **Recommendations** — category-specific saving tips

To enable **Gemini AI**: set `GEMINI_API_KEY` in `.env` and update  
`backend/services/ai.service.js` → replace rule-based with Gemini API calls.

---

## 📱 Screens

| Screen               | Features                                          |
|----------------------|---------------------------------------------------|
| Splash               | Auto-login, session restore                       |
| Login                | Email/pass, Google, WhatsApp OTP                  |
| Register             | Full form + Terms checkbox                        |
| Forgot Password      | Email reset link via Brevo                        |
| OTP Verification     | 6-digit input, countdown, resend                  |
| Dashboard            | Balance card, donut chart, AI insight, quick actions |
| Transaction List     | Search, filter by category, swipe to delete       |
| Add Transaction      | Amount hero input, date picker, category chips    |
| Scan (OCR)           | Camera/gallery, Tesseract OCR, confidence badge   |
| OCR Review           | Edit merchant/total/date, item list, category     |
| Budget               | Progress bars, add/edit/delete, overview card     |
| AI Insights          | Cards by type, analyze button                     |
| Subscription         | Free vs Premium comparison, Midtrans payment      |
| Payment WebView      | Snap UI, success/fail/pending handling            |
| Profile              | Edit name/phone, avatar upload, change password   |

---

## 🚀 Development Phases

- [x] **Phase 1** — Architecture & Foundation
- [x] **Phase 2** — Auth System (JWT + Google + WA OTP)
- [x] **Phase 3** — Transaction CRUD + Dashboard
- [x] **Phase 4** — OCR + AI Categorization
- [x] **Phase 5** — Payment Sandbox (Midtrans)
- [x] **Phase 6** — AI Analytics Engine
- [ ] **Phase 7** — Optimization + ngrok testing + APK build

---

## 🔧 Troubleshooting

**`Connection refused` on physical device?**  
→ Use ngrok: `ngrok http 3000`, update `api_constants.dart`

**OCR returns empty/wrong data?**  
→ Ensure good lighting, clear receipt photo, try different angle

**Midtrans webhook not firing?**  
→ Use ngrok URL as `APP_URL` in `.env`, register in Midtrans dashboard

**Google Login fails?**  
→ Add SHA-1 fingerprint in Firebase Console + Google Cloud Console

---

## 📄 License

MIT — Built for educational purposes.  
**Do NOT use Midtrans production keys in development.**
