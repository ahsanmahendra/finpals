import 'package:intl/intl.dart';

class AppUtils {
  AppUtils._();

  // ── Currency ──────────────────────────────
  static String formatRupiah(double amount, {bool compact = false}) {
    if (compact) {
      if (amount >= 1_000_000_000) {
        return 'Rp ${(amount / 1_000_000_000).toStringAsFixed(1)}M';
      }
      if (amount >= 1_000_000) {
        return 'Rp ${(amount / 1_000_000).toStringAsFixed(1)}jt';
      }
      if (amount >= 1_000) {
        return 'Rp ${(amount / 1_000).toStringAsFixed(0)}rb';
      }
    }
    final formatted = NumberFormat.currency(
      locale:        'id_ID',
      symbol:        'Rp ',
      decimalDigits: 0,
    ).format(amount);
    return formatted;
  }

  static double parseAmount(String raw) {
    final cleaned = raw
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    return double.tryParse(cleaned) ?? 0;
  }

  // ── Date ──────────────────────────────────
  static String formatDate(DateTime date, {String pattern = 'd MMMM yyyy'}) {
    return DateFormat(pattern, 'id_ID').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('d MMM', 'id_ID').format(date);
  }

  static String formatDateFull(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  static String formatMonth(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  static String toApiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static DateTime? parseApiDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
    return formatDateShort(date);
  }

  // ── Validation ────────────────────────────
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^(\+62|62|0)8[1-9][0-9]{6,10}$').hasMatch(phone);
  }

  // ── String ────────────────────────────────
  static String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String truncate(String s, int maxLength) {
    if (s.length <= maxLength) return s;
    return '${s.substring(0, maxLength)}...';
  }

  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // ── Category color hex → Color ────────────
  static int parseHexColor(String hex, {int fallback = 0xFF10B981}) {
    try {
      final clean = hex.replaceFirst('#', '');
      return int.parse('FF$clean', radix: 16);
    } catch (_) {
      return fallback;
    }
  }
}
