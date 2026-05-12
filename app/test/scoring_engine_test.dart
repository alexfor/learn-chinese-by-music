import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_chinese_by_music/features/singalong/scoring_engine.dart';

void main() {
  group('ScoringEngine', () {
    test('perfect match returns score near 100', () {
      const sampleRate = 16000.0;
      const freq = 440.0;
      const frameSize = 2048;
      final signal = List<double>.generate(frameSize, (i) =>
          sin(2 * pi * freq * i / sampleRate));

      final engine = ScoringEngine(sampleRate: sampleRate);
      final refCurve = engine.extractPitchCurve(signal);
      final testCurve = engine.extractPitchCurve(signal);

      final score = engine.score(refCurve, testCurve);
      expect(score, greaterThan(90));
    });

    test('silence vs pitched signal returns low score', () {
      const sampleRate = 16000.0;
      const freq = 440.0;
      const frameSize = 2048;

      final engine = ScoringEngine(sampleRate: sampleRate);
      final pitched = List<double>.generate(frameSize, (i) =>
          sin(2 * pi * freq * i / sampleRate));
      final silence = List<double>.filled(frameSize, 0.0);

      final refCurve = engine.extractPitchCurve(pitched);
      final testCurve = engine.extractPitchCurve(silence);

      final score = engine.score(refCurve, testCurve);
      expect(score, lessThan(50));
    });

    test('extractPitchCurve returns list of nullable doubles', () {
      const sampleRate = 16000.0;
      const freq = 440.0;
      const frameSize = 4096;
      final signal = List<double>.generate(frameSize, (i) =>
          sin(2 * pi * freq * i / sampleRate));

      final engine = ScoringEngine(sampleRate: sampleRate);
      final curve = engine.extractPitchCurve(signal);
      expect(curve, isNotEmpty);
      // Should have detected some pitches
      expect(curve.where((f) => f != null), isNotEmpty);
    });

    test('low precision mode uses larger frame size', () {
      const sampleRate = 16000.0;
      const freq = 440.0;
      const frameSize = 4096;
      final signal = List<double>.generate(frameSize, (i) =>
          sin(2 * pi * freq * i / sampleRate));

      final engineNormal = ScoringEngine(sampleRate: sampleRate, precision: PrecisionMode.normal);
      final engineLow = ScoringEngine(sampleRate: sampleRate, precision: PrecisionMode.low);

      final curveNormal = engineNormal.extractPitchCurve(signal);
      final curveLow = engineLow.extractPitchCurve(signal);

      // Low precision should produce fewer frames (larger hop)
      expect(curveLow.length, lessThanOrEqualTo(curveNormal.length));
    });
  });
}
