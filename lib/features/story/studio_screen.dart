import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_strings.dart';
import '../../core/media/media_picker.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/story_provider.dart';
import '../../core/services/story_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_widgets.dart';
import 'camera_recorder.dart';
import 'my_stories_screen.dart';
import 'story_preview.dart';

/// The 60-second story studio: record with the camera or pick from the gallery,
/// add a caption, then publish (upload progress included).
class StoryStudioScreen extends StatefulWidget {
  const StoryStudioScreen({
    super.key,
    this.picker,
    this.cameraEnabled = true,
    this.allowVideoPreview = true,
  });

  static const String route = '/studio';

  final MediaPicker? picker;
  final bool cameraEnabled;
  final bool allowVideoPreview;

  @override
  State<StoryStudioScreen> createState() => _StoryStudioScreenState();
}

class _StoryStudioScreenState extends State<StoryStudioScreen> {
  bool _cameraBroken = false;
  bool _cameraRequested = false;
  File? _video;
  File? _thumbnail;
  double _progress = 0;
  bool _publishing = false;
  Object? _publishError;

  final _caption = TextEditingController();

  bool get _hasVideo => _video != null;
  bool get _canPublish => _hasVideo && !_publishing;
  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  /// Picker from the widget, then the widget tree (test DI), then production.
  MediaPicker get _picker {
    if (widget.picker != null) return widget.picker!;
    try {
      return context.read<MediaPicker>();
    } catch (_) {
      return ImagePickerMediaPicker();
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _onVideoPicked(File? file) {
    if (file == null) return;
    setState(() {
      _video = file;
      _cameraBroken = false;
      _publishError = null;
    });
  }

  Future<void> _pickFromGallery() async {
    try {
      _onVideoPicked(await _picker.pickVideo());
    } catch (_) {
      _showSnack(AppStrings.pickFailed(_isAr));
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final file = await _picker.pickImage();
      if (file == null) return;
      setState(() => _thumbnail = file);
    } catch (_) {
      _showSnack(AppStrings.pickFailed(_isAr));
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  String _errorMessage(Object error) {
    if (error is StoryTooLongException) {
      return _isAr ? AppStrings.storyTooLongAr : AppStrings.storyTooLong;
    }
    return AuthErrors.friendlyMessage(error, isAr: _isAr);
  }

  String? _ownerUid() => context.read<AuthProvider>().snapshot.profile?.uid;

  Future<void> _publish() async {
    if (!_canPublish) return;
    final ownerUid = _ownerUid();
    if (ownerUid == null || ownerUid.isEmpty) {
      _showSnack(_isAr ? 'يرجى إعادة تسجيل الدخول.' : 'Please sign in again.');
      return;
    }

    setState(() {
      _publishing = true;
      _publishError = null;
      _progress = 0;
    });

    try {
      await context.read<StoryProvider>().publishStory(
            video: _video!,
            thumbnail: _thumbnail,
            caption: _caption.text,
            ownerUid: ownerUid,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      if (!mounted) return;
      _showSnack(_isAr ? 'تم نشر قصتك بنجاح' : 'Your story was published');
      context.go(MyStoriesScreen.route);
    } catch (e) {
      if (!mounted) return;
      setState(() => _publishError = e);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text(AppStrings.appName)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isAr ? AppStrings.studioTitleAr : AppStrings.studioTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                _isAr ? AppStrings.studioHintAr : AppStrings.studioHint,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              if (_hasVideo) _previewSection() else _sourceSection(),
              const SizedBox(height: 20),
              BrandTextField(
                controller: _caption,
                label: _isAr ? AppStrings.captionLabelAr : AppStrings.captionLabel,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              if (_publishError != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage(_publishError!),
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
              if (_publishing) ...[
                LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.accent,
                ),
                const SizedBox(height: 12),
              ],
              GradientButton(
                label: _publishing
                    ? (_isAr ? 'جاري النشر…' : 'Publishing…')
                    : (_isAr ? AppStrings.publishStoryAr : AppStrings.publishStory),
                onPressed: _canPublish ? _publish : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 9 / 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: RepaintBoundary(child: StoryVideoPreview(video: _video, allowPreview: widget.allowVideoPreview)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OutlineAction(
                icon: Icons.replay_rounded,
                label: _isAr ? 'إعادة التصوير' : 'Retake',
                onTap: () => setState(() {
                  _video = null;
                  _thumbnail = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OutlineAction(
                icon: Icons.photo_library_rounded,
                label: _isAr ? 'الصورة الغلاف' : 'Cover',
                onTap: _pickThumbnail,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sourceSection() {
    final showRecorder = widget.cameraEnabled && !_cameraBroken && _cameraRequested;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Camera is mounted only on explicit request — keeps route building cheap
        // and lets widget tests run without the camera plugin.
        if (widget.cameraEnabled && !_cameraBroken && !_cameraRequested) ...[
          _OutlineAction(
            icon: Icons.videocam_rounded,
            label: _isAr ? 'سجّل فيديو' : 'Record video',
            onTap: () => setState(() => _cameraRequested = true),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: Divider(color: AppColors.surfaceLight)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('أو', style: TextStyle(color: AppColors.textMuted)),
              ),
              Expanded(child: Divider(color: AppColors.surfaceLight)),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (showRecorder) ...[
          CameraRecorder(
            onRecorded: _onVideoPicked,
            onUnavailable: () => setState(() => _cameraBroken = true),
          ),
          const SizedBox(height: 16),
        ],
        GradientButton(
          label: _isAr ? AppStrings.pickFromGalleryAr : AppStrings.pickFromGallery,
          onPressed: _publishing ? null : _pickFromGallery,
        ),
        if (_cameraBroken) ...[
          const SizedBox(height: 12),
          Text(
            _isAr ? 'تعذّر الوصول إلى الكاميرا — اختر من المعرض.' : 'Camera unavailable — pick from the gallery instead.',
            style: const TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.surfaceLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}