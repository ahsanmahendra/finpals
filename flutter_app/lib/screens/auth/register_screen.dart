import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

// ════════════════════════════════════════
// REGISTER SCREEN
// ════════════════════════════════════════
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        FinpalsSnackbar.show(context, next.error!, isError: true);
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Buat Akun'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Mulai perjalanan\nkeuangan cerdasmu 🚀',
                  style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800,
                    color: AppColors.gray800, height: 1.3,
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 8),
                const Text(
                  'Daftar gratis, kelola keuangan lebih baik.',
                  style: TextStyle(color: AppColors.gray400, fontSize: 14),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 32),

                FinpalsTextField(
                  controller: _nameCtrl,
                  label: 'Nama Lengkap',
                  hint: 'Nama kamu',
                  prefixIcon: const Icon(Icons.person_outline_rounded,
                      color: AppColors.gray400),
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Nama minimal 2 karakter' : null,
                ).animate().slideY(begin: 0.2, duration: 350.ms),

                const SizedBox(height: 14),

                FinpalsTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'nama@email.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.gray400),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email wajib diisi';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
                      return 'Format email tidak valid';
                    return null;
                  },
                ).animate().slideY(begin: 0.2, delay: 60.ms, duration: 350.ms),

                const SizedBox(height: 14),

                FinpalsTextField(
                  controller: _phoneCtrl,
                  label: 'Nomor WhatsApp (Opsional)',
                  hint: '08xxxxxxxxxx',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_android_rounded,
                      color: AppColors.gray400),
                  textInputAction: TextInputAction.next,
                ).animate().slideY(begin: 0.2, delay: 120.ms, duration: 350.ms),

                const SizedBox(height: 14),

                FinpalsTextField(
                  controller: _passCtrl,
                  label: 'Password',
                  hint: 'Min. 8 karakter',
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                        color: AppColors.gray400, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    if (v.length < 8) return 'Minimal 8 karakter';
                    return null;
                  },
                ).animate().slideY(begin: 0.2, delay: 180.ms, duration: 350.ms),

                const SizedBox(height: 14),

                FinpalsTextField(
                  controller: _confirmCtrl,
                  label: 'Konfirmasi Password',
                  hint: 'Ulangi password',
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                        color: AppColors.gray400, size: 20),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v != _passCtrl.text) return 'Password tidak cocok';
                    return null;
                  },
                ).animate().slideY(begin: 0.2, delay: 240.ms, duration: 350.ms),

                const SizedBox(height: 20),

                // Terms checkbox
                GestureDetector(
                  onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: _agreeTerms
                              ? AppColors.emerald500 : Colors.transparent,
                          border: Border.all(
                            color: _agreeTerms
                                ? AppColors.emerald500 : AppColors.gray300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _agreeTerms
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(TextSpan(children: [
                          const TextSpan(
                            text: 'Saya setuju dengan ',
                            style: TextStyle(
                                color: AppColors.gray600, fontSize: 13),
                          ),
                          TextSpan(
                            text: 'Syarat & Ketentuan',
                            style: const TextStyle(
                              color: AppColors.emerald600,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const TextSpan(
                            text: ' Finpals',
                            style: TextStyle(
                                color: AppColors.gray600, fontSize: 13),
                          ),
                        ])),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 28),

                FinpalsButton(
                  label: 'Daftar Sekarang',
                  isLoading: authState.isLoading,
                  onPressed: _agreeTerms ? _handleRegister : null,
                ).animate().slideY(begin: 0.2, delay: 360.ms, duration: 350.ms),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? ',
                        style: TextStyle(
                            color: AppColors.gray400, fontSize: 14)),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Text('Masuk',
                          style: TextStyle(
                            color: AppColors.emerald600,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      FinpalsSnackbar.show(context, 'Setujui syarat & ketentuan terlebih dahulu');
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );
  }
}

// ════════════════════════════════════════
// FORGOT PASSWORD SCREEN
// ════════════════════════════════════════
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Lupa Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: _sent ? _buildSuccessState() : _buildFormState(authState),
        ),
      ),
    );
  }

  Widget _buildFormState(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: AppColors.emerald500, size: 36),
          ).animate().scale(duration: 400.ms),

          const SizedBox(height: 24),
          const Text('Reset Password',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800,
                  color: AppColors.gray800)),
          const SizedBox(height: 8),
          const Text(
            'Masukkan email kamu dan kami akan kirimkan link reset password.',
            style: TextStyle(color: AppColors.gray400, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),

          FinpalsTextField(
            controller: _emailCtrl,
            label: 'Email',
            hint: 'nama@email.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.gray400),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email wajib diisi';
              if (!v.contains('@')) return 'Format email tidak valid';
              return null;
            },
          ),

          const SizedBox(height: 28),

          FinpalsButton(
            label: 'Kirim Link Reset',
            isLoading: authState.isLoading,
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: AppColors.emerald50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_rounded,
              color: AppColors.emerald500, size: 50),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 24),
        const Text('Email Terkirim!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                color: AppColors.gray800)),
        const SizedBox(height: 12),
        Text(
          'Link reset password telah dikirim ke\n${_emailCtrl.text}',
          style: const TextStyle(color: AppColors.gray400, fontSize: 14,
              height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        FinpalsButton(
          label: 'Kembali ke Login',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authProvider.notifier)
        .forgotPassword(_emailCtrl.text.trim());
    if (ok && mounted) setState(() => _sent = true);
  }
}

// ════════════════════════════════════════
// OTP SCREEN — WhatsApp OTP verification
// ════════════════════════════════════════
class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_countdown <= 1) {
        setState(() { _countdown = 0; _canResend = true; });
        return false;
      }
      setState(() => _countdown--);
      return true;
    });
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        FinpalsSnackbar.show(context, next.error!, isError: true);
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Verifikasi OTP'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7FAF0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.phone_android_rounded,
                    color: Color(0xFF25D366), size: 38),
              ).animate().scale(duration: 400.ms),

              const SizedBox(height: 24),
              const Text('Masukkan Kode OTP',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                      color: AppColors.gray800)),
              const SizedBox(height: 8),
              Text(
                'Kami mengirim kode 6 digit ke WhatsApp\n${widget.phone}',
                style: const TextStyle(color: AppColors.gray400,
                    fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 40),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _OtpBox(
                  controller: _ctrls[i],
                  focusNode: _nodes[i],
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) {
                      _nodes[i + 1].requestFocus();
                    } else if (v.isEmpty && i > 0) {
                      _nodes[i - 1].requestFocus();
                    }
                    if (_otp.length == 6) _handleVerify();
                  },
                )),
              ),

              const SizedBox(height: 32),

              FinpalsButton(
                label: 'Verifikasi',
                isLoading: authState.isLoading,
                onPressed: _otp.length == 6 ? _handleVerify : null,
              ),

              const SizedBox(height: 24),

              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _handleResend,
                        child: const Text('Kirim Ulang OTP',
                            style: TextStyle(color: AppColors.emerald600,
                                fontWeight: FontWeight.w600)),
                      )
                    : Text(
                        'Kirim ulang dalam ${_countdown}s',
                        style: const TextStyle(color: AppColors.gray400,
                            fontSize: 14),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerify() async {
    if (_otp.length != 6) return;
    await ref.read(authProvider.notifier).verifyOtp(
      phone: widget.phone,
      otp: _otp,
    );
  }

  Future<void> _handleResend() async {
    setState(() { _countdown = 60; _canResend = false; });
    _startCountdown();
    await ref.read(authProvider.notifier).sendOtp(widget.phone);
    if (mounted) FinpalsSnackbar.show(context, 'OTP baru telah dikirim');
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48, height: 56,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.gray800,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.gray200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.emerald500, width: 2),
          ),
          filled: true,
          fillColor: AppColors.gray50,
        ),
      ),
    );
  }
}
