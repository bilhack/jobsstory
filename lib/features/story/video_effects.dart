import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';

/// A color-grade preset (TikTok-style) that is baked into the recorded video.
@immutable
class ColorFilterPreset {
  const ColorFilterPreset({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.filter,
    required this.swatchA,
    required this.swatchB,
  });

  /// Stable id, also used as the "original/none" marker when empty.
  final String id;
  final String nameAr;
  final String nameEn;

  /// A pure ffmpeg `-vf` chain. Null means "no filter".
  final String? filter;

  /// Two colors used to render a small gradient swatch in the UI.
  final Color swatchA;
  final Color swatchB;

  bool get isNone => filter == null;
}

/// A replacement background, chroma-keyed from the video.
@immutable
class BackgroundPreset {
  const BackgroundPreset({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.color,
  });

  final String id;
  final String nameAr;
  final String nameEn;

  /// Solid background source color; null means "no background replacement".
  final int? color;

  bool get isNone => color == null;

  /// ffmpeg hex form (0xRRGGBB → "RRGGBB").
  String get colorHex => (color ?? 0x000000).toRadixString(16).padLeft(8, '0').substring(2);
}

/// The chroma-key colour we remove (a uniform green backdrop by default).
String kChromaKeyColorHex = '0x00FF00';

/// Bundled presets shown in the studio.
const List<ColorFilterPreset> kColorFilters = [
  ColorFilterPreset(
    id: 'none',
    nameAr: 'أصلي',
    nameEn: 'None',
    filter: null,
    swatchA: Color(0xFF3C4453),
    swatchB: Color(0xFF3C4453),
  ),
  ColorFilterPreset(
    id: 'warm',
    nameAr: 'كودا',
    nameEn: 'Koda',
    filter: 'eq=contrast=1.05:saturation=1.30:gamma=1.12:gamma_r=1.06:gamma_b=0.93',
    swatchA: Color(0xFFF7A54A),
    swatchB: Color(0xFFDF6F2C),
  ),
  ColorFilterPreset(
    id: 'cool',
    nameAr: 'قرجي',
    nameEn: 'Chilly',
    filter: 'eq=contrast=1.04:saturation=1.15:gamma_r=0.95:gamma_b=1.08',
    swatchA: Color(0xFF4A9FF7),
    swatchB: Color(0xFF2C67DF),
  ),
  ColorFilterPreset(
    id: 'vivid',
    nameAr: 'بون',
    nameEn: 'Pop',
    filter: 'eq=contrast=1.12:saturation=1.75',
    swatchA: Color(0xFF26DE81),
    swatchB: Color(0xFF1ABDA4),
  ),
  ColorFilterPreset(
    id: 'mono',
    nameAr: 'مونو',
    nameEn: 'Mono',
    filter: 'hue=s=0,eq=contrast=1.15',
    swatchA: Color(0xFF8A8A8A),
    swatchB: Color(0xFF4A4A4A),
  ),
  ColorFilterPreset(
    id: 'violet',
    nameAr: 'بنفسجي',
    nameEn: 'Violet',
    filter: 'eq=saturation=1.60:contrast=1.18,hue=b=18',
    swatchA: Color(0xFF9B59FF),
    swatchB: Color(0xFF5B2CD9),
  ),
  ColorFilterPreset(
    id: 'cherry',
    nameAr: 'كرز',
    nameEn: 'Cherry',
    filter: 'eq=saturation=1.40:contrast=1.05,hue=b=-12',
    swatchA: Color(0xFFFF6B9D),
    swatchB: Color(0xFFE53170),
  ),
  ColorFilterPreset(
    id: 'cinema',
    nameAr: 'سينما',
    nameEn: 'Cinema',
    filter: 'curves=preset=increase_contrast,eq=saturation=0.85:gamma=1.05',
    swatchA: Color(0xFF2D3561),
    swatchB: Color(0xFF6A4C93),
  ),
];

const List<BackgroundPreset> kBackgrounds = [
  BackgroundPreset(id: 'none', nameAr: 'بدون', nameEn: 'None', color: null),
  BackgroundPreset(id: 'night', nameAr: 'ليل', nameEn: 'Night', color: 0x1E2337),
  BackgroundPreset(id: 'violet', nameAr: 'بنفسجي', nameEn: 'Violet', color: 0x4A00E0),
  BackgroundPreset(id: 'pink', nameAr: 'وردي', nameEn: 'Pink', color: 0xFF4290),
  BackgroundPreset(id: 'mint', nameAr: 'نعناع', nameEn: 'Mint', color: 0x11998E),
  BackgroundPreset(id: 'crimson', nameAr: 'أحمر', nameEn: 'Crimson', color: 0xCB2D3E),
  BackgroundPreset(id: 'sky', nameAr: 'سماوي', nameEn: 'Sky', color: 0x007ADF),
  BackgroundPreset(id: 'ink', nameAr: 'حبر', nameEn: 'Ink', color: 0x0F0F0F),
];

ColorFilterPreset get kNoFilter => kColorFilters.first;
BackgroundPreset get kNoBackground => kBackgrounds.first;

/// Thrown when applying an effect fails on the device.
class VideoEffectsException implements Exception {
  const VideoEffectsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Applies effects to a recorded video, producing a new file.
abstract class VideoEffectsService {
  /// Returns the processed file, or [input] unchanged when both [filter]
  /// and [background] are the "none" presets.
  Future<File> process({
    required File input,
    ColorFilterPreset? filter,
    BackgroundPreset? background,
    ValueChanged<double>? onProgress,
  });
}

/// Builds an ffmpeg command-line for [input] → [output] with optional
/// colour grade and background replacement. Pure string builder (unit
/// tested without a real FFmpeg binary).
String buildFfmpegCommand({
  required String input,
  required String output,
  ColorFilterPreset? filter,
  BackgroundPreset? background,
}) {
  final hasFilter = filter != null && !filter.isNone;
  final hasBackground = background != null && !background.isNone;
  if (!hasFilter && !hasBackground) {
    return '-y -i "$input" -map 0:v -map 0:a? -c:v libx264 -preset veryfast '
        '-crf 26 -pix_fmt yuv420p -acodec copy -movflags +faststart "$output"';
  }
  final filterGraph = _filterGraph(filter, background)!;
  if (hasBackground) {
    final colorHex = background.colorHex;
    return '-y -i "$input" -f lavfi -i color=c=0x$colorHex:s=1280x720 '
        '-filter_complex "$filterGraph" -map "[outv]" -map 0:a? '
        '-c:v libx264 -preset veryfast -crf 26 -pix_fmt yuv420p '
        '-acodec copy -movflags +faststart "$output"';
  }
  return '-y -i "$input" -vf "$filterGraph" -map 0:v -map 0:a? '
      '-c:v libx264 -preset veryfast -crf 26 -pix_fmt yuv420p '
      '-acodec copy -movflags +faststart "$output"';
}

String? _filterGraph(ColorFilterPreset? filter, BackgroundPreset? background) {
  final grade = (filter == null || filter.isNone) ? null : filter.filter;
  final withBackground = background != null && !background.isNone;
  if (grade == null && !withBackground) return null;
  if (!withBackground) return grade;

  final afterKey = grade == null ? '[ck]' : '[ck]$grade';
  return '[0:v]colorkey=$kChromaKeyColorHex:0.12:0.20[ck];'
      '[1:v][$afterKey]scale2ref[bg][fg];'
      '[bg][fg]overlay=0:0[outv]';
}

/// FFmpegKit-backed implementation (FFmpeg 8, GPL build with x264 + libavfilter).
class FfmpegVideoEffectsService implements VideoEffectsService {
  @override
  Future<File> process({
    required File input,
    ColorFilterPreset? filter,
    BackgroundPreset? background,
    ValueChanged<double>? onProgress,
  }) async {
    final useFilter = filter != null && !filter.isNone;
    final useBackground = background != null && !background.isNone;
    if (!useFilter && !useBackground) return input;

    final outDir = await Directory.systemTemp.createTemp('jobsstory_fx');
    final output = File('${outDir.path}/story_ed.mp4');

    // Probe the duration (ffprobe reports seconds) for a smooth progress bar.
    var durationMs = 0.0;
    try {
      final session = await FFprobeKit.getMediaInformation(input.path);
      final raw = session.getMediaInformation()?.getDuration();
      durationMs = (double.tryParse(raw ?? '') ?? 0) * 1000;
    } catch (_) {
      durationMs = 0;
    }

    var processOk = true;
    var failureDetail = 'Unknown error';

    await FFmpegKit.executeAsync(
      buildFfmpegCommand(
        input: input.path,
        output: output.path,
        filter: filter,
        background: background,
      ),
      (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isCancel(returnCode)) {
          processOk = false;
          failureDetail = 'cancelled';
          return;
        }
        if (!ReturnCode.isSuccess(returnCode)) {
          processOk = false;
          final logs = (await session.getOutput()) ?? '';
          final tail = logs.split('\n').lastWhere((l) => l.trim().isNotEmpty, orElse: () => '');
          failureDetail = 'return $returnCode: $tail';
        }
      },
      null,
      (statistics) {
        if (onProgress == null || !processOk || durationMs <= 0) return;
        final time = statistics.getTime().toDouble();
        onProgress((time / durationMs).clamp(0.0, 1.0));
      },
    );

    if (!processOk) throw VideoEffectsException('FFmpeg failed: $failureDetail');
    if (!await output.exists()) {
      throw const VideoEffectsException('Output was not produced');
    }
    return output;
  }
}