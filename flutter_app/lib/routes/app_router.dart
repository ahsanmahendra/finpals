import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/transaction/transaction_list_screen.dart';
import '../screens/transaction/add_transaction_screen.dart';
import '../screens/scan/scan_screen.dart';
import '../screens/scan/ocr_review_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/ai/insight_screen.dart';
import '../screens/payment/subscription_screen.dart';
import '../screens/payment/payment_webview_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/common/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    redirect: (context, state) {
      // Wait for session restore
      if (!authState.isInitialized) return null;

      final isAuth = authState.isAuthenticated;
      final path = state.matchedLocation;

      final publicPaths = [
        '/splash', '/login', '/register',
        '/forgot-password', '/otp',
      ];
      final isPublic = publicPaths.any((p) => path.startsWith(p));

      if (!isAuth && !isPublic) return '/login';
      if (isAuth && isPublic && path != '/splash') return '/dashboard';
      return null;
    },
    routes: [
      // ── Public routes ─────────────────
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) => _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (_, state) => _slidePage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (_, state) =>
            _slidePage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (_, state) {
          final phone = state.extra as String? ?? '';
          return _slidePage(state, OtpScreen(phone: phone));
        },
      ),

      // ── Authenticated shell ────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (_, state) =>
                _fadePage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: '/transactions',
            pageBuilder: (_, state) =>
                _slidePage(state, const TransactionListScreen()),
          ),
          GoRoute(
            path: '/transactions/add',
            pageBuilder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return _slidePage(state, AddTransactionScreen(prefill: extra));
            },
          ),
          GoRoute(
            path: '/scan',
            pageBuilder: (_, state) =>
                _slidePage(state, const ScanScreen()),
          ),
          GoRoute(
            path: '/ocr-review',
            pageBuilder: (_, state) {
              final ocrData = state.extra as Map<String, dynamic>;
              return _slidePage(state, OcrReviewScreen(ocrData: ocrData));
            },
          ),
          GoRoute(
            path: '/budget',
            pageBuilder: (_, state) =>
                _slidePage(state, const BudgetScreen()),
          ),
          GoRoute(
            path: '/insights',
            pageBuilder: (_, state) =>
                _slidePage(state, const InsightScreen()),
          ),
          GoRoute(
            path: '/subscription',
            pageBuilder: (_, state) =>
                _slidePage(state, const SubscriptionScreen()),
          ),
          GoRoute(
            path: '/payment-webview',
            pageBuilder: (_, state) {
              final extra = state.extra as Map<String, dynamic>;
              return _slidePage(
                state,
                PaymentWebviewScreen(
                  snapToken: extra['snapToken'] as String,
                  orderId: extra['orderId'] as String,
                ),
              );
            },
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, state) =>
                _slidePage(state, const ProfileScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Halaman tidak ditemukan: ${state.error}'),
      ),
    ),
  );
});

// ── Page transitions ───────────────────
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, __, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
