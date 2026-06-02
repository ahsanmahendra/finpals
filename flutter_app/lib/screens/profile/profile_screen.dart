import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.emerald500),
            onPressed: () => _showEditProfileSheet(context, ref, user),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // ── Avatar & Name ──────────────
            _ProfileHeader(user: user)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1),

            const SizedBox(height: 24),

            // ── Account Info ───────────────
            _SectionCard(
              title: 'Informasi Akun',
              children: [
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Nama',
                  value: user.name,
                ),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user.email,
                ),
                _InfoRow(
                  icon: Icons.phone_android_rounded,
                  label: 'WhatsApp',
                  value: user.phone ?? 'Belum ditambahkan',
                ),
                _InfoRow(
                  icon: Icons.verified_outlined,
                  label: 'Status',
                  value: user.isVerified ? 'Terverifikasi' : 'Belum verifikasi',
                  valueColor: user.isVerified
                      ? AppColors.emerald600
                      : AppColors.warning,
                ),
              ],
            ).animate().slideY(begin: 0.2, delay: 80.ms),

            const SizedBox(height: 16),

            // ── Subscription ───────────────
            _SectionCard(
              title: 'Langganan',
              children: [
                _SubscriptionRow(isPremium: user.isPremium),
              ],
            ).animate().slideY(begin: 0.2, delay: 140.ms),

            const SizedBox(height: 16),

            // ── Settings ───────────────────
            _SectionCard(
              title: 'Pengaturan',
              children: [
                _SettingRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Ubah Password',
                  onTap: () => _showChangePasswordSheet(context, ref),
                ),
                _SettingRow(
                  icon: Icons.notifications_outlined,
                  label: 'Notifikasi',
                  trailing: Switch(
                    value: true,
                    onChanged: (_) {},
                    activeColor: AppColors.emerald500,
                  ),
                ),
                _SettingRow(
                  icon: Icons.language_rounded,
                  label: 'Bahasa',
                  trailing: const Text('Indonesia',
                      style:
                          TextStyle(color: AppColors.gray400, fontSize: 14)),
                ),
              ],
            ).animate().slideY(begin: 0.2, delay: 200.ms),

            const SizedBox(height: 16),

            // ── Danger zone ────────────────
            _SectionCard(
              title: 'Lainnya',
              children: [
                _SettingRow(
                  icon: Icons.help_outline_rounded,
                  label: 'Bantuan & FAQ',
                  onTap: () {},
                ),
                _SettingRow(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Kebijakan Privasi',
                  onTap: () {},
                ),
                _SettingRow(
                  icon: Icons.logout_rounded,
                  label: 'Keluar',
                  labelColor: AppColors.danger,
                  iconColor: AppColors.danger,
                  onTap: () => _confirmLogout(context, ref),
                ),
              ],
            ).animate().slideY(begin: 0.2, delay: 260.ms),

            const SizedBox(height: 20),

            Center(
              child: Text(
                'Finpals v1.0.0',
                style: const TextStyle(
                    color: AppColors.gray300, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(
      BuildContext context, WidgetRef ref, dynamic user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(user: user),
    );
  }

  void _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Kamu akan keluar dari akun Finpals.',
            style: TextStyle(color: AppColors.gray500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.gray500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(80, 40)),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Header ─────────────────────
class _ProfileHeader extends ConsumerStatefulWidget {
  final dynamic user;
  const _ProfileHeader({required this.user});

  @override
  ConsumerState<_ProfileHeader> createState() =>
      _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  bool _uploading = false;

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final url = await ref
          .read(userServiceProvider)
          .uploadAvatar(File(picked.path));
      final updated = widget.user.copyWith(avatarUrl: url);
      ref.read(authProvider.notifier).updateUser(updated);
    } catch (e) {
      if (mounted) {
        FinpalsSnackbar.show(context, 'Gagal upload foto', isError: true);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = (widget.user.name as String)
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Column(
      children: [
        Stack(
          children: [
            // Avatar
            GestureDetector(
              onTap: _changeAvatar,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.emerald200, width: 3),
                ),
                child: ClipOval(
                  child: widget.user.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.user.avatarUrl as String,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const CircularProgressIndicator(
                                  strokeWidth: 2),
                          errorWidget: (_, __, ___) =>
                              _AvatarFallback(initials: initials),
                        )
                      : _AvatarFallback(initials: initials),
                ),
              ),
            ),
            // Edit icon
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: AppColors.emerald500,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _uploading
                    ? const Padding(
                        padding: EdgeInsets.all(4),
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white),
                      )
                    : const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.user.name as String,
          style: AppTextStyles.headingMedium,
        ),
        const SizedBox(height: 4),
        Text(
          widget.user.email as String,
          style: const TextStyle(
              color: AppColors.gray400, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (widget.user.isPremium as bool)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded,
                    color: Colors.amber, size: 14),
                SizedBox(width: 6),
                Text('Premium',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;
  const _AvatarFallback({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.emerald100,
      alignment: Alignment.center,
      child: Text(initials,
          style: const TextStyle(
              color: AppColors.emerald700,
              fontSize: 30,
              fontWeight: FontWeight.w800)),
    );
  }
}

// ─── Section Card ──────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.gray600)),
        ),
        Container(
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
          child: Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1),
                ),
            ],
          ]),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gray400, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.gray600)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.gray800)),
        ],
      ),
    );
  }
}

class _SubscriptionRow extends StatelessWidget {
  final bool isPremium;
  const _SubscriptionRow({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(
            isPremium
                ? Icons.workspace_premium_rounded
                : Icons.star_outline_rounded,
            color: isPremium ? Colors.amber : AppColors.gray400,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isPremium ? 'Premium' : 'Free Plan',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.gray600),
            ),
          ),
          if (!isPremium)
            GestureDetector(
              onTap: () => context.push('/subscription'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Upgrade',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            )
          else
            const Text('Aktif',
                style: TextStyle(
                    color: AppColors.emerald600,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingRow({
    required this.icon,
    required this.label,
    this.labelColor,
    this.iconColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                color: iconColor ?? AppColors.gray400, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      color: labelColor ?? AppColors.gray700,
                      fontWeight: FontWeight.w500)),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(Icons.chevron_right_rounded,
                        color: AppColors.gray300, size: 20)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Profile Sheet ────────────────────
class _EditProfileSheet extends ConsumerStatefulWidget {
  final dynamic user;
  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() =>
      _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name as String);
    _phoneCtrl =
        TextEditingController(text: widget.user.phone as String? ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const Text('Edit Profil', style: AppTextStyles.headingMedium),
          const SizedBox(height: 20),
          FinpalsTextField(
            controller: _nameCtrl,
            label: 'Nama Lengkap',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          FinpalsTextField(
            controller: _phoneCtrl,
            label: 'Nomor WhatsApp',
            hint: '08xxxxxxxxxx',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          FinpalsButton(
            label: 'Simpan Perubahan',
            isLoading: _isLoading,
            onPressed: _handleSave,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_nameCtrl.text.trim().isEmpty) {
      FinpalsSnackbar.show(context, 'Nama tidak boleh kosong',
          isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final updated = await ref.read(userServiceProvider).updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
      );
      ref.read(authProvider.notifier).updateUser(updated);
      if (mounted) {
        Navigator.pop(context);
        FinpalsSnackbar.show(context, 'Profil berhasil diperbarui',
            isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        FinpalsSnackbar.show(context, 'Gagal memperbarui profil',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─── Change Password Sheet ─────────────────
class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState
    extends ConsumerState<_ChangePasswordSheet> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure1 = true, _obscure2 = true, _obscure3 = true;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const Text('Ubah Password',
              style: AppTextStyles.headingMedium),
          const SizedBox(height: 20),
          FinpalsTextField(
            controller: _oldCtrl,
            label: 'Password Lama',
            obscureText: _obscure1,
            suffixIcon: IconButton(
              icon: Icon(_obscure1
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
                  color: AppColors.gray400, size: 20),
              onPressed: () => setState(() => _obscure1 = !_obscure1),
            ),
          ),
          const SizedBox(height: 14),
          FinpalsTextField(
            controller: _newCtrl,
            label: 'Password Baru',
            hint: 'Min. 8 karakter',
            obscureText: _obscure2,
            suffixIcon: IconButton(
              icon: Icon(_obscure2
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
                  color: AppColors.gray400, size: 20),
              onPressed: () => setState(() => _obscure2 = !_obscure2),
            ),
          ),
          const SizedBox(height: 14),
          FinpalsTextField(
            controller: _confirmCtrl,
            label: 'Konfirmasi Password Baru',
            obscureText: _obscure3,
            suffixIcon: IconButton(
              icon: Icon(_obscure3
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
                  color: AppColors.gray400, size: 20),
              onPressed: () => setState(() => _obscure3 = !_obscure3),
            ),
          ),
          const SizedBox(height: 24),
          FinpalsButton(
            label: 'Ubah Password',
            isLoading: _loading,
            onPressed: _handleChange,
          ),
        ],
      ),
    );
  }

  Future<void> _handleChange() async {
    if (_newCtrl.text != _confirmCtrl.text) {
      FinpalsSnackbar.show(context, 'Password baru tidak cocok',
          isError: true);
      return;
    }
    if (_newCtrl.text.length < 8) {
      FinpalsSnackbar.show(context, 'Password minimal 8 karakter',
          isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(userServiceProvider).changePassword(
        oldPassword: _oldCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (mounted) {
        Navigator.pop(context);
        FinpalsSnackbar.show(context, 'Password berhasil diubah',
            isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        FinpalsSnackbar.show(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
