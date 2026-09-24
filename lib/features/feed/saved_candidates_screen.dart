import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_strings.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/story_interaction_provider.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_theme.dart';
import '../profile/seeker_profile_screen.dart';

/// Recruiter-only list of saved candidates (their public profile pages).
class SavedCandidatesScreen extends StatefulWidget {
  const SavedCandidatesScreen({super.key});

  static const String route = '/candidates';

  @override
  State<SavedCandidatesScreen> createState() => _SavedCandidatesScreenState();
}

class _SavedCandidatesScreenState extends State<SavedCandidatesScreen> {
  final Map<String, AppUser> _users = {};
  final Set<String> _requested = {};
  bool _loading = true;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<StoryInteractionProvider>();
      for (final id in provider.savedSeekerIds) {
        _requestUser(id);
      }
      setState(() => _loading = false);
    });
  }

  Future<void> _requestUser(String uid) async {
    if (_requested.contains(uid) || _users.containsKey(uid)) return;
    _requested.add(uid);
    final user = await context.read<UserRepository>().get(uid);
    if (user != null && mounted) {
      setState(() => _users[uid] = user);
    }
  }

  void _sync() {
    final ids = context.watch<StoryInteractionProvider>().savedSeekerIds;
    for (final id in ids) {
      _requestUser(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final saved = context.watch<StoryInteractionProvider>().savedSeekerIds.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_isAr ? AppStrings.candidatesAr : AppStrings.candidates),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : saved.isEmpty
                ? _EmptyCandidates(isAr: _isAr)
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: saved.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final uid = saved[index];
                      final user = _users[uid];
                      if (user == null) {
                        return const SizedBox(height: 80);
                      }
                      return _CandidateCard(
                        user: user,
                        onOpen: () => context.push(SeekerProfileScreen.route(uid)),
                        onUnsave: () {
                          final me = context.read<AuthProvider>().snapshot.profile?.uid;
                          if (me == null || me.isEmpty) return;
                          context
                              .read<StoryInteractionProvider>()
                              .toggleSaveSeeker(seekerId: uid, savedById: me);
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.user, required this.onOpen, required this.onUnsave});

  final AppUser user;
  final VoidCallback onOpen;
  final VoidCallback onUnsave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary,
                child: user.displayName.isEmpty
                    ? const Icon(Icons.person_rounded, color: Colors.white)
                    : Text(
                        user.displayName.characters.first,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    if (user.headline.isNotEmpty)
                      Text(
                        user.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onUnsave,
                child: const Icon(Icons.bookmark_remove_outlined, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCandidates extends StatelessWidget {
  const _EmptyCandidates({required this.isAr});

  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              isAr ? AppStrings.noCandidatesAr : AppStrings.noCandidates,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isAr ? 'احفظ قصص الباحثين البارزة من التغذية.' : 'Save standout seeker stories from the feed.',
              style: const TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}