import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_strings.dart';
import '../../core/theme/app_theme.dart';

const int kCameraRecorderSeconds = 60;

/// In-app 60-second recorder backed by the `camera` plugin.
/// Lives in its own widget so the studio stays testable without a camera.
class CameraRecorder extends StatefulWidget {
  const CameraRecorder({
    super.key,
    required this.onRecorded,
    required this.onUnavailable,
    required this.onClose,
  });

  final ValueChanged<File> onRecorded;
  final VoidCallback onUnavailable;
  final VoidCallback onClose;

  @override
  State<CameraRecorder> createState() => _CameraRecorderState();
}

class _CameraRecorderState extends State<CameraRecorder> {
  CameraController? _controller;
  bool _initializing = true;
  bool _recording = false;
  bool _torchOn = false;
  int _remaining = kCameraRecorderSeconds;
  Timer? _timer;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _initializing = false);
          widget.onUnavailable();
        }
        return;
      }
      _cameras = cameras;
      await _activateCamera(cameras.first);
    } catch (_) {
      if (mounted) {
        setState(() => _initializing = false);
        widget.onUnavailable();
      }
    }
  }

  Future<void> _activateCamera(CameraDescription description) async {
    final previous = _controller;
    final controller = CameraController(description, ResolutionPreset.high, enableAudio: true);
    try {
      await controller.initialize();
    } catch (_) {
      await controller.dispose();
      widget.onUnavailable();
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _initializing = false;
      _torchOn = false;
    });
    if (previous != null && previous != controller) {
      // Old controller outlived its use.
      try {
        await previous.dispose();
      } catch (_) {}
    }
  }

  Future<void> _flipCamera() async {
    final controller = _controller;
    if (controller == null || _cameras.length < 2) return;
    final next = (_cameraIndex + 1) % _cameras.length;
    setState(() {
      _cameraIndex = next;
      _initializing = true;
    });
    await _activateCamera(_cameras[next]);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final mode = _torchOn ? FlashMode.off : FlashMode.torch;
    try {
      await controller.setFlashMode(mode);
      if (!mounted) return;
      setState(() => _torchOn = mode == FlashMode.torch);
    } catch (_) {
      // Flash unsupported on this camera — stay silent.
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

  Future<void> _close() async {
    _timer?.cancel();
    try {
      await _controller?.stopVideoRecording();
    } catch (_) {}
    widget.onClose();
  }

  @override
  void dispose() {
    _timer?.cancel();
    final controller = _controller;
    if (controller == null) {
      super.dispose();
      return;
    }
    if (controller.value.isRecordingVideo) {
      // Stop cleanly so the partial clip is never persisted as a story.
      controller.stopVideoRecording().then(
            (_) => controller.dispose(),
            onError: (_) => controller.dispose(),
          );
    } else {
      controller.dispose();
    }
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
            _glassChip(
              top: 12,
              right: 12,
              child: Text(
                _recording
                    ? '$_remaining'
                    : (_isAr ? '60 ثانية' : '60s'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            _glassButton(
              top: 12,
              left: 12,
              tooltip: _isAr ? AppStrings.closeCameraAr : AppStrings.closeCamera,
              icon: Icons.close_rounded,
              onPressed: _close,
            ),
            if (_cameras.length > 1)
              _glassButton(
                top: 64,
                left: 12,
                tooltip: _isAr ? AppStrings.flipCameraAr : AppStrings.flipCamera,
                icon: Icons.cameraswitch_rounded,
                onPressed: _flipCamera,
                spinOnTap: true,
              ),
            if (controller.value.isInitialized)
              _glassButton(
                top: 116,
                left: 12,
                tooltip: _isAr ? AppStrings.flashToggleAr : AppStrings.flashToggle,
                icon: _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                onPressed: _toggleFlash,
                selected: _torchOn,
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

  Widget _glassChip({required double top, required double right, required Widget child}) {
    return Positioned(
      top: top,
      right: right,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
        child: child,
      ),
    );
  }

  Widget _glassButton({
    required double top,
    required double left,
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    bool selected = false,
    bool spinOnTap = false,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: selected ? AppColors.accent : Colors.black54,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: AnimatedRotation(
              turns: spinOnTap && _cameraIndex > 0 ? (_cameraIndex % 2) * 1.0 : 0,
              duration: const Duration(milliseconds: 250),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}