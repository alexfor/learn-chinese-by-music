import 'fft.dart';
import 'yin.dart';
import 'dtw.dart';

enum PrecisionMode { normal, low }

class ScoringEngine {
  final double sampleRate;
  final PrecisionMode precision;

  late final int _frameSize;
  late final int _hopSize;

  ScoringEngine({
    this.sampleRate = 16000.0,
    this.precision = PrecisionMode.normal,
  }) {
    switch (precision) {
      case PrecisionMode.normal:
        _frameSize = 2048;
        _hopSize = 512;
      case PrecisionMode.low:
        _frameSize = 4096;
        _hopSize = 2048;
    }
  }

  /// Extract a pitch curve from raw audio samples.
  /// Returns a list of Hz values (null for unvoiced frames).
  List<double?> extractPitchCurve(List<double> samples) {
    final window = hammingWindow(_frameSize);
    final frames = frameSignal(samples, frameSize: _frameSize, hopSize: _hopSize);
    final curve = <double?>[];

    for (final frame in frames) {
      // Apply window
      final windowed = List<double>.generate(
        _frameSize,
        (i) => i < frame.length ? frame[i] * window[i] : 0.0,
      );

      // Detect pitch via YIN
      final freq = yinDetect(windowed, sampleRate: sampleRate);
      curve.add(freq);
    }

    return curve;
  }

  /// Score two pitch curves against each other.
  /// Returns 0-100 similarity score.
  int score(List<double?> reference, List<double?> test) {
    return dtwScore(reference, test);
  }
}
