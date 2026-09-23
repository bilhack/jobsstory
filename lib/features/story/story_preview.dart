import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_theme.dart';

/// Video player that can be downgraded to a static card in widget tests
/// (no platform channels involved when [allowPreview] is false).
class StoryVideoPreview extends StatefulWidget {
  const StoryVideoPreview({
    super.key,
    required this.video,
    this.allowPreview = true,
  });

  final File? video;
  final bool allowPreview;

  @override
  State<StoryVideoPreview> createState() => _StoryVideoPreviewState();
}

class _StoryVideoPreviewState extends State<StoryVideoPreview> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    if (!widget.allowPreview || widget.video == null) return;
    try {
      await _controller?.dispose();
      final controller = VideoPlayerController.file(widget.video!);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      await controller.setLooping(true);
      controller.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized && !_failed) {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      );
    }
    // Static placeholder — also the widget-test friendly rendering.
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_fill_rounded, size: 72, color: Colors.white54),
        ),
      ),
    );
  }
}