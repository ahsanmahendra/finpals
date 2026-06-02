import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class InsightScreen extends ConsumerWidget {
  const InsightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(aiInsightsProvider);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: const Text('AI Insight'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.emerald500),
            onPressed: () => ref.invalidate(aiInsightsProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: insightsAsync.when(
          loading: () => _buildSkeleton(),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.danger, size: 40),
                const SizedBox(height: 12),
                Text(e.toString(),
                    style: const TextStyle(color: AppColors.gray500),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(aiInsightsProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
          data: (insights) => insights.isEmpty
              ? _buildEmpty(context, ref)
              : RefreshIndicator(
                  color: AppColors.emerald500,
                  onRefresh: () async =>
                      ref.invalidate(aiInsightsProvider),
                  child: ListView(
                    padding:
                        const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      // Header banner
                      _AiBanner().animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 20),

                      // Group by type
                      ..._buildGrouped(insights),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  List<Widget> _buildGrouped(List<AiInsight> insights) {
    final groups = <String, List<AiInsight>>{};
    for (final i in insights) {
      groups.putIfAbsent(i.type, () => []).add(i);
    }

    final order = ['warning', 'tip', 'prediction', 'summary'];
    final widgets = <Widget>[];

    for (final type in order) {
      if (groups.containsKey(type)) {
        widgets.add(_GroupHeader(type: type));
        widgets.add(const SizedBox(height: 10));
        final items = groups[type]!;
        for (var idx = 0; idx < items.length; idx++) {
          widgets.add(
            _InsightCard(insight: items[idx])
                .animate()
                .slideY(
                  begin: 0.2,
                  delay: (idx * 60).ms,
                  duration: 350.ms,
                ),
          );
          widgets.add(const SizedBox(height: 10));
        }
        widgets.add(const SizedBox(height: 8));
      }
    }
    return widgets;
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const ShimmerBox(height: 120, borderRadius: 20),
        const SizedBox(height: 20),
        ...List.generate(
            4,
            (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerBox(height: 100, borderRadius: 16),
                )),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.emerald400, size: 44),
            ).animate().scale(duration: 400.ms),
            const SizedBox(height: 20),
            const Text('Belum Ada Insight',
                style: AppTextStyles.headingMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Text(
              'Tambahkan lebih banyak transaksi agar AI bisa menganalisis pola pengeluaranmu.',
              style: TextStyle(
                  color: AppColors.gray400, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              child: FinpalsButton(
                label: 'Generate Insight',
                height: 48,
                onPressed: () => ref.invalidate(aiInsightsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Finpals AI',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Analisis Keuangan Cerdas',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI menganalisis pola belanja & memberikan rekomendasi personal.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String type;
  const _GroupHeader({required this.type});

  String get _label {
    switch (type) {
      case 'warning':    return '⚠️  Peringatan';
      case 'tip':        return '💡  Tips Keuangan';
      case 'prediction': return '📈  Prediksi';
      case 'summary':    return '📊  Ringkasan';
      default:           return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_label, style: AppTextStyles.headingSmall);
  }
}

class _InsightCard extends StatelessWidget {
  final AiInsight insight;
  const _InsightCard({required this.insight});

  Color get _bgColor {
    switch (insight.type) {
      case 'warning':    return AppColors.warning.withOpacity(0.06);
      case 'tip':        return AppColors.emerald50;
      case 'prediction': return AppColors.info.withOpacity(0.06);
      case 'summary':    return AppColors.purple400.withOpacity(0.06);
      default:           return AppColors.gray50;
    }
  }

  Color get _accentColor {
    switch (insight.type) {
      case 'warning':    return AppColors.warning;
      case 'tip':        return AppColors.emerald500;
      case 'prediction': return AppColors.info;
      case 'summary':    return AppColors.purple400;
      default:           return AppColors.gray500;
    }
  }

  IconData get _icon {
    switch (insight.type) {
      case 'warning':    return Icons.warning_amber_rounded;
      case 'tip':        return Icons.lightbulb_outline_rounded;
      case 'prediction': return Icons.trending_up_rounded;
      case 'summary':    return Icons.summarize_rounded;
      default:           return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: _accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(insight.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.gray800)),
              ),
              if (!insight.isRead)
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight.content,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray600,
                height: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            DateFormat('d MMM yyyy, HH:mm', 'id_ID')
                .format(insight.generatedAt),
            style: const TextStyle(
                fontSize: 11, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }
}
