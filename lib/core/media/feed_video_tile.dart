import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_theme.dart';

/// Renders the story video inside the feed. The real implementation uses
/// `video_player`; widget tests inject a fake builder and avoid platform channels.
abstract class FeedVideoTile {
  Widget build({
    required String videoUrl,
    String? thumbnailUrl,
    required bool autoplay,
    required bool initiallyMuted,
  });
}

/// Production tile: network video, loops, starts muted (TikTok convention)
/// and exposes a small sound toggle. Autoplay only for the visible page.
class RealFeedVideoTile implements FeedVideoTile {
  @override
  Widget build({
    required String videoUrl,
    String? thumbnailUrl,
    required bool autoplay,
    required bool initiallyMuted,
  }) {
    return _RealFeedVideo(
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      autoplay: autoplay,
      initiallyMuted: initiallyMuted,
    );
  }
}

class _RealFeedVideo extends StatefulWidget {
  const _RealFeedVideo({
    required this.videoUrl,
    this.thumbnailUrl,
    required this.autoplay,
    required this.initiallyMuted,
  });

  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoplay;
  final bool initiallyMuted;

  @override
  State<_RealFeedVideo> createState() => _RealFeedVideoState();
}

class _RealFeedVideoState extends State<_RealFeedVideo> {
  late final VideoPlayerController _controller;
  bool _muted = true;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _muted = widget.initiallyMuted;
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(true)
      ..setVolume(_muted ? 0 : 1)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        if (widget.autoplay) _controller.play();
      }).catchError((Object _) {
        // Surface errors as a silent placeholder; the feed still navigates.
      });
  }

  @override
  void didUpdateWidget(_RealFeedVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoplay != oldWidget.autoplay && _ready) {
      widget.autoplay ? _controller.play() : _controller.pause();
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller.setVolume(_muted ? 0 : 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_ready)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(width: _controller.value.size.width, height: _controller.value.size.height, child: VideoPlayer(_controller)),
          )
        else
          _VideoFallback(thumbnailUrl: widget.thumbnailUrl),
        Positioned(
          bottom: 24,
          right: 12,
          child: _SoundButton(muted: _muted, onToggle: _toggleMute),
        ),
      ],
    );
  }
}

class _VideoFallback extends StatelessWidget {
  const _VideoFallback({this.thumbnailUrl});

  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final thumb = thumbnailUrl;
    if (thumb != null && thumb.isNotEmpty) {
      return Image.network(thumb, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _VideoFallback());
    }
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: const Center(child: Icon(Icons.videocam_outlined, size: 72, color: Colors.white70)),
    );
  }
}

class _SoundButton extends StatelessWidget {
  const _SoundButton({required this.muted, required this.onToggle});

  final bool muted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onToggle,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}