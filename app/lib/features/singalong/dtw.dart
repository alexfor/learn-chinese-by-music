import 'dart:math';

/// Computes a 0-100 similarity score between two pitch curves using DTW.
///
/// Pitch values are in Hz. Null represents unvoiced frames.
/// Score 100 = perfect match, 0 = completely different.
int dtwScore(List<double?> reference, List<double?> test) {
  if (reference.isEmpty || test.isEmpty) return 0;

  final n = reference.length;
  final m = test.length;

  // Cost matrix with DTW dynamic programming
  final cost = List<List<double>>.generate(
    n + 1,
    (_) => List<double>.filled(m + 1, double.infinity),
  );
  cost[0][0] = 0;

  for (int i = 1; i <= n; i++) {
    for (int j = 1; j <= m; j++) {
      final d = _pitchDistance(reference[i - 1], test[j - 1]);
      cost[i][j] = d +
          min(cost[i - 1][j], min(cost[i][j - 1], cost[i - 1][j - 1]));
    }
  }

  final rawCost = cost[n][m];

  // Normalize: worst case is all frames maximally different
  final maxDistance = _maxPitchDistance * max(n, m);
  if (maxDistance == 0) return 100;

  final normalized = rawCost / maxDistance;
  final similarity = 1.0 - normalized.clamp(0.0, 1.0);
  return (similarity * 100).round().clamp(0, 100);
}

/// Distance between two pitch values.
/// Uses cent-based distance for voiced frames.
/// Null (unvoiced) vs voiced incurs a fixed penalty.
const _unvoicedPenalty = 1.0;
const _maxPitchDistance = 1.0;

double _pitchDistance(double? a, double? b) {
  if (a == null && b == null) return 0;
  if (a == null || b == null) return _unvoicedPenalty;

  // Use cent difference: more perceptually meaningful than Hz difference
  if (a! <= 0 || b! <= 0) return _unvoicedPenalty;

  final cents = 1200 * (log(b / a) / ln2).abs();
  // Normalize: 1200 cents (one octave) = max distance of 1.0
  return (cents / 1200).clamp(0.0, _maxPitchDistance);
}
