import 'package:flutter/material.dart';

import '../../core/config/app_strings.dart';
import '../../core/theme/app_theme.dart';

/// Onboarding — pick your role: Job Seeker or Recruiter.
/// Phase 1 wires this to Auth + Firebase.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const String route = '/onboarding';

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(AppStrings.appName),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                isAr ? AppStrings.onboardingTitleAr : AppStrings.onboardingTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'اختر دورك وابدأ رحلتك.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),
              _RoleCard(
                icon: Icons.videocam_rounded,
                title: isAr ? AppStrings.roleSeekerAr : AppStrings.roleSeeker,
                description: AppStrings.roleSeekerDesc,
                gradient: AppColors.buttonGradient,
                onTap: () => _comingSoon(context, isAr ? AppStrings.roleSeekerAr : AppStrings.roleSeeker),
              ),
              const SizedBox(height: 20),
              _RoleCard(
                icon: Icons.work_rounded,
                title: isAr ? AppStrings.roleRecruiterAr : AppStrings.roleRecruiter,
                description: AppStrings.roleRecruiterDesc,
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.primary],
                ),
                onTap: () => _comingSoon(context, isAr ? AppStrings.roleRecruiterAr : AppStrings.roleRecruiter),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String role) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$role — قريباً في المرحلة 1 (التسجيل والمصادقة)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}