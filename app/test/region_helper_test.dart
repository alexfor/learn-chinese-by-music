import 'package:flutter_test/flutter_test.dart';
import 'package:learn_chinese_by_music/shared/region_helper.dart';

void main() {
  group('RegionHelper', () {
    test('selects cn URL when region is cn and both URLs exist', () {
      final url = RegionHelper.selectUrl(
        cnUrl: 'https://qiniu.com/audio.mp3',
        globalUrl: 'https://r2.dev/audio.mp3',
        region: 'cn',
      );
      expect(url, equals('https://qiniu.com/audio.mp3'));
    });

    test('selects global URL when region is global and both URLs exist', () {
      final url = RegionHelper.selectUrl(
        cnUrl: 'https://qiniu.com/audio.mp3',
        globalUrl: 'https://r2.dev/audio.mp3',
        region: 'global',
      );
      expect(url, equals('https://r2.dev/audio.mp3'));
    });

    test('falls back to global URL when cn URL is null and region is cn', () {
      final url = RegionHelper.selectUrl(
        cnUrl: null,
        globalUrl: 'https://r2.dev/audio.mp3',
        region: 'cn',
      );
      expect(url, equals('https://r2.dev/audio.mp3'));
    });

    test('falls back to cn URL when global URL is null and region is global', () {
      final url = RegionHelper.selectUrl(
        cnUrl: 'https://qiniu.com/audio.mp3',
        globalUrl: null,
        region: 'global',
      );
      expect(url, equals('https://qiniu.com/audio.mp3'));
    });

    test('returns null when both URLs are null', () {
      final url = RegionHelper.selectUrl(
        cnUrl: null,
        globalUrl: null,
        region: 'cn',
      );
      expect(url, isNull);
    });
  });
}
