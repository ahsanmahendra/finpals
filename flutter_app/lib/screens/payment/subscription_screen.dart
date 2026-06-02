import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

// ════════════════════════════════════════
// SUBSCRIPTION SCREEN
// ════════════════════════════════════════
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final paymentState = ref.watch(paymentProvider);
    final isPremium = authState.user?.isPremium ?? false;

    ref.listen(paymentProvider, (prev, next) {
      // When snapToken is ready, navigate to webview
      if (next.snapToken != null && next.snapToken != prev?.snapToken) {
        context.push('/payment-webview', extra: {
          'snapToken': next.snapToken!,
          'orderId': next.orderId ?? '',
        });
      }
      if (next.error != null && next.error != prev?.error) {
        FinpalsSnackbar.show(context, next.error!, isError: true);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: const Text('Finpals Premium'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero banner
              _PremiumHero(isPremium: isPremium)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: 28),

              if (isPremium) ...[
                _ActivePremiumCard(
                  sub: paymentState.subscription,
                ).animate().fadeIn(delay: 100.ms),
              ] else ...[
                // Features list
                const Text('Yang kamu dapat:',
                    style: AppTextStyles.headingSmall),
                const SizedBox(height: 14),
                ..._features.asMap().entries.map((e) =>
                    _FeatureRow(feature: e.value)
                        .animate()
                        .slideX(
                          begin: 0.2,
                          delay: (e.key * 60).ms,
                          duration: 350.ms,
                        )),

                const SizedBox(height: 28),

                // Price card
                _PriceCard().animate().slideY(begin: 0.2, delay: 300.ms),

                const SizedBox(height: 24),

                FinpalsButton(
                  label: paymentState.isLoading
                      ? 'Memproses...'
                      : 'Mulai Premium — Rp 29.000/bln',
                  isLoading: paymentState.isLoading,
                  onPressed: () =>
                      ref.read(paymentProvider.notifier).createPayment(),
                ).animate().slideY(begin: 0.2, delay: 380.ms),

                const SizedBox(height: 12),
                const Text(
                  '* Sandbox/Testing — tidak ada transaksi nyata',
                  style: TextStyle(
                      color: AppColors.gray400,
                      fontSize: 11),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // Payment history
                if (paymentState.history.isNotEmpty) ...[
                  const Text('Riwayat Pembayaran',
                      style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),
                  ...paymentState.history.map(
                      (p) => _PaymentHistoryTile(payment: p)),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  static const _features = [
    _Feature(Icons.document_scanner_rounded,
        'Scan Struk Unlimited', 'Scan berapa pun tanpa batas'),
    _Feature(Icons.auto_awesome_rounded,
        'AI Insight Personal', 'Analisis pola belanja mendalam'),
    _Feature(Icons.trending_up_rounded,
        'Prediksi Pengeluaran', 'Prediksi bulan depan berbasis AI'),
    _Feature(Icons.pie_chart_rounded,
        'Budget Smart', 'Rekomendasi budget otomatis dari AI'),
    _Feature(Icons.notifications_active_rounded,
        'Notifikasi WA & Email', 'Alert overspending real-time'),
    _Feature(Icons.cloud_done_rounded,
        'Export Laporan', 'Download laporan keuangan PDF/Excel'),
  ];
}

class _Feature {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Feature(this.icon, this.title, this.subtitle);
}

// ─── Premium Hero ──────────────────────────
class _PremiumHero extends StatelessWidget {
  final bool isPremium;
  const _PremiumHero({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPremium ? Icons.workspace_premium_rounded
                        : Icons.star_rounded,
              color: Colors.amber,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPremium ? 'Kamu Sudah Premium! 🎉' : 'Finpals Premium',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            isPremium
                ? 'Nikmati semua fitur premium Finpals'
                : 'Kelola keuangan lebih cerdas dengan AI',
            style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Feature Row ───────────────────────────
class _FeatureRow extends StatelessWidget {
  final _Feature feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(feature.icon,
                color: AppColors.emerald500, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.gray800)),
                Text(feature.subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.gray400)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: AppColors.emerald500, size: 20),
        ],
      ),
    );
  }
}

// ─── Price Card ────────────────────────────
class _PriceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.emerald200, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald100.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Premium Plan',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.gray800)),
              const SizedBox(height: 4),
              Row(children: [
                const Text('Rp ',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.gray500)),
                const Text('29.000',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emerald600)),
                const Text('/bulan',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.gray500)),
              ]),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Hemat 40%',
                style: TextStyle(
                    color: AppColors.emerald700,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Active Premium Card ───────────────────
class _ActivePremiumCard extends StatelessWidget {
  final dynamic sub;
  const _ActivePremiumCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: Colors.amber, size: 26),
              SizedBox(width: 10),
              Text('Premium Aktif',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.gray800)),
            ],
          ),
          const SizedBox(height: 16),
          if (sub?.expiresAt != null)
            Text(
              'Berlaku hingga: ${sub!.expiresAt.toString().split(' ').first}',
              style: const TextStyle(color: AppColors.gray500),
            ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatusItem(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'AI Insight',
                  active: true),
              _StatusItem(
                  icon: Icons.document_scanner_outlined,
                  label: 'OCR Unlimited',
                  active: true),
              _StatusItem(
                  icon: Icons.notifications_active_outlined,
                  label: 'Notifikasi',
                  active: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _StatusItem(
      {required this.icon,
      required this.label,
      required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon,
            color: active ? AppColors.emerald500 : AppColors.gray300,
            size: 24),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: active ? AppColors.gray700 : AppColors.gray400,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Payment History Tile ──────────────────
class _PaymentHistoryTile extends StatelessWidget {
  final dynamic payment;
  const _PaymentHistoryTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final status = payment.status as String;
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'success':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.pending_rounded;
        break;
      default:
        statusColor = AppColors.danger;
        statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Premium Plan',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(payment.orderId as String,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.gray400)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CurrencyText(amount: payment.amount as double, fontSize: 13),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == 'success'
                      ? 'Berhasil'
                      : status == 'pending'
                          ? 'Pending'
                          : 'Gagal',
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
