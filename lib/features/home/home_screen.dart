import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_strings.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

/// Post-auth shell. Placeholder for the real experiences:
/// seeker → my story / jobs | recruiter → feed / jobs / candidates.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String route = '/home';

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final auth = context.watch<AuthProvider>();
    final profile = auth.snapshot.profile;
    final roleLabel = switch (auth.role) {
      UserRole.seeker => (isAr ? AppStrings.roleSeekerAr : AppStrings.roleSeeker),
      UserRole.recruiter => (isAr ? AppStrings.roleRecruiterAr : AppStrings.roleRecruiter),
      null => '',
    };
    final name = (profile?.displayName.isNotEmpty ?? false) ? profile!.displayName : '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                  ),
                  IconButton(
                    tooltip: isAr ? AppStrings.signOutAr : AppStrings.signOut,
                    onPressed: () => context.read<AuthProvider>().signOut(),
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isAr ? AppStrings.homeHelloAr : AppStrings.homeHello} $name',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        roleLabel,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _FeaturePlaceholder(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePlaceholder extends StatelessWidget {
  const _FeaturePlaceholder();

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const Icon(Icons.rocket_launch_rounded, color: AppColors.accent, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                isAr
                    ? 'المرحلة 1 جاهزة!\nقريباً: سجل قصتك، وظائف، وتغذية المرشحين.'
                    : 'Phase 1 done!\nComing next: your story, jobs & candidate feed.',
                style: const TextStyle(color: AppColors.textMuted, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}