import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

// ════════════════════════════════════════
// SCAN SCREEN — mirrors React ScanView
// ════════════════════════════════════════
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrState = ref.watch(ocrProvider);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: const Text('Scan Struk'),
        automaticallyImplyLeading: false,
      ),
      body: LoadingOverlay(
        isLoading: ocrState.isScanning,
        message: 'Memproses struk...',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                // Illustration / Camera preview area
                _ScanIllustration()
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: 32),

                const Text(
                  'Pilih cara scan struk',
                  style: AppTextStyles.headingSmall,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 8),

                const Text(
                  'AI akan otomatis membaca merchant, tanggal, dan total belanja kamu',
                  style: TextStyle(
                    color: AppColors.gray400,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 36),

                // Camera button
                _ScanOptionCard(
                  icon: Icons.camera_alt_rounded,
                  title: 'Ambil Foto',
                  subtitle: 'Gunakan kamera untuk foto struk langsung',
                  color: AppColors.emerald500,
                  onTap: () => _pickImage(context, ref, ImageSource.camera),
                ).animate().slideY(begin: 0.3, delay: 350.ms, duration: 400.ms),

                const SizedBox(height: 12),

                // Gallery button
                _ScanOptionCard(
                  icon: Icons.photo_library_outlined,
                  title: 'Pilih dari Galeri',
                  subtitle: 'Upload foto struk dari galeri ponselmu',
                  color: AppColors.teal500,
                  onTap: () => _pickImage(context, ref, ImageSource.gallery),
                ).animate().slideY(begin: 0.3, delay: 450.ms, duration: 400.ms),

                if (ocrState.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.danger, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ocrState.error!,
                            style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(
      BuildContext context, WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final ok = await ref.read(ocrProvider.notifier).scanReceipt(file);

    if (ok && context.mounted) {
      final result = ref.read(ocrProvider).result!;
      context.push('/ocr-review', extra: {
        'merchant': result.merchant,
        'total': result.total,
        'date': result.date,
        'items': result.items.map((i) => {
          'name': i.name,
          'price': i.price,
          'qty': i.qty,
        }).toList(),
        'confidence': result.confidence,
        'imageUrl': result.imageUrl,
        'suggestedCategory': result.suggestedCategory,
        'suggestedCategoryId': result.suggestedCategoryId,
      });
    }
  }
}

class _ScanIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.emerald200,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Corner markers
          ..._corners(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.document_scanner_outlined,
                  color: AppColors.emerald400, size: 64),
              const SizedBox(height: 12),
              const Text(
                'Arahkan kamera ke struk',
                style: TextStyle(
                    color: AppColors.emerald600,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    return [
      Positioned(
        top: 16, left: 16,
        child: _CornerMark(topLeft: true),
      ),
      Positioned(
        top: 16, right: 16,
        child: _CornerMark(topRight: true),
      ),
      Positioned(
        bottom: 16, left: 16,
        child: _CornerMark(bottomLeft: true),
      ),
      Positioned(
        bottom: 16, right: 16,
        child: _CornerMark(bottomRight: true),
      ),
    ];
  }
}

class _CornerMark extends StatelessWidget {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _CornerMark({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _CornerPainter(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool topLeft, topRight, bottomLeft, bottomRight;
  _CornerPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.emerald500
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 20.0;
    final w = size.width;
    final h = size.height;

    if (topLeft) {
      canvas.drawLine(Offset.zero, Offset(len, 0), paint);
      canvas.drawLine(Offset.zero, Offset(0, len), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(w, 0), Offset(w - len, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset(0, h), Offset(len, h), paint);
      canvas.drawLine(Offset(0, h), Offset(0, h - len), paint);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(w, h), Offset(w - len, h), paint);
      canvas.drawLine(Offset(w, h), Offset(w, h - len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ScanOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.gray800)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray400,
                            height: 1.4)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.gray300, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════
// OCR REVIEW SCREEN — mirrors React EditTransactionView
// ════════════════════════════════════════
class OcrReviewScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> ocrData;
  const OcrReviewScreen({super.key, required this.ocrData});

  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  late TextEditingController _merchantCtrl;
  late TextEditingController _totalCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _notesCtrl;
  int? _selectedCategoryId;
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    final d = widget.ocrData;
    _merchantCtrl = TextEditingController(text: d['merchant'] as String? ?? '');
    _totalCtrl = TextEditingController(
        text: (d['total'] as num?)?.toStringAsFixed(0) ?? '');
    _dateCtrl = TextEditingController(text: d['date'] as String? ?? '');
    _notesCtrl = TextEditingController();
    _selectedCategoryId = d['suggestedCategoryId'] as int?;
    _selectedCategoryName = d['suggestedCategory'] as String?;
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _totalCtrl.dispose();
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
        title: const Text('Review Struk'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(ocrProvider.notifier).clearResult();
            context.pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: txState.isLoading ? null : _handleSave,
              child: const Text(
                'Simpan',
                style: TextStyle(
                    color: AppColors.emerald600,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Confidence badge
              _ConfidenceBadge(
                confidence: widget.ocrData['confidence'] as double? ?? 0),

              const SizedBox(height: 20),

              // OCR fields
              _buildSection(
                title: 'Detail Transaksi',
                child: Column(
                  children: [
                    FinpalsTextField(
                      controller: _merchantCtrl,
                      label: 'Nama Merchant',
                      hint: 'Nama toko / restoran',
                      prefixIcon: const Icon(Icons.store_outlined,
                          color: AppColors.gray400),
                    ),
                    const SizedBox(height: 14),
                    FinpalsTextField(
                      controller: _totalCtrl,
                      label: 'Total',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text('Rp',
                            style: TextStyle(
                                color: AppColors.gray500,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FinpalsTextField(
                      controller: _dateCtrl,
                      label: 'Tanggal',
                      hint: 'YYYY-MM-DD',
                      readOnly: true,
                      prefixIcon: const Icon(Icons.calendar_today_outlined,
                          color: AppColors.gray400),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 14),
                    FinpalsTextField(
                      controller: _notesCtrl,
                      label: 'Catatan (Opsional)',
                      hint: 'Tambahkan catatan...',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Category picker
              _buildSection(
                title: 'Kategori',
                child: categoriesAsync.when(
                  loading: () =>
                      const ShimmerBox(height: 44, borderRadius: 12),
                  error: (_, __) =>
                      const Text('Gagal memuat kategori'),
                  data: (cats) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cats.map((cat) {
                      final isSelected =
                          cat.categoryId == _selectedCategoryId;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedCategoryId = cat.categoryId;
                          _selectedCategoryName = cat.name;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.emerald500
                                : AppColors.gray100,
                            borderRadius: BorderRadius.circular(20),
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
              ),

              // Items list (if any)
              if ((widget.ocrData['items'] as List?)?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Item Terdeteksi',
                  child: Column(
                    children: (widget.ocrData['items'] as List)
                        .map((item) {
                      final m = item as Map;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(m['name'] as String,
                                  style: const TextStyle(
                                      color: AppColors.gray700,
                                      fontSize: 13)),
                            ),
                            CurrencyText(
                              amount: (m['price'] as num).toDouble(),
                              fontSize: 13,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              FinpalsButton(
                label: 'Simpan Transaksi',
                isLoading: txState.isLoading,
                icon: Icons.save_rounded,
                onPressed: _handleSave,
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.gray800)),
          const SizedBox(height: 14),
          child,
        ],
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
            primary: AppColors.emerald500,
          ),
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
    if (_merchantCtrl.text.trim().isEmpty) {
      FinpalsSnackbar.show(context, 'Nama merchant wajib diisi', isError: true);
      return;
    }
    final amount = double.tryParse(_totalCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      FinpalsSnackbar.show(context, 'Masukkan total yang valid', isError: true);
      return;
    }

    final ok = await ref.read(transactionListProvider.notifier).addTransaction({
      'merchant_name': _merchantCtrl.text.trim(),
      'amount': amount,
      'category_id': _selectedCategoryId,
      'date': _dateCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'source': 'ocr',
      'image_url': widget.ocrData['imageUrl'],
    });

    if (ok && mounted) {
      ref.read(ocrProvider.notifier).clearResult();
      ref.invalidate(dashboardProvider);
      FinpalsSnackbar.show(context, 'Transaksi berhasil disimpan!',
          isSuccess: true);
      context.go('/dashboard');
    }
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;
  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence).toInt();
    Color color;
    String label;
    if (pct >= 80) {
      color = AppColors.success;
      label = 'Akurasi Tinggi';
    } else if (pct >= 50) {
      color = AppColors.warning;
      label = 'Akurasi Sedang — Cek kembali';
    } else {
      color = AppColors.danger;
      label = 'Akurasi Rendah — Periksa data';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Text('$label ($pct%)',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
