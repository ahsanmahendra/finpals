class ApiConstants {
  ApiConstants._();

  // Change this to your ngrok URL when testing on physical device
  static const String baseUrl =
      'http://10.0.2.2:3000'; // Android emulator localhost
  // static const String baseUrl = 'https://xxxx.ngrok.io'; // ngrok for physical device

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String refreshToken = '/api/auth/refresh';
  static const String googleAuth = '/api/auth/google';
  static const String sendOtp = '/api/auth/send-otp';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String verifyEmail = '/api/auth/verify-email';

  // User / Profile
  static const String profile = '/api/user/profile';
  static const String updateProfile = '/api/user/profile';
  static const String uploadAvatar = '/api/user/avatar';
  static const String changePassword = '/api/user/change-password';

  // Transactions
  static const String transactions = '/api/transactions';
  static const String transaction = '/api/transactions'; // + /:id
  static const String summary = '/api/transactions/summary';
  static const String monthlyStats = '/api/transactions/monthly-stats';

  // Categories
  static const String categories = '/api/categories';

  // Budget
  static const String budgets = '/api/budgets';

  // OCR
  static const String scanReceipt = '/api/ocr/scan';

  // AI
  static const String aiInsights = '/api/ai/insights';
  static const String aiAnalyze = '/api/ai/analyze';
  static const String aiRecommend = '/api/ai/recommend';
  static const String aiBudgetSuggest = '/api/ai/budget-suggest';
  static const String aiChat = '/api/ai/chat';

  // Payment
  static const String createPayment = '/api/payment/create';
  static const String paymentHistory = '/api/payment/history';
  static const String subscriptionStatus = '/api/payment/subscription';
  static const String paymentWebhook = '/api/payment/webhook';

  // Notifications
  static const String notifications = '/api/notifications';
  static const String markNotifRead = '/api/notifications/read';
}
