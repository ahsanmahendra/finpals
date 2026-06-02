import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? prefill;
  const AddTransactionScreen({super.key, this.prefill});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int? _categoryId;
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    // Pre-fill date to today
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Pre-fill from OCR/extra if provided
    if (widget.prefill != null) {
      final p = widget.prefill!;
      _merchantCtrl.text = p['merchant'] as String? ?? '';
      _amountCtrl.text =
          (p['amount'] as num?)?.toStringAsFixed(0) ?? '';
      _dateCtrl.text = p['date'] as String? ?? _dateCtrl.text;
      _categoryId = p['category_id'] as int?;
      _categoryName = p['category_name'] as String?;
    }
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
    final txState = ref.watch(transactionListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: const Text('Tambah Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              // Amount — big input at top
              _AmountInput(controller: _amountCtrl)
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: 20),

              // Merchant
              _FormCard(
                children: [
                  FinpalsTextField(
                    controller: _merchantCtrl,
                    label: 'Nama Merchant / Toko',
                    hint: 'Contoh: Indomaret, Grab Food',
                    prefixIcon: const Icon(Icons.store_outlined,
                        color: AppColors.gray400, size: 20),
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama merchant wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  FinpalsTextField(
                    controller: _dateCtrl,
                    label: 'Tanggal',
                    readOnly: true,
                    prefixIcon: const Icon(Icons.calendar_today_outlined,
                        color: AppColors.gray400, size: 20),
                    onTap: _pickDate,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Tanggal wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  FinpalsTextField(
                    controller: _notesCtrl,
                    label: 'Catatan (Opsional)',
                    hint: 'Tambahkan catatan...',
                    maxLines: 2,
                    prefixIcon: const Icon(Icons.notes_rounded,
                        color: AppColors.gray400, size: 20),
                  ),
                ],
              ).animate().slideY(begin: 0.2, delay: 80.ms, duration: 350.ms),

              const SizedBox(height: 16),

              // Category
              _FormCard(
                title: 'Kategori',
                children: [
                  categoriesAsync.when(
                    loading: () => const ShimmerBox(height: 100),
                    error: (_, __) =>
                        const Text('Gagal memuat kategori'),
                    data: (cats) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cats.map((cat) {
                        final isSelected =
                            cat.categoryId == _categoryId;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _categoryId = cat.categoryId;
                            _categoryName = cat.name;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.emerald500
                                  : AppColors.gray100,
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: AppColors.gray200),
                            ),
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.gray600,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ).animate().slideY(begin: 0.2, delay: 150.ms, duration: 350.ms),

              const SizedBox(height: 28),

              FinpalsButton(
                label: 'Simpan Transaksi',
                isLoading: txState.isLoading,
                icon: Icons.check_rounded,
                onPressed: _handleSave,
              ).animate().slideY(begin: 0.2, delay: 200.ms, duration: 350.ms),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
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
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final raw = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '');
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      FinpalsSnackbar.show(context, 'Masukkan jumlah yang valid',
          isError: true);
      return;
    }
    FocusScope.of(context).unfocus();

    final ok = await ref
        .read(transactionListProvider.notifier)
        .addTransaction({
      'merchant_name': _merchantCtrl.text.trim(),
      'amount': amount,
      'category_id': _categoryId,
      'date': _dateCtrl.text,
      'notes': _notesCtrl.text.trim(),
      'source': 'manual',
    });

    if (ok && mounted) {
      ref.invalidate(dashboardProvider);
      FinpalsSnackbar.show(context, 'Transaksi berhasil ditambahkan!',
          isSuccess: true);
      context.pop();
    } else if (mounted) {
      FinpalsSnackbar.show(
          context,
          ref.read(transactionListProvider).error ??
              'Gagal menyimpan transaksi',
          isError: true);
    }
  }
}

// ─── Big Amount Input ──────────────────────
class _AmountInput extends StatefulWidget {
  final TextEditingController controller;
  const _AmountInput({required this.controller});

  @override
  State<_AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<_AmountInput> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.emerald500, AppColors.emerald700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald600.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jumlah Pengeluaran',
            style: TextStyle(
                color: Colors.white.withOpacity(0.85), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Rp',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandsSeparatorFormatter(),
                  ],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                    final raw =
                        v.replaceAll('.', '').replaceAll(',', '');
                    final n = double.tryParse(raw);
                    if (n == null || n <= 0) return 'Masukkan jumlah yang valid';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Thousands Separator ──────────────────
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    final buffer = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
      count++;
    }
    final formatted = buffer.toString().split('').reversed.join('');
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ─── Form Section Card ─────────────────────
class _FormCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _FormCard({this.title, required this.children});

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
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.gray800)),
            const SizedBox(height: 14),
          ],
          ...children,
        ],
      ),
    );
  }
}
