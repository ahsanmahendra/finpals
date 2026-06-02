import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../themes/app_theme.dart';

// ─────────────────────────────────────────
// FINPALS BUTTON
// ─────────────────────────────────────────
class FinpalsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final double height;

  const FinpalsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ElevatedButton(
        style: backgroundColor != null
            ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
            : null,
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────
// FINPALS TEXT FIELD
// ─────────────────────────────────────────
class FinpalsTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;

  const FinpalsTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.inputFormatters,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          focusNode: focusNode,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.gray800,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// FINPALS CARD
// ─────────────────────────────────────────
class FinpalsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;

  const FinpalsCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// LOADING OVERLAY
// ─────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.35),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.emerald500,
                      strokeWidth: 3,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: const TextStyle(
                          color: AppColors.gray700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.emerald500),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.gray800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SHIMMER LOADING PLACEHOLDER
// ─────────────────────────────────────────
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this)
      ..repeat();
    _anim = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [
              Color(0xFFE8EDF0),
              Color(0xFFF5F7F9),
              Color(0xFFE8EDF0),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// CURRENCY FORMATTER UTIL
// ─────────────────────────────────────────
class CurrencyText extends StatelessWidget {
  final double amount;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final bool compact;

  const CurrencyText({
    super.key,
    required this.amount,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
    this.color,
    this.compact = false,
  });

  String _format(double v) {
    if (compact) {
      if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
      if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
    }
    final formatted = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(amount),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.gray800,
      ),
    );
  }
}

// ─────────────────────────────────────────
// SNACKBAR HELPER
// ─────────────────────────────────────────
class FinpalsSnackbar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    Color bg = AppColors.gray800;
    if (isError) bg = AppColors.danger;
    if (isSuccess) bg = AppColors.emerald600;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: bg,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}
