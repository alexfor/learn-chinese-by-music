import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_chinese_by_music/features/singalong/fft.dart';

void main() {
  group('FFT', () {
    test('FFT of a DC signal returns magnitude at bin 0', () {
      final input = List<double>.filled(8, 1.0);
      final result = fft(input);
      expect(result.length, equals(8));
      expect(result[0].abs, closeTo(8.0, 0.01));
      for (int i = 1; i < result.length; i++) {
        expect(result[i].abs, closeTo(0.0, 0.01));
      }
    });

    test('FFT of a single-frequency sine wave peaks at correct bin', () {
      const sampleRate = 16000.0;
      const freq = 440.0;
      const n = 1024;
      final input = List<double>.generate(n, (i) =>
          sin(2 * pi * freq * i / sampleRate));
      final result = fft(input);

      // Only search first half (Nyquist) — FFT is conjugate-symmetric
      int peakBin = 0;
      double peakMag = 0;
      for (int i = 0; i < n ~/ 2; i++) {
        final mag = result[i].abs;
        if (mag > peakMag) {
          peakMag = mag;
          peakBin = i;
        }
      }
      expect(peakBin, equals(28));
    });

    test('FFT length must be power of 2', () {
      expect(() => fft([1.0, 2.0, 3.0]), throwsArgumentError);
    });

    test('inverse FFT recovers original signal', () {
      final original = <double>[1, 2, 3, 4, 0, -1, -2, -3];
      final transformed = fft(original);
      final recovered = ifft(transformed);
      for (int i = 0; i < original.length; i++) {
        expect(recovered[i].real, closeTo(original[i], 0.001));
      }
    });
  });

  group('HammingWindow', () {
    test('hamming window endpoints are small and center is large', () {
      const n = 8;
      final w = hammingWindow(n);
      expect(w.length, equals(n));
      expect(w[0], closeTo(0.08, 0.01));
      expect(w[n ~/ 2], greaterThan(0.9));
    });

    test('hamming window sums to approximately N * 0.54', () {
      const n = 1024;
      final w = hammingWindow(n);
      final sum = w.reduce((a, b) => a + b);
      expect(sum, closeTo(n * 0.54, n * 0.02));
    });
  });

  group('frameSignal', () {
    test('frames a signal with correct overlap', () {
      final signal = List<double>.generate(16, (i) => i.toDouble());
      final frames = frameSignal(signal, frameSize: 8, hopSize: 4);
      expect(frames.length, equals(3));
      expect(frames[0], equals([0, 1, 2, 3, 4, 5, 6, 7]));
      expect(frames[1], equals([4, 5, 6, 7, 8, 9, 10, 11]));
      expect(frames[2], equals([8, 9, 10, 11, 12, 13, 14, 15]));
    });

    test('zero-pads last frame if signal is shorter than frame size', () {
      // 10 samples [0..9], frame=8, hop=4
      // Frame 0: signal[0..7] = [0,1,2,3,4,5,6,7]
      // Frame 1: signal[4..9] = [4,5,6,7,8,9] + pad [0,0]
      final signal = List<double>.generate(10, (i) => i.toDouble());
      final frames = frameSignal(signal, frameSize: 8, hopSize: 4);
      expect(frames.length, equals(2));
      expect(frames[0], equals([0, 1, 2, 3, 4, 5, 6, 7]));
      expect(frames[1][0], equals(4.0));
      expect(frames[1][5], equals(9.0));
      expect(frames[1][6], equals(0.0)); // zero-padded
      expect(frames[1][7], equals(0.0)); // zero-padded
    });
  });
}
