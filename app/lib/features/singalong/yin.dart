import 'dart:math';

/// YIN pitch detection algorithm.
///
/// Returns the detected fundamental frequency in Hz, or null if the
/// signal is unpitched (below threshold).
///
/// Reference: de Cheveigné, A., & Kawahara, H. (2002). YIN, a fundamental
/// frequency estimator for speech and music.
double? yinDetect(
  List<double> buffer, {
  required double sampleRate,
  double threshold = 0.15,
}) {
  final halfLen = buffer.length ~/ 2;

  // Step 2: Difference function
  final diff = List<double>.filled(halfLen, 0.0);
  for (int tau = 1; tau < halfLen; tau++) {
    double sum = 0;
    for (int i = 0; i < halfLen; i++) {
      final d = buffer[i] - buffer[i + tau];
      sum += d * d;
    }
    diff[tau] = sum;
  }

  // Step 3: Cumulative mean normalized difference function (CMND)
  final cmnd = List<double>.filled(halfLen, 0.0);
  cmnd[0] = 1.0;
  double runningSum = 0.0;
  for (int tau = 1; tau < halfLen; tau++) {
    runningSum += diff[tau];
    cmnd[tau] = diff[tau] * tau / runningSum;
  }

  // Step 4: Absolute threshold — find first tau below threshold
  int tauEstimate = -1;
  for (int tau = 2; tau < halfLen; tau++) {
    if (cmnd[tau] < threshold) {
      // Find the local minimum after crossing threshold
      while (tau + 1 < halfLen && cmnd[tau + 1] < cmnd[tau]) {
        tau++;
      }
      tauEstimate = tau;
      break;
    }
  }

  // No pitch found
  if (tauEstimate == -1) return null;

  // Step 5: Parabolic interpolation for sub-sample accuracy
  double betterTau;
  if (tauEstimate > 0 && tauEstimate < halfLen - 1) {
    final s0 = cmnd[tauEstimate - 1];
    final s1 = cmnd[tauEstimate];
    final s2 = cmnd[tauEstimate + 1];
    final adjustment = (s2 - s0) / (2 * (2 * s1 - s2 - s0));
    betterTau = tauEstimate + (adjustment.isFinite ? adjustment : 0.0);
  } else {
    betterTau = tauEstimate.toDouble();
  }

  return sampleRate / betterTau;
}
