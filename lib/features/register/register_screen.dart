import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_strings.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_widgets.dart';

/// Create an account. Role is passed via query in the onboarding flow,
/// or picked inline with chips when registering directly.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialRole});

  static const String route = '/register';

  final UserRole? initialRole;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserRole? _role;
  bool _loading = false;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AuthErrors.friendlyMessage(error, isAr: _isAr)),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty || _password.text.isEmpty) {
      _showError(AppStrings.fillAllFields);
      return;
    }
    if (_role == null) {
      _showError(_isAr ? 'اختر دورك أولاً.' : 'Please pick a role first.');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().signUpWithEmail(
            displayName: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            role: _role!,
          );
      // Redirect to /home happens automatically through the router.
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _isAr;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text(AppStrings.appName)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                isAr ? AppStrings.registerTitleAr : AppStrings.registerTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '${isAr ? AppStrings.registerRoleHintAr : AppStrings.registerRoleHint}:',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              _RoleSelector(
                selected: _role,
                onChanged: (r) => setState(() => _role = r),
              ),
              const SizedBox(height: 24),
              BrandTextField(
                controller: _name,
                label: isAr ? AppStrings.nameLabelAr : AppStrings.nameLabel,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              BrandTextField(
                controller: _email,
                label: isAr ? AppStrings.emailLabelAr : AppStrings.emailLabel,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              BrandTextField(
                controller: _password,
                label: isAr ? AppStrings.passwordLabelAr : AppStrings.passwordLabel,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: isAr ? AppStrings.registerButtonAr : AppStrings.registerButton,
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isAr ? 'لديك حساب؟' : AppStrings.haveAccount,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  TextButton(
                    onPressed: _loading ? null : () => context.goNamed('login'),
                    child: Text(isAr ? AppStrings.loginButtonAr : AppStrings.signInCta),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selected, required this.onChanged});

  final UserRole? selected;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            selected: selected == UserRole.seeker,
            onSelected: (_) => onChanged(UserRole.seeker),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_rounded, size: 18),
                const SizedBox(width: 6),
                Text(isAr ? AppStrings.roleSeekerAr : AppStrings.roleSeeker),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            selected: selected == UserRole.recruiter,
            onSelected: (_) => onChanged(UserRole.recruiter),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.work_rounded, size: 18),
                const SizedBox(width: 6),
                Text(isAr ? AppStrings.roleRecruiterAr : AppStrings.roleRecruiter),
              ],
            ),
          ),
        ),
      ],
    );
  }
}