import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen for errors
    ref.listen(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        FinpalsSnackbar.show(context, next.error!, isError: true);
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Logo & Branding ──────────────
                _buildHeader(),
                const SizedBox(height: 48),

                // ── Email ────────────────────────
                FinpalsTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'nama@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email wajib diisi';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v)) return 'Format email tidak valid';
                    return null;
                  },
                ).animate().slideY(
                  begin: 0.3, delay: 300.ms, duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),

                const SizedBox(height: 16),

                // ── Password ─────────────────────
                FinpalsTextField(
                  controller: _passCtrl,
                  label: 'Password',
                  hint: 'Masukkan password',
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined
                               : Icons.visibility_outlined,
                      color: AppColors.gray400,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    if (v.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ).animate().slideY(
                  begin: 0.3, delay: 380.ms, duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),

                // ── Forgot password ──────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text(
                      'Lupa Password?',
                      style: TextStyle(
                        color: AppColors.emerald600,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                // ── Login button ─────────────────
                FinpalsButton(
                  label: 'Masuk',
                  isLoading: authState.isLoading,
                  onPressed: _handleLogin,
                ).animate().slideY(
                  begin: 0.3, delay: 460.ms, duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),

                const SizedBox(height: 28),

                // ── Divider ───────────────────────
                _buildDivider(),

                const SizedBox(height: 24),

                // ── Google ────────────────────────
                _buildSocialButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Lanjutkan dengan Google',
                  color: const Color(0xFF4285F4),
                  onTap: () =>
                      ref.read(authProvider.notifier).loginWithGoogle(),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 12),

                // ── WhatsApp OTP ──────────────────
                _buildSocialButton(
                  icon: Icons.phone_android_rounded,
                  label: 'Login dengan WhatsApp OTP',
                  color: const Color(0xFF25D366),
                  onTap: () => _showPhoneDialog(),
                ).animate().fadeIn(delay: 680.ms),

                const SizedBox(height: 36),

                // ── Register link ─────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Belum punya akun? ',
                      style: TextStyle(color: AppColors.gray400, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: const Text(
                        'Daftar Sekarang',
                        style: TextStyle(
                          color: AppColors.emerald600,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 750.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.emerald400, AppColors.emerald600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald500.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 40,
          ),
        )
            .animate()
            .scale(duration: 500.ms, curve: Curves.easeOutBack)
            .fadeIn(),

        const SizedBox(height: 20),

        const Text(
          'Selamat datang kembali',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.gray800,
          ),
        ).animate().fadeIn(delay: 150.ms),

        const SizedBox(height: 6),

        const Text(
          'Login ke akun Finpals kamu',
          style: TextStyle(color: AppColors.gray400, fontSize: 14),
        ).animate().fadeIn(delay: 220.ms),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.gray200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'atau',
            style: TextStyle(
              color: AppColors.gray400,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.gray200)),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.gray200),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.gray700,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showPhoneDialog() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.center,
            ),
            const Text(
              'Login via WhatsApp',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan nomor WA kamu, kami akan kirim kode OTP.',
              style: TextStyle(color: AppColors.gray400, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor WhatsApp',
                hintText: '08xxxxxxxxxx',
                prefixIcon: Icon(Icons.phone_android_rounded),
              ),
            ),
            const SizedBox(height: 16),
            FinpalsButton(
              label: 'Kirim OTP',
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final phone = ctrl.text.trim();
                await ref.read(authProvider.notifier).sendOtp(phone);
                if (mounted) context.push('/otp', extra: phone);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
  }
}
