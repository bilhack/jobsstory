import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_strings.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/jobs_provider.dart';
import 'my_jobs_screen.dart';

/// Recruiter-only form to publish a new job opening.
class JobCreateScreen extends StatefulWidget {
  const JobCreateScreen({super.key});

  static const String route = '/jobs/new';

  @override
  State<JobCreateScreen> createState() => _JobCreateScreenState();
}

class _JobCreateScreenState extends State<JobCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _company = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  bool _publishing = false;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    final me = context.read<AuthProvider>().snapshot.profile;
    if (me == null) return;

    setState(() => _publishing = true);
    try {
      await context.read<JobsProvider>().create(
            title: _title.text,
            company: _company.text,
            location: _location.text,
            description: _description.text,
            createdBy: me.uid,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isAr ? AppStrings.jobPostedAr : AppStrings.jobPosted)),
      );
      context.go(MyJobsScreen.route);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_isAr ? AppStrings.postJobAr : AppStrings.postJob),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  _title,
                  label: _isAr ? AppStrings.jobTitleLabelAr : AppStrings.jobTitleLabel,
                  hint: _isAr ? 'مثال: مهندس Flutter' : 'e.g. Flutter Engineer',
                  validate: true,
                ),
                const SizedBox(height: 16),
                _field(
                  _company,
                  label: _isAr ? AppStrings.companyLabelAr : AppStrings.companyLabel,
                  hint: _isAr ? 'مثال: شركة النور' : 'e.g. An-Noor Tech',
                  validate: true,
                ),
                const SizedBox(height: 16),
                _field(
                  _location,
                  label: _isAr ? AppStrings.locationLabelAr : AppStrings.locationLabel,
                  hint: _isAr ? 'مثال: دبي (اختياري)' : 'e.g. Dubai (optional)',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: _isAr ? AppStrings.descriptionLabelAr : AppStrings.descriptionLabel,
                    hintText: _isAr ? 'متطلبات الوظيفة والمزايا...' : 'Requirements and perks...',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _publishing ? null : _publish,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _publishing
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isAr ? AppStrings.postJobAr : AppStrings.postJob),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller, {
    required String label,
    required String hint,
    bool validate = false,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      validator: validate
          ? (value) => (value == null || value.trim().isEmpty)
              ? (_isAr ? AppStrings.fillJobFieldsAr : AppStrings.fillJobFields)
              : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}