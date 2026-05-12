import '../../shared/lrc_parser.dart';
import 'scoring_engine.dart';

/// Pre-computes reference pitch curves for each lyric line.
///
/// Takes the vocal track audio samples + LRC timestamps and produces
/// a pitch curve per line that can be compared against the user's recording.
class ReferenceProcessor {
  final ScoringEngine _engine;

  ReferenceProcessor({double sampleRate = 16000.0})
      : _engine = ScoringEngine(sampleRate: sampleRate);

  /// Extract pitch curves for each LRC line from vocal audio.
  ///
  /// Returns a list parallel to [lrcLines], where each entry is the
  /// pitch curve (list of Hz or null) for that line's time span.
  List<List<double?>> process(
    List<double> vocalSamples,
    List<LrcLine> lrcLines,
  ) {
    if (lrcLines.isEmpty) return [];

    final curves = <List<double?>>[];

    for (int i = 0; i < lrcLines.length; i++) {
      final startMs = lrcLines[i].timestampMs;
      final endMs = (i + 1 < lrcLines.length)
          ? lrcLines[i + 1].timestampMs
          : startMs + 5000; // default 5s for last line

      final startSample = _msToSample(startMs);
      final endSample = _msToSample(endMs);

      if (startSample >= vocalSamples.length) {
        curves.add([]);
        continue;
      }

      final sliceEnd = endSample.clamp(0, vocalSamples.length);
      final slice = vocalSamples.sublist(startSample, sliceEnd);

      final curve = _engine.extractPitchCurve(slice);
      curves.add(curve);
    }

    return curves;
  }

  int _msToSample(int ms) => (ms * _engine.sampleRate / 1000).round();
}
