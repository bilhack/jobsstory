import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_strings.dart';
import '../theme/app_theme.dart';

/// Brand circle logo (gradient coin with a play mark).
class GradientMark extends StatelessWidget {
  const GradientMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.buttonGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.45),
            blurRadius: size * 0.55,
            spreadRadius: size * 0.06,
          ),
        ],
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        size: size * 0.58,
        color: Colors.white,
      ),
    );
  }
}

/// Small section heading with a gradient accent bar.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.label, {super.key, this.padding});

  final String label;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Branded gradient CTA button.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(28),
child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: loading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 22, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
        ),
      ),
    );
  }
}

/// Outlined social button (Google).
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Text(
        'G',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
        ),
      ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.surfaceLight),
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}

/// Dark rounded text field with the JobsStory look.
class BrandTextField extends StatelessWidget {
  const BrandTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.surfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }
}

/// Maps Firebase auth exceptions to friendly localized messages.
class AuthErrors {
  AuthErrors._();

  static String friendlyMessage(Object? error, {required bool isAr}) {
    if (error is! FirebaseAuthException) {
      return isAr ? AppStrings.genericErrorAr : AppStrings.genericError;
    }
    return switch (error.code) {
      'email-already-in-use' =>
        isAr ? 'هذا البريد مسجّل مسبقاً.' : AppStrings.emailInUseError,
      'invalid-email' => isAr ? 'أدخل بريداً صحيحاً.' : AppStrings.invalidEmailError,
      'invalid-credential' || 'wrong-password' || 'user-not-found' =>
        isAr ? 'البريد أو كلمة المرور غير صحيحة.' : AppStrings.wrongPasswordError,
      'weak-password' => isAr
          ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.'
          : AppStrings.weakPasswordError,
      _ => isAr ? AppStrings.genericErrorAr : AppStrings.genericError,
    };
  }
}