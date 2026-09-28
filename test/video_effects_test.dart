import 'package:flutter_test/flutter_test.dart';
import 'package:jobsstory/features/story/video_effects.dart';

void main() {
  group('FFmpeg command builder', () {
    test('no effects produces a copy command without -vf', () {
      final cmd = buildFfmpegCommand(input: 'a.mp4', output: 'b.mp4');
      expect(cmd, contains('-i "a.mp4"'));
      expect(cmd, contains('"b.mp4"'));
      expect(cmd, contains('libx264'));
      expect(cmd, isNot(contains('-vf')));
      expect(cmd, isNot(contains('-filter_complex')));
    });

    test('none presets behave like no effects', () {
      final cmd = buildFfmpegCommand(
        input: 'a.mp4',
        output: 'b.mp4',
        filter: kNoFilter,
        background: kNoBackground,
      );
      expect(cmd, isNot(contains('-vf')));
      expect(cmd, isNot(contains('colorkey')));
    });

    test('filter only uses -vf and never a background source', () {
      final warm = kColorFilters.firstWhere((f) => f.id == 'warm');
      final cmd = buildFfmpegCommand(input: 'a.mp4', output: 'b.mp4', filter: warm);
      expect(cmd, contains('-vf'));
      expect(cmd, contains(warm.filter!));
      expect(cmd, isNot(contains('lavfi')));
      expect(cmd, isNot(contains('colorkey')));
    });

    test('background only keys green and overlays the colour source', () {
      final night = kBackgrounds.firstWhere((b) => b.id == 'night');
      final cmd = buildFfmpegCommand(input: 'a.mp4', output: 'b.mp4', background: night);
      expect(cmd, contains('color=c=0x1e2337'));
      expect(cmd, contains('colorkey=0x00FF00'));
      expect(cmd, contains('scale2ref'));
      expect(cmd, contains('overlay=0:0[outv]'));
      expect(cmd, contains('-map "[outv]"'));
    });

    test('filter + background chain both operations', () {
      final warm = kColorFilters.firstWhere((f) => f.id == 'warm');
      final night = kBackgrounds.firstWhere((b) => b.id == 'night');
      final cmd = buildFfmpegCommand(
        input: 'a.mp4',
        output: 'b.mp4',
        filter: warm,
        background: night,
      );
      expect(cmd, contains(warm.filter!));
      expect(cmd, contains('colorkey=0x00FF00'));
      expect(cmd, contains('color=c=0x1e2337'));
      expect(cmd, isNot(contains('-vf ')));
    });
  });

  group('Preset integrity', () {
    test('colour filter ids are unique and include the original', () {
      final ids = kColorFilters.map((f) => f.id).toSet();
      expect(ids.length, kColorFilters.length);
      expect(kColorFilters.first.isNone, isTrue);
      expect(kColorFilters.every((f) => f.swatchA == f.swatchA), isTrue);
    });

    test('background hex values are six hexadecimal digits', () {
      for (final bg in kBackgrounds.where((b) => !b.isNone)) {
        expect(bg.colorHex, hasLength(6));
        expect(int.tryParse(bg.colorHex, radix: 16), isNotNull);
      }
      expect(kBackgrounds.first.isNone, isTrue);
    });
  });
}
