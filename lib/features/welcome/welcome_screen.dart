import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_widgets.dart';

/// Welcome — bold gradient, logo, slogan and a single CTA.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const String route = '/';

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Stack(
            children: [
              const _GlowOrb(top: -80, left: -60, size: 240, color: AppColors.secondary, opacity: 0.55),
              const _GlowOrb(bottom: 120, right: -70, size: 280, color: AppColors.accent, opacity: 0.35),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) => Transform.scale(
                        scale: 0.6 + 0.4 * value,
                        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                      ),
                      child: const Center(child: GradientMark(size: 120)),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      isAr ? AppStrings.appNameAr : AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAr ? AppStrings.sloganAr : AppStrings.sloganEn,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.welcomeTagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    const Spacer(flex: 3),
                    GradientButton(
                      label: isAr ? AppStrings.ctaStartAr : AppStrings.ctaStart,
                      icon: Icons.rocket_launch_rounded,
                      onPressed: () => context.pushNamed('onboarding'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}