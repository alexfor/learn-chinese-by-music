import 'package:flutter_test/flutter_test.dart';
import 'package:learn_chinese_by_music/features/singalong/dtw.dart';

void main() {
  group('DTW', () {
    test('identical pitch curves score 100', () {
      final curve = [440.0, 466.0, 494.0, 523.0, 554.0];
      final score = dtwScore(curve, curve);
      expect(score, equals(100));
    });

    test('completely different curves score near 0', () {
      // One ascending, one constant at a very different frequency
      final ref = [100.0, 100.0, 100.0, 100.0, 100.0];
      final test = [800.0, 800.0, 800.0, 800.0, 800.0];
      final score = dtwScore(ref, test);
      expect(score, lessThan(30));
    });

    test('slightly shifted curve scores high', () {
      // Same melody, slightly shifted in time
      final ref = [261.0, 294.0, 330.0, 349.0, 392.0];
      final test = [261.0, 261.0, 294.0, 330.0, 349.0];
      final score = dtwScore(ref, test);
      expect(score, greaterThan(60));
    });

    test('empty reference curve returns 0', () {
      final score = dtwScore([], [440.0, 466.0]);
      expect(score, equals(0));
    });

    test('empty test curve returns 0', () {
      final score = dtwScore([440.0, 466.0], []);
      expect(score, equals(0));
    });

    test('both empty returns 0', () {
      final score = dtwScore([], []);
      expect(score, equals(0));
    });

    test('handles nulls in pitch curves (unvoiced frames)', () {
      // Null = unvoiced frame, treated as 0 distance to other null, penalty to voiced
      final ref = [440.0, null, 466.0, null, 494.0];
      final test = [440.0, null, 466.0, null, 494.0];
      final score = dtwScore(ref, test);
      expect(score, equals(100));
    });

    test('null vs voiced has distance penalty', () {
      final ref = [440.0, 466.0, 494.0];
      final test = [null, null, null];
      final score = dtwScore(ref, test);
      expect(score, lessThan(50));
    });
  });
}
