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
import '../home/home_screen.dart';
import 'camera_recorder.dart';
import 'my_stories_screen.dart';
import 'story_preview.dart';
import 'video_effects.dart';

/// The 60-second story studio: record with the camera or pick from the gallery,
/// add a caption, then publish (upload progress included).
/// Effects (filters + backgrounds) are baked into the final clip before publish.
class StoryStudioScreen extends StatefulWidget {
  const StoryStudioScreen({
    super.key,
    this.picker,
    this.cameraEnabled = true,
    this.allowVideoPreview = true,
    this.videoEffectsService,
  });

  static const String route = '/studio';

  final MediaPicker? picker;
  final bool cameraEnabled;
  final bool allowVideoPreview;
  final VideoEffectsService? videoEffectsService;

  @override
  State<StoryStudioScreen> createState() => _StoryStudioScreenState();
}

class _StoryStudioScreenState extends State<StoryStudioScreen> {
  bool _cameraBroken = false;
  bool _cameraRequested = false;
  File? _base;
  File? _video;
  File? _thumbnail;
  double _progress = 0;
  bool _publishing = false;
  bool _processingFx = false;
  double _fxProgress = 0;
  ColorFilterPreset _filter = kNoFilter;
  BackgroundPreset _background = kNoBackground;
  Object? _publishError;

  final _caption = TextEditingController();

  bool get _hasVideo => _video != null;
  bool get _canPublish => _hasVideo && !_publishing && !_processingFx;
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

  /// Effect engine from the widget, then the widget tree, then production.
  VideoEffectsService get _effectsService {
    if (widget.videoEffectsService != null) return widget.videoEffectsService!;
    try {
      return context.read<VideoEffectsService>();
    } catch (_) {
      return FfmpegVideoEffectsService();
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  /// Step back: close the camera → discard the current clip → leave the studio.
  void _goBack() {
    if (_hasVideo) {
      setState(() {
        _base = null;
        _video = null;
        _thumbnail = null;
        _filter = kNoFilter;
        _background = kNoBackground;
        _processingFx = false;
        _fxProgress = 0;
        _publishError = null;
      });
      return;
    }
    if (_cameraRequested && !_cameraBroken) {
      setState(() => _cameraRequested = false);
      return;
    }
    context.go(HomeScreen.route);
  }

  void _onVideoPicked(File? file) {
    if (file == null) return;
    setState(() {
      _base = file;
      _video = file;
      _cameraBroken = false;
      _publishError = null;
      _processingFx = false;
      _fxProgress = 0;
      _filter = kNoFilter;
      _background = kNoBackground;
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
    if (error is VideoEffectsException) {
      return _isAr ? AppStrings.effectFailedAr : AppStrings.effectFailed;
    }
    return AuthErrors.friendlyMessage(error, isAr: _isAr);
  }

  String? _ownerUid() => context.read<AuthProvider>().snapshot.profile?.uid;

  void _selectFilter(ColorFilterPreset preset) {
    if (_base == null || preset.id == _filter.id) return;
    setState(() => _filter = preset);
    _applyEffects();
  }

  void _selectBackground(BackgroundPreset preset) {
    if (_base == null || preset.id == _background.id) return;
    setState(() => _background = preset);
    _applyEffects();
  }

  /// Re-encodes [_base] with the current filter/background so the preview
  /// and the published clip both reflect the effect.
  Future<void> _applyEffects() async {
    final base = _base;
    if (base == null) return;
    if (_filter.isNone && _background.isNone) {
      setState(() {
        _video = base;
        _processingFx = false;
        _fxProgress = 0;
      });
      return;
    }
    setState(() {
      _processingFx = true;
      _fxProgress = 0;
      _publishError = null;
    });
    try {
      final output = await _effectsService.process(
        input: base,
        filter: _filter,
        background: _background,
        onProgress: (p) {
          if (mounted && _processingFx) setState(() => _fxProgress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _video = output;
        _processingFx = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processingFx = false;
        _fxProgress = 0;
        _video = base;
        _filter = kNoFilter;
        _background = kNoBackground;
        _publishError = e;
      });
      _showSnack(_isAr ? AppStrings.effectFailedAr : AppStrings.effectFailed);
    }
  }

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
      _showSnack(_isAr ? AppStrings.publishedSuccessAr : AppStrings.publishedSuccess);
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: BackButton(onPressed: _goBack),
        title: const Text(AppStrings.appName),
      ),
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(child: StoryVideoPreview(video: _video, allowPreview: widget.allowVideoPreview)),
                if (_processingFx)
                  ColoredBox(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: _fxProgress == 0 ? null : _fxProgress,
                            color: AppColors.accent,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isAr ? AppStrings.applyingEffectAr : AppStrings.applyingEffect,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _EffectsBar(
          filter: _filter,
          background: _background,
          onFilter: _selectFilter,
          onBackground: _selectBackground,
          isAr: _isAr,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OutlineAction(
                icon: Icons.replay_rounded,
                label: _isAr ? 'إعادة التصوير' : 'Retake',
                onTap: _processingFx
                    ? null
                    : () => setState(() {
                          _base = null;
                          _video = null;
                          _thumbnail = null;
                          _filter = kNoFilter;
                          _background = kNoBackground;
                          _processingFx = false;
                          _fxProgress = 0;
                        }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OutlineAction(
                icon: Icons.photo_library_rounded,
                label: _isAr ? 'الصورة الغلاف' : 'Cover',
                onTap: _processingFx ? null : _pickThumbnail,
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
            onClose: () => setState(() => _cameraRequested = false),
          ),
          const SizedBox(height: 16),
        ],
        GradientButton(
          label: _isAr ? AppStrings.pickFromGalleryAr : AppStrings.pickFromGallery,
          onPressed: _publishing || _processingFx ? null : _pickFromGallery,
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

/// Filters + backgrounds chooser. Gets its own file later if it grows.
class _EffectsBar extends StatelessWidget {
  const _EffectsBar({
    required this.filter,
    required this.background,
    required this.onFilter,
    required this.onBackground,
    required this.isAr,
  });

  final ColorFilterPreset filter;
  final BackgroundPreset background;
  final ValueChanged<ColorFilterPreset> onFilter;
  final ValueChanged<BackgroundPreset> onBackground;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? AppStrings.filtersSectionAr : AppStrings.filtersSection,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kColorFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final preset = kColorFilters[i];
              return _FxOption(
                label: isAr ? preset.nameAr : preset.nameEn,
                selected: preset.id == filter.id,
                swatch: GradientBoxSwatch(a: preset.swatchA, b: preset.swatchB),
                onTap: () => onFilter(preset),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isAr ? AppStrings.backgroundSectionAr : AppStrings.backgroundSection,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kBackgrounds.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final preset = kBackgrounds[i];
              return _FxOption(
                label: isAr ? preset.nameAr : preset.nameEn,
                selected: preset.id == background.id,
                swatch: SolidColorSwatch(color: Color(preset.color ?? 0x000000)),
                onTap: () => onBackground(preset),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isAr ? AppStrings.chromaHintAr : AppStrings.chromaHint,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _FxOption extends StatelessWidget {
  const _FxOption({
    required this.label,
    required this.swatch,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Widget swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 56,
              height: 54,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: swatch,
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class GradientBoxSwatch extends StatelessWidget {
  const GradientBoxSwatch({super.key, required this.a, required this.b});

  final Color a;
  final Color b;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [a, b],
        ),
      ),
    );
  }
}

class SolidColorSwatch extends StatelessWidget {
  const SolidColorSwatch({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(decoration: BoxDecoration(color: color));
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

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