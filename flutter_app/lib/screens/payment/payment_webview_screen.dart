import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class PaymentWebviewScreen extends ConsumerStatefulWidget {
  final String snapToken;
  final String orderId;
  const PaymentWebviewScreen({super.key, required this.snapToken, required this.orderId});
  @override
  ConsumerState<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends ConsumerState<PaymentWebviewScreen> {
  late final WebViewController _ctrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: _handleNav,
      ))
      ..loadRequest(Uri.parse(
          'https://app.sandbox.midtrans.com/snap/v3/redirection/${widget.snapToken}'));
  }

  NavigationDecision _handleNav(NavigationRequest req) {
    final url = req.url;
    if (url.contains('settlement') || url.contains('capture') || url.contains('payment/finish')) {
      _showResult(true, 'Pembayaran Berhasil!',
          'Selamat! Kamu sekarang menjadi member Premium.');
      return NavigationDecision.prevent;
    }
    if (url.contains('deny') || url.contains('cancel') || url.contains('expire') || url.contains('payment/error')) {
      _showResult(false, 'Pembayaran Gagal', 'Transaksi tidak berhasil. Silakan coba lagi.');
      return NavigationDecision.prevent;
    }
    if (url.contains('pending') || url.contains('payment/pending')) {
      _showResult(true, 'Menunggu Pembayaran',
          'Pembayaran diproses. Status akan diperbarui otomatis.');
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  void _showResult(bool success, String title, String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: (success ? AppColors.success : AppColors.danger).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              success ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: success ? AppColors.success : AppColors.danger,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(color: AppColors.gray500, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          FinpalsButton(
            label: success ? 'Kembali ke Dashboard' : 'Coba Lagi',
            height: 48,
            onPressed: () {
              Navigator.pop(context);
              ref.invalidate(paymentProvider);
              ref.invalidate(dashboardProvider);
              context.go(success ? '/dashboard' : '/subscription');
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Batalkan Pembayaran?'),
              content: const Text('Transaksi yang belum selesai akan dibatalkan.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx),
                    child: const Text('Lanjutkan', style: TextStyle(color: AppColors.emerald600))),
                TextButton(onPressed: () { Navigator.pop(ctx); context.go('/subscription'); },
                    child: const Text('Keluar', style: TextStyle(color: AppColors.gray500))),
              ],
            ),
          ),
        ),
        title: const Text('Pembayaran Aman', style: TextStyle(fontSize: 15)),
      ),
      body: Stack(children: [
        WebViewWidget(controller: _ctrl),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: AppColors.emerald500)),
      ]),
    );
  }
}
