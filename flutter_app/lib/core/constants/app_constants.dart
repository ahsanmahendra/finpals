class AppConstants {
  AppConstants._();

  static const String appName    = 'Finpals';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String tokenKey    = 'finpals_token';
  static const String userKey     = 'finpals_user';
  static const String onboardKey  = 'finpals_onboarded';

  // Pagination
  static const int pageSize = 20;

  // Animation durations
  static const int animFast   = 200;
  static const int animNormal = 350;
  static const int animSlow   = 500;

  // Midtrans Sandbox Client Key (safe to expose in frontend)
  static const String midtransClientKey = 'SB-Mid-client-GANTI_INI';
  static const String midtransSnapUrl   = 'https://app.sandbox.midtrans.com/snap/snap.js';

  // Premium price
  static const int premiumPrice = 29000; // Rp 29.000/bulan

  // Max image size (5MB)
  static const int maxImageSizeBytes = 5 * 1024 * 1024;

  // Category icons (maps to category_id order in DB)
  static const List<String> categoryIconNames = [
    'restaurant',
    'shopping_bag',
    'directions_car',
    'celebration',
    'favorite',
    'school',
    'receipt_long',
    'more_horiz',
  ];
}
