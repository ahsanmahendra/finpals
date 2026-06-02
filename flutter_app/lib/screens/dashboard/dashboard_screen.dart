import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: dashAsync.when(
          loading: () => _buildSkeleton(),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.danger, size: 48),
                const SizedBox(height: 12),
                Text(e.toString(),
                    style: const TextStyle(color: AppColors.gray500)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(dashboardProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
          data: (state) => RefreshIndicator(
            color: AppColors.emerald500,
            onRefresh: () async =>
                ref.read(dashboardProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────
                SliverToBoxAdapter(
                  child: _Header(userName: authState.user?.name ?? ''),
                ),

                // ── Balance Card ───────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _BalanceCard(state: state),
                  ).animate().slideY(
                        begin: 0.2,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ),

                // ── Quick Actions ──────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _QuickActions(),
                  ),
                ),

                // ── Category Chart ─────────────
                if (state.categoryBreakdown.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child:
                          _CategoryChart(categories: state.categoryBreakdown),
                    ).animate().slideY(
                          begin: 0.2,
                          delay: 100.ms,
                          duration: 450.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ),

                // ── AI Insight card ────────────
                if (state.latestInsight != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _InsightCard(insight: state.latestInsight!),
                    ).animate().slideX(
                          begin: 0.3,
                          delay: 200.ms,
                          duration: 400.ms,
                        ),
                  ),

                // ── Recent Transactions header ─
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transaksi Terbaru',
                            style: AppTextStyles.headingSmall),
                        TextButton(
                          onPressed: () => context.go('/transactions'),
                          child: const Text('Lihat semua',
                              style: TextStyle(
                                  color: AppColors.emerald600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Transaction list ───────────
                state.recentTransactions.isEmpty
                    ? SliverToBoxAdapter(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: _emptyTransactions(context),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final tx = state.recentTransactions[i];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                              child: _TransactionTile(tx: tx).animate().slideX(
                                    begin: 0.15,
                                    delay: (i * 60).ms,
                                    duration: 300.ms,
                                  ),
                            );
                          },
                          childCount: state.recentTransactions.length,
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        backgroundColor: AppColors.emerald500,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const ShimmerBox(height: 28, width: 200),
          const SizedBox(height: 20),
          const ShimmerBox(height: 180, borderRadius: 24),
          const SizedBox(height: 20),
          const ShimmerBox(height: 220, borderRadius: 24),
          const SizedBox(height: 20),
          ...List.generate(
              3,
              (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: ShimmerBox(height: 72, borderRadius: 16),
                  )),
        ],
      ),
    );
  }

  Widget _emptyTransactions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Belum ada transaksi',
        subtitle: 'Tambahkan transaksi pertama kamu atau scan struk belanja',
        actionLabel: '+ Tambah Transaksi',
        onAction: () => context.push('/transactions/add'),
      ),
    );
  }
}

// ─── Header ────────────────────────────────
class _Header extends StatelessWidget {
  final String userName;
  const _Header({required this.userName});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = userName.split(' ').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting, $firstName! 👋',
                style: AppTextStyles.headingLarge,
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          GestureDetector(
            onTap: () => context.push('/insights'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.emerald500, size: 22),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

// ─── Balance Card ──────────────────────────
class _BalanceCard extends StatelessWidget {
  final DashboardState state;
  const _BalanceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final percent = (state.budgetPercent * 100).toInt();
    final isOver = state.budgetPercent >= 1.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.emerald500, AppColors.emerald700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald600.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengeluaran ${DateFormat('MMMM', 'id_ID').format(DateTime.now())}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 13),
              ),
              if (isOver)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.danger.withOpacity(0.5)),
                  ),
                  child: const Text('Over Budget!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Total amount
          CurrencyText(
            amount: state.totalMonthly,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),

          const SizedBox(height: 20),

          // Budget progress
          if (state.budgetStatus != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget terpakai $percent%',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12)),
                CurrencyText(
                  amount: state.budgetStatus!.totalBudget,
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.budgetPercent.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOver ? AppColors.danger : Colors.white,
                ),
                minHeight: 8,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Weekly summary
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                'Minggu ini: ',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 13),
              ),
              CurrencyText(
                amount: state.totalWeekly,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ─────────────────────────
class _QuickActions extends StatelessWidget {
  final _actions = const [
    _Action(Icons.add_circle_outline_rounded, 'Tambah', '/transactions/add'),
    _Action(Icons.document_scanner_outlined, 'Scan Struk', '/scan'),
    _Action(Icons.pie_chart_outline_rounded, 'Budget', '/budget'),
    _Action(Icons.auto_awesome_outlined, 'Insight AI', '/insights'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          _actions.map((a) => Expanded(child: _ActionBtn(action: a))).toList(),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final String route;
  const _Action(this.icon, this.label, this.route);
}

class _ActionBtn extends StatelessWidget {
  final _Action action;
  const _ActionBtn({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(action.route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(action.icon, color: AppColors.emerald500, size: 22),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Donut Chart ──────────────────
class _CategoryChart extends StatefulWidget {
  final List<CategorySummary> categories;
  const _CategoryChart({required this.categories});

  @override
  State<_CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<_CategoryChart> {
  int _touchedIndex = -1;

  static const _colors = AppColors.categoryColors;

  Color _colorFor(int i) => _colors[i % _colors.length];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pengeluaran per Kategori',
              style: AppTextStyles.headingSmall),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut
              SizedBox(
                width: 130,
                height: 130,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 38,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex =
                              response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: List.generate(
                      widget.categories.length,
                      (i) {
                        final cat = widget.categories[i];
                        final isTouched = i == _touchedIndex;
                        return PieChartSectionData(
                          value: cat.amount,
                          color: _colorFor(i),
                          radius: isTouched ? 38 : 30,
                          showTitle: isTouched,
                          title: isTouched
                              ? '${cat.percent.toStringAsFixed(0)}%'
                              : '',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Legend
              Expanded(
                child: Column(
                  children: List.generate(
                    widget.categories.length,
                    (i) {
                      final cat = widget.categories[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _colorFor(i),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(cat.name,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.gray600),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            CurrencyText(
                              amount: cat.amount,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              compact: true,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── AI Insight Card ───────────────────────
class _InsightCard extends StatelessWidget {
  final AiInsight insight;
  const _InsightCard({required this.insight});

  Color get _bgColor {
    switch (insight.type) {
      case 'warning':
        return AppColors.warning.withOpacity(0.1);
      case 'tip':
        return AppColors.emerald50;
      case 'prediction':
        return AppColors.info.withOpacity(0.08);
      default:
        return AppColors.emerald50;
    }
  }

  Color get _iconColor {
    switch (insight.type) {
      case 'warning':
        return AppColors.warning;
      case 'tip':
        return AppColors.emerald500;
      case 'prediction':
        return AppColors.info;
      default:
        return AppColors.emerald500;
    }
  }

  IconData get _icon {
    switch (insight.type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'tip':
        return Icons.lightbulb_outline_rounded;
      case 'prediction':
        return Icons.trending_up_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _iconColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.gray800)),
                const SizedBox(height: 3),
                Text(insight.content,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.gray500, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.gray300, size: 20),
        ],
      ),
    );
  }
}

// ─── Transaction Tile ──────────────────────
class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionTile({required this.tx});

  Color get _catColor {
    if (tx.categoryColor != null) {
      try {
        return Color(int.parse(tx.categoryColor!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return AppColors.emerald500;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _catColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.receipt_outlined, color: _catColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.merchantName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.gray800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  tx.categoryName ??
                      DateFormat('d MMM', 'id_ID').format(tx.date),
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.gray400),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CurrencyText(
                amount: tx.amount,
                fontSize: 14,
                color: AppColors.danger,
              ),
              const SizedBox(height: 3),
              Text(
                DateFormat('d MMM', 'id_ID').format(tx.date),
                style: const TextStyle(fontSize: 11, color: AppColors.gray400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
