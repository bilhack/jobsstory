import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_strings.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_widgets.dart';

/// Email/password + Google sign-in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String route = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  void _showError(Object error) {
    final isAr = _isAr;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AuthErrors.friendlyMessage(error, isAr: isAr)),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      _showError(AppStrings.fillAllFields);
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().signInWithEmail(_email.text, _password.text);
      // Router redirects to onboarding/home automatically from here.
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
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
                isAr ? AppStrings.loginTitleAr : AppStrings.loginTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 28),
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
              GradientButton(label: isAr ? AppStrings.loginButtonAr : AppStrings.loginButton, onPressed: _loading ? null : _submit),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.surfaceLight)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      isAr ? 'أو' : 'or',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.surfaceLight)),
                ],
              ),
              const SizedBox(height: 16),
              GoogleButton(label: _loading ? '...' : (isAr ? AppStrings.continueWithGoogleAr : AppStrings.continueWithGoogle), onPressed: _loading ? null : _google),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isAr ? 'ليس لديك حساب؟' : AppStrings.noAccount,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  TextButton(
                    onPressed: _loading ? null : () => context.pushNamed('register'),
                    child: Text(isAr ? AppStrings.registerButtonAr : AppStrings.createAccountCta),
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