import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState
    extends ConsumerState<TransactionListScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(transactionListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari transaksi...',
                  border: InputBorder.none,
                  hintStyle:
                      TextStyle(color: AppColors.gray400, fontSize: 16),
                ),
                style: const TextStyle(
                    fontSize: 16, color: AppColors.gray800),
                onChanged: (v) => ref
                    .read(transactionListProvider.notifier)
                    .applyFilter(state.filter.copyWith(search: v)),
              )
            : const Text('Transaksi'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.gray700,
            ),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchCtrl.clear();
                ref
                    .read(transactionListProvider.notifier)
                    .applyFilter(state.filter.copyWith(search: ''));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.emerald500),
            onPressed: () => context.push('/transactions/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Category filter chips ──────────
          categoriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (cats) => _CategoryFilterBar(
              categories: cats,
              selectedId: state.filter.categoryId,
              onSelect: (id) => ref
                  .read(transactionListProvider.notifier)
                  .applyFilter(state.filter.copyWith(
                    categoryId: id,
                    clearCategory: id == null,
                  )),
            ),
          ),

          // ── Transaction list ───────────────
          Expanded(
            child: state.isLoading
                ? _buildSkeleton()
                : state.transactions.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Belum ada transaksi',
                        subtitle:
                            'Tambahkan transaksi atau scan struk belanja kamu',
                        actionLabel: '+ Tambah',
                        onAction: () =>
                            context.push('/transactions/add'),
                      )
                    : RefreshIndicator(
                        color: AppColors.emerald500,
                        onRefresh: () => ref
                            .read(transactionListProvider.notifier)
                            .fetch(),
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(
                              20, 8, 20, 100),
                          itemCount: state.transactions.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == state.transactions.length) {
                              return const Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.emerald500,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            final tx = state.transactions[i];
                            return _buildTxTile(ctx, tx, i);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        backgroundColor: AppColors.emerald500,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child:
            const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildTxTile(
      BuildContext context, TransactionModel tx, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key('tx_${tx.transactionId}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: AppColors.danger, size: 24),
        ),
        confirmDismiss: (_) => _confirmDelete(context),
        onDismissed: (_) {
          ref
              .read(transactionListProvider.notifier)
              .deleteTransaction(tx.transactionId);
          FinpalsSnackbar.show(context, 'Transaksi dihapus');
        },
        child: _TxCard(
          tx: tx,
          onTap: () => _showEditSheet(context, tx),
        ).animate().slideX(
              begin: 0.1,
              delay: (index * 40).ms,
              duration: 280.ms,
              curve: Curves.easeOut,
            ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: 6,
      itemBuilder: (_, i) => const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: ShimmerBox(height: 76, borderRadius: 18),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Transaksi?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Transaksi ini akan dihapus permanen.',
            style: TextStyle(color: AppColors.gray500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.gray500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(80, 40)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTransactionSheet(tx: tx),
    );
  }
}

// ─── Category Filter Bar ───────────────────
class _CategoryFilterBar extends StatelessWidget {
  final List<CategoryModel> categories;
  final int? selectedId;
  final void Function(int?) onSelect;

  const _CategoryFilterBar({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          // "Semua" chip
          _Chip(
            label: 'Semua',
            isSelected: selectedId == null,
            onTap: () => onSelect(null),
          ),
          ...categories.map(
            (c) => _Chip(
              label: c.name,
              isSelected: selectedId == c.categoryId,
              onTap: () => onSelect(
                selectedId == c.categoryId ? null : c.categoryId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.emerald500 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.emerald500
                : AppColors.gray200,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : AppColors.gray600,
            ),
          ),
        ),
      ),
    );
  }
}

IconData getCategoryIcon(String? iconName, String? categoryName) {
  if (iconName != null) {
    switch (iconName.toLowerCase()) {
      case 'restaurant': return Icons.restaurant_rounded;
      case 'shopping_bag': return Icons.shopping_bag_rounded;
      case 'directions_car': return Icons.directions_car_rounded;
      case 'celebration': return Icons.celebration_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'school': return Icons.school_rounded;
      case 'receipt_long': return Icons.receipt_long_rounded;
      case 'coffee': return Icons.coffee_rounded;
      case 'home': return Icons.home_rounded;
      case 'sports_esports': return Icons.sports_esports_rounded;
      case 'more_horiz': return Icons.more_horiz_rounded;
      case 'category': return Icons.category_rounded;
    }
  }
  switch (categoryName?.toLowerCase()) {
    case 'makanan':   return Icons.restaurant_rounded;
    case 'belanja':   return Icons.shopping_bag_rounded;
    case 'transport': return Icons.directions_car_rounded;
    case 'hiburan':   return Icons.celebration_rounded;
    case 'kesehatan': return Icons.favorite_rounded;
    case 'pendidikan': return Icons.school_rounded;
    case 'tagihan':   return Icons.receipt_long_rounded;
    default:          return Icons.receipt_outlined;
  }
}

// ─── Transaction Card ──────────────────────
class _TxCard extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onTap;

  const _TxCard({required this.tx, required this.onTap});

  Color get _color {
    if (tx.categoryColor != null) {
      try {
        return Color(
            int.parse(tx.categoryColor!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return AppColors.emerald500;
  }

  IconData get _icon => getCategoryIcon(tx.categoryIcon, tx.categoryName);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: _color, size: 22),
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
                    Row(children: [
                      if (tx.categoryName != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(tx.categoryName!,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _color,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        DateFormat('d MMM yyyy', 'id_ID').format(tx.date),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.gray400),
                      ),
                    ]),
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
                  if (tx.source == 'ocr')
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Row(children: [
                        Icon(Icons.document_scanner_outlined,
                            size: 10, color: AppColors.gray400),
                        SizedBox(width: 3),
                        Text('OCR',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.gray400)),
                      ]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Edit Transaction Bottom Sheet ─────────
class _EditTransactionSheet extends ConsumerStatefulWidget {
  final TransactionModel tx;
  const _EditTransactionSheet({required this.tx});

  @override
  ConsumerState<_EditTransactionSheet> createState() =>
      _EditTransactionSheetState();
}

class _EditTransactionSheetState
    extends ConsumerState<_EditTransactionSheet> {
  late TextEditingController _merchantCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _notesCtrl;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _merchantCtrl =
        TextEditingController(text: widget.tx.merchantName);
    _amountCtrl = TextEditingController(
        text: widget.tx.amount.toStringAsFixed(0));
    _dateCtrl = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(widget.tx.date));
    _notesCtrl =
        TextEditingController(text: widget.tx.notes ?? '');
    _categoryId = widget.tx.categoryId;
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final txState = ref.watch(transactionListProvider);

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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Transaksi',
                    style: AppTextStyles.headingMedium),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.danger),
                  onPressed: () async {
                    Navigator.pop(context);
                    final ok = await ref
                        .read(transactionListProvider.notifier)
                        .deleteTransaction(widget.tx.transactionId);
                    if (ok && context.mounted) {
                      ref.invalidate(dashboardProvider);
                      FinpalsSnackbar.show(
                          context, 'Transaksi dihapus');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            FinpalsTextField(
              controller: _merchantCtrl,
              label: 'Nama Merchant',
              hint: 'Nama toko',
            ),
            const SizedBox(height: 12),
            FinpalsTextField(
              controller: _amountCtrl,
              label: 'Total (Rp)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            FinpalsTextField(
              controller: _dateCtrl,
              label: 'Tanggal',
              readOnly: true,
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            FinpalsTextField(
              controller: _notesCtrl,
              label: 'Catatan',
              maxLines: 2,
            ),

            const SizedBox(height: 12),

            // Category selector
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
                children: cats.map((cat) {
                  final sel = cat.categoryId == _categoryId;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _categoryId = cat.categoryId),
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
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),
            FinpalsButton(
              label: 'Simpan Perubahan',
              isLoading: txState.isLoading,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.tx.date,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppColors.emerald500),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dateCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _handleSave() async {
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      FinpalsSnackbar.show(context, 'Total tidak valid',
          isError: true);
      return;
    }
    final ok = await ref
        .read(transactionListProvider.notifier)
        .updateTransaction(widget.tx.transactionId, {
      'merchant_name': _merchantCtrl.text.trim(),
      'amount': amount,
      'category_id': _categoryId,
      'date': _dateCtrl.text,
      'notes': _notesCtrl.text.trim(),
    });

    if (ok && mounted) {
      Navigator.pop(context);
      ref.invalidate(dashboardProvider);
      FinpalsSnackbar.show(context, 'Transaksi diperbarui',
          isSuccess: true);
    }
  }
}
