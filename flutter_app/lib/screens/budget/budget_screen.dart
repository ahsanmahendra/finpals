import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

// ─── Budget provider ───────────────────────
final budgetProvider = FutureProvider<List<BudgetModel>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.budgets);
  final list = response.data['data'] as List<dynamic>;
  return list
      .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetProvider);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: const Text('Budget'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.emerald500),
            onPressed: () => _showAddBudgetSheet(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: budgetAsync.when(
          loading: () => _buildSkeleton(),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.danger, size: 40),
                const SizedBox(height: 12),
                Text(e.toString(),
                    style: const TextStyle(color: AppColors.gray500)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(budgetProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
          data: (budgets) => RefreshIndicator(
            color: AppColors.emerald500,
            onRefresh: () async => ref.invalidate(budgetProvider),
            child: budgets.isEmpty
                ? EmptyState(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'Belum ada budget',
                    subtitle:
                        'Buat budget bulanan untuk mengontrol pengeluaranmu',
                    actionLabel: '+ Buat Budget',
                    onAction: () => _showAddBudgetSheet(context, ref),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      // Summary card
                      _BudgetSummaryCard(budgets: budgets)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.2),

                      const SizedBox(height: 20),

                      const Text('Per Kategori',
                          style: AppTextStyles.headingSmall),
                      const SizedBox(height: 12),

                      ...budgets.asMap().entries.map((e) =>
                          _BudgetCard(budget: e.value)
                              .animate()
                              .slideY(
                                begin: 0.2,
                                delay: (e.key * 60).ms,
                                duration: 350.ms,
                              )),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const ShimmerBox(height: 140, borderRadius: 24),
        const SizedBox(height: 20),
        ...List.generate(
            4,
            (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerBox(height: 100, borderRadius: 20),
                )),
      ],
    );
  }

  void _showAddBudgetSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBudgetSheet(onSaved: () {
        ref.invalidate(budgetProvider);
      }),
    );
  }
}

// ─── Budget Summary Card ───────────────────
class _BudgetSummaryCard extends StatelessWidget {
  final List<BudgetModel> budgets;
  const _BudgetSummaryCard({required this.budgets});

  @override
  Widget build(BuildContext context) {
    final totalBudget =
        budgets.fold(0.0, (sum, b) => sum + b.amount);
    final totalSpent =
        budgets.fold(0.0, (sum, b) => sum + b.spent);
    final percent =
        totalBudget > 0 ? totalSpent / totalBudget : 0.0;
    final isOver = percent > 1.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOver
              ? [AppColors.danger, const Color(0xFFB91C1C)]
              : [AppColors.emerald500, AppColors.emerald700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isOver ? AppColors.danger : AppColors.emerald500)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Budget Bulan Ini',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13)),
              if (isOver)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
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
          CurrencyText(
            amount: totalBudget,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          Row(children: [
            Text('Terpakai: ',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 13)),
            CurrencyText(
              amount: totalSpent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              compact: true,
            ),
            Text(
              ' (${(percent * 100).clamp(0, 999).toStringAsFixed(0)}%)',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8), fontSize: 13),
            ),
          ]),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          CurrencyText(
            amount: (totalBudget - totalSpent).abs(),
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
            compact: true,
          ),
        ],
      ),
    );
  }
}

// ─── Per-category Budget Card ──────────────
class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final isOver = budget.isOverBudget;
    final pct = (budget.usagePercent * 100).toStringAsFixed(0);

    Color progressColor;
    if (budget.usagePercent < 0.7) {
      progressColor = AppColors.emerald500;
    } else if (budget.usagePercent < 1.0) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.danger;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOver
                        ? Icons.warning_amber_rounded
                        : Icons.pie_chart_rounded,
                    color: progressColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.categoryName ?? 'Total',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.gray800),
                    ),
                    Text(
                      budget.period == 'monthly'
                          ? 'Bulanan'
                          : 'Mingguan',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.gray400),
                    ),
                  ],
                ),
              ]),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$pct%',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: progressColor),
                  ),
                  Text(
                    isOver ? 'Over Budget!' : 'Sisa budget',
                    style: TextStyle(
                        fontSize: 10,
                        color: isOver
                            ? AppColors.danger
                            : AppColors.gray400),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: budget.usagePercent.clamp(0.0, 1.0),
              backgroundColor: AppColors.gray100,
              valueColor: AlwaysStoppedAnimation(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Text('Terpakai: ',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.gray400)),
                CurrencyText(
                    amount: budget.spent,
                    fontSize: 12,
                    compact: true),
              ]),
              Row(children: [
                const Text('Budget: ',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.gray400)),
                CurrencyText(
                    amount: budget.amount,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    compact: true),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Add Budget Sheet ──────────────────────
class _AddBudgetSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _AddBudgetSheet({required this.onSaved});

  @override
  ConsumerState<_AddBudgetSheet> createState() =>
      _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<_AddBudgetSheet> {
  final _amountCtrl = TextEditingController();
  int? _categoryId;
  String _period = 'monthly';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Tambah Budget',
                style: AppTextStyles.headingMedium),
            const SizedBox(height: 20),

            // Amount
            const Text('Jumlah Budget',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: '500.000',
              ),
            ),

            const SizedBox(height: 16),

            // Period
            const Text('Periode',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700)),
            const SizedBox(height: 8),
            Row(children: [
              _PeriodChip(
                label: 'Bulanan',
                selected: _period == 'monthly',
                onTap: () => setState(() => _period = 'monthly'),
              ),
              const SizedBox(width: 10),
              _PeriodChip(
                label: 'Mingguan',
                selected: _period == 'weekly',
                onTap: () => setState(() => _period = 'weekly'),
              ),
            ]),

            const SizedBox(height: 16),

            // Category
            const Text('Kategori',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700)),
            const SizedBox(height: 8),
            categoriesAsync.when(
              loading: () =>
                  const ShimmerBox(height: 44, borderRadius: 12),
              error: (_, __) =>
                  const Text('Gagal memuat kategori'),
              data: (cats) => Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _categoryId = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _categoryId == null
                            ? AppColors.emerald500
                            : AppColors.gray100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Semua',
                          style: TextStyle(
                              color: _categoryId == null
                                  ? Colors.white
                                  : AppColors.gray600,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ),
                  ...cats.map((cat) {
                    final sel = cat.categoryId == _categoryId;
                    return GestureDetector(
                      onTap: () => setState(
                          () => _categoryId = cat.categoryId),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.emerald500
                              : AppColors.gray100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(cat.name,
                            style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : AppColors.gray600,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),
            FinpalsButton(
              label: 'Simpan Budget',
              isLoading: _isLoading,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      FinpalsSnackbar.show(context, 'Masukkan jumlah budget yang valid',
          isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final dio = ref.read(dioProvider);
      await dio.post(ApiConstants.budgets, data: {
        'amount': amount,
        'period': _period,
        'category_id': _categoryId,
        'month': now.month,
        'year': now.year,
      });
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        FinpalsSnackbar.show(context, 'Budget berhasil dibuat!',
            isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        FinpalsSnackbar.show(context, 'Gagal membuat budget',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.emerald500 : AppColors.gray100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.gray600,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
