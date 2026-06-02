import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Min 2 seconds for branding
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emerald600,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 52,
              ),
            )
                .animate()
                .scale(
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            const Text(
              'Finpals',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 8),

            Text(
              'Kelola keuanganmu dengan cerdas',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 400.ms),

            const SizedBox(height: 80),

            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withOpacity(0.6),
              ),
            )
                .animate()
                .fadeIn(delay: 800.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
