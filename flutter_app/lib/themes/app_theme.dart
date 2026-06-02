import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────
// FINPALS COLOR SYSTEM
// Emerald/Teal palette — mirrors React existing
// ─────────────────────────────────────────
class AppColors {
  AppColors._();

  // Primary — Emerald
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald300 = Color(0xFF6EE7B7);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);
  static const emerald800 = Color(0xFF065F46);

  // Secondary — Teal
  static const teal300 = Color(0xFF5EEAD4);
  static const teal400 = Color(0xFF2DD4BF);
  static const teal500 = Color(0xFF14B8A6);
  static const teal600 = Color(0xFF0D9488);

  // Accent colors for categories
  static const blue400 = Color(0xFF60A5FA);
  static const purple400 = Color(0xFFA78BFA);
  static const rose400 = Color(0xFFFB7185);
  static const amber400 = Color(0xFFFBBF24);
  static const orange400 = Color(0xFFFB923C);

  // Neutral — Gray
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);

  // Semantic
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
  static const info = Color(0xFF3B82F6);

  // Background — matches React #e2f1ed
  static const appBackground = Color(0xFFE2F1ED);
  static const cardBackground = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FBFA);

  // Category colors (maps to DB categories)
  static const categoryColors = [
    emerald500, // Makanan
    teal400, // Belanja
    blue400, // Transport
    purple400, // Hiburan
    rose400, // Kesehatan
    amber400, // Pendidikan
    gray400, // Tagihan
    gray500, // Lainnya
  ];
}

// ─────────────────────────────────────────
// TEXT STYLES
// ─────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static const displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.gray800,
    height: 1.2,
  );
  static const displayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.gray800,
    height: 1.3,
  );
  static const headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.gray800,
  );
  static const headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.gray800,
  );
  static const headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.gray800,
  );
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.gray700,
  );
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.gray600,
  );
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.gray400,
  );
  static const labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.gray800,
  );
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.gray400,
    letterSpacing: 0.5,
  );
}

// ─────────────────────────────────────────
// THEME
// ─────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const primary = AppColors.emerald500;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.appBackground,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.teal500,
        surface: AppColors.cardBackground,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.gray800),
        titleTextStyle: AppTextStyles.headingMedium,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),

      // ElevatedButton — primary CTA
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.emerald200,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: AppColors.emerald500, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.emerald500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        labelStyle: const TextStyle(
          color: AppColors.gray500,
          fontFamily: 'Inter',
        ),
        hintStyle: const TextStyle(
          color: AppColors.gray400,
          fontFamily: 'Inter',
        ),
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontSize: 12,
          fontFamily: 'Inter',
        ),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.emerald500,
        unselectedItemColor: AppColors.gray400,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          fontFamily: 'Inter',
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.emerald50,
        selectedColor: AppColors.emerald500,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.gray100,
        thickness: 1,
        space: 0,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.gray800,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
