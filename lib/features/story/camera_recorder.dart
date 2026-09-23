import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

const int kCameraRecorderSeconds = 60;

/// In-app 60-second recorder backed by the `camera` plugin.
/// Lives in its own widget so the studio stays testable without a camera.
class CameraRecorder extends StatefulWidget {
  const CameraRecorder({
    super.key,
    required this.onRecorded,
    required this.onUnavailable,
  });

  final ValueChanged<File> onRecorded;
  final VoidCallback onUnavailable;

  @override
  State<CameraRecorder> createState() => _CameraRecorderState();
}

class _CameraRecorderState extends State<CameraRecorder> {
  CameraController? _controller;
  bool _initializing = true;
  bool _recording = false;
  int _remaining = kCameraRecorderSeconds;
  Timer? _timer;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      final controller = CameraController(cameras.first, ResolutionPreset.high, enableAudio: true);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _initializing = false);
        widget.onUnavailable();
      }
    }
  }

  Future<void> _toggleRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (_recording) {
      await _stopRecording();
    } else {
      try {
        await controller.startVideoRecording();
        if (!mounted) return;
        setState(() {
          _recording = true;
          _remaining = kCameraRecorderSeconds;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() => _remaining -= 1);
          if (_remaining <= 0) {
            timer.cancel();
            await _stopRecording();
          }
        });
      } catch (_) {
        widget.onUnavailable();
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    try {
      final shot = await _controller?.stopVideoRecording();
      if (shot == null || !mounted) return;
      setState(() => _recording = false);
      widget.onRecorded(File(shot.path));
    } catch (_) {
      if (mounted) setState(() => _recording = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_initializing) {
      return const AspectRatio(
        aspectRatio: 9 / 16,
        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }
    if (controller == null) {
      return const SizedBox.shrink(); // onUnavailable already fired.
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                child: Text(
                  _recording
                      ? '$_remaining'
                      : (_isAr ? '60 ثانية' : '60s'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _recording ? Colors.black26 : Colors.white24,
                    border: Border.all(color: _recording ? AppColors.danger : Colors.white, width: 4),
                  ),
                  child: Icon(
                    _recording ? Icons.stop_rounded : Icons.videocam_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}