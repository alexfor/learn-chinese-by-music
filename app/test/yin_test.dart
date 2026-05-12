import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_chinese_by_music/features/singalong/yin.dart';

void main() {
  group('YIN', () {
    test('detects frequency of a pure sine wave at 440 Hz', () {
      const sampleRate = 16000.0;
      const freq = 440.0;
      const frameSize = 1024;
      final signal = List<double>.generate(frameSize, (i) =>
          sin(2 * pi * freq * i / sampleRate));

      final result = yinDetect(signal, sampleRate: sampleRate);
      expect(result, isNotNull);
      expect(result!, closeTo(440.0, 5.0));
    });

    test('detects frequency of a 261 Hz sine (middle C)', () {
      const sampleRate = 16000.0;
      const freq = 261.63;
      const frameSize = 2048;
      final signal = List<double>.generate(frameSize, (i) =>
          sin(2 * pi * freq * i / sampleRate));

      final result = yinDetect(signal, sampleRate: sampleRate);
      expect(result, isNotNull);
      expect(result!, closeTo(261.63, 3.0));
    });

    test('returns null for silence', () {
      const sampleRate = 16000.0;
      const frameSize = 1024;
      final signal = List<double>.filled(frameSize, 0.0);

      final result = yinDetect(signal, sampleRate: sampleRate);
      expect(result, isNull);
    });

    test('returns null for white noise with high threshold', () {
      const sampleRate = 16000.0;
      const frameSize = 1024;
      final rng = Random(42);
      final signal = List<double>.generate(frameSize, (_) => rng.nextDouble() * 2 - 1);

      // With a strict threshold, noise should not be detected as pitched
      final result = yinDetect(signal, sampleRate: sampleRate, threshold: 0.05);
      expect(result, isNull);
    });

    test('detects 100 Hz in a signal with two harmonics', () {
      const sampleRate = 16000.0;
      const fundamental = 100.0;
      const frameSize = 2048;
      final signal = List<double>.generate(frameSize, (i) =>
          sin(2 * pi * fundamental * i / sampleRate) +
          0.5 * sin(2 * pi * 2 * fundamental * i / sampleRate));

      final result = yinDetect(signal, sampleRate: sampleRate);
      expect(result, isNotNull);
      expect(result!, closeTo(100.0, 3.0));
    });
  });
}
