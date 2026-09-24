import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_strings.dart';
import '../../core/media/feed_video_tile.dart';
import '../../core/models/app_user.dart';
import '../../core/models/story.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/story_interaction_provider.dart';
import '../../core/services/story_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_widgets.dart';

/// Public seeker page: the video story + a simplified CV + contact/save.
class SeekerProfileScreen extends StatefulWidget {
  const SeekerProfileScreen({super.key, required this.uid});

  static String route(String uid) => '/seeker/$uid';

  final String uid;

  @override
  State<SeekerProfileScreen> createState() => _SeekerProfileScreenState();
}

class _SeekerProfileScreenState extends State<SeekerProfileScreen> {
  AppUser? _user;
  Story? _story;
  bool _loading = true;
  Object? _error;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';
  String get _myUid => context.read<AuthProvider>().snapshot.profile?.uid ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = context.read<UserRepository>();
    final service = context.read<StoryService>();
    try {
      final user = await repo.get(widget.uid);
      final stories = await service.fetchApprovedStoriesOf(widget.uid);
      if (!mounted) return;
      setState(() {
        _user = user;
        _story = stories.isEmpty ? null : stories.first;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _toggleSave() async {
    if (_myUid.isEmpty) return;
    await context
        .read<StoryInteractionProvider>()
        .toggleSaveSeeker(seekerId: widget.uid, savedById: _myUid);
  }

  Future<void> _contactSheet() async {
    final email = _user?.email ?? '';
    final name = _user?.displayName ?? '';
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isAr ? 'تواصل مع $name' : 'Contact $name',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _copyEmail(email);
                },
                icon: const Icon(Icons.copy_rounded),
                label: Text(_isAr ? 'نسخ البريد الإلكتروني' : 'Copy email'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.mail_outline_rounded),
                label: Text(_isAr ? 'الرسائل داخل التطبيق (المرحلة 4)' : 'In-app messages (Phase 4)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.surfaceLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyEmail(String email) async {
    if (email.isEmpty) return;
    try {
      await Clipboard.setData(ClipboardData(text: email));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(_isAr ? 'تم نسخ البريد' : 'Email copied'),
          behavior: SnackBarBehavior.floating,
        ));
    } catch (_) {
      // Clipboard unavailable (e.g. some test environments) — ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? Center(child: Text(_isAr ? 'تعذّر تحميل الملف.' : 'Could not load the profile.'))
              : _user == null
                  ? Center(child: Text(_isAr ? 'لم يتم العثور على هذا المستخدم.' : 'User not found.'))
                  : _ProfileBody(
                      user: _user!,
                      story: _story,
                      isAr: _isAr,
                      isSelf: _myUid == widget.uid,
                      onToggleSave: _toggleSave,
                      onContact: _contactSheet,
                    ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.user,
    required this.story,
    required this.isAr,
    required this.isSelf,
    required this.onToggleSave,
    required this.onContact,
  });

  final AppUser user;
  final Story? story;
  final bool isAr;
  final bool isSelf;
  final VoidCallback onToggleSave;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final interactions = context.watch<StoryInteractionProvider>();
    final saved = interactions.isSaved(user.uid);
    final sections = _sections;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        AspectRatio(
          aspectRatio: 9 / 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: story == null
                ? _NoVideoPlaceholder(isAr: isAr)
                : context.watch<FeedVideoTile>().build(
                      videoUrl: story!.videoUrl,
                      thumbnailUrl: story!.thumbnailUrl,
                      autoplay: true,
                      initiallyMuted: true,
                    ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              child: user.displayName.isEmpty
                  ? const Icon(Icons.person_rounded, color: Colors.white)
                  : Text(
                      user.displayName.characters.first,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (user.headline.isNotEmpty)
                    Text(user.headline, style: const TextStyle(color: AppColors.textMuted, height: 1.5)),
                  if (user.location.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(user.location, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (user.bio.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(user.bio, style: const TextStyle(height: 1.6)),
        ],
        for (final section in sections) ...[
          const SizedBox(height: 20),
          section,
        ],
        const SizedBox(height: 24),
        if (!isSelf) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggleSave,
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                  label: Text(saved
                      ? (isAr ? AppStrings.savedAr : AppStrings.saved)
                      : (isAr ? AppStrings.saveSeekerAr : AppStrings.saveSeeker)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: saved ? AppColors.accent : AppColors.textPrimary,
                    side: BorderSide(color: saved ? AppColors.accent : AppColors.surfaceLight),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  label: isAr ? AppStrings.contactAr : AppStrings.contact,
                  onPressed: onContact,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  List<Widget> get _sections {
    final items = <Widget>[];
    if (user.skills.isNotEmpty) {
      items.add(_Section(
        title: isAr ? 'المهارات' : 'Skills',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final skill in user.skills) Chip(label: Text(skill)),
          ],
        ),
      ));
    }
    if (user.experience.isNotEmpty) {
      items.add(_Section(title: isAr ? 'الخبرة' : 'Experience', child: Text(user.experience, style: const TextStyle(height: 1.6))));
    }
    if (user.education.isNotEmpty) {
      items.add(_Section(title: isAr ? 'التعليم' : 'Education', child: Text(user.education, style: const TextStyle(height: 1.6))));
    }
    if (user.languages.isNotEmpty) {
      items.add(_Section(
        title: isAr ? 'اللغات' : 'Languages',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final lang in user.languages) Chip(label: Text(lang)),
          ],
        ),
      ));
    }
    return items;
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.accent),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _NoVideoPlaceholder extends StatelessWidget {
  const _NoVideoPlaceholder({required this.isAr});

  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: const Center(child: Icon(Icons.videocam_outlined, size: 72, color: Colors.white70)),
    );
  }
}