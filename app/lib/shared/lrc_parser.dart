class LrcLine {
  final int timestampMs;
  final String text;

  const LrcLine({required this.timestampMs, required this.text});
}

class LrcParser {
  static final _timestampRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');

  static List<LrcLine> parse(String lrc) {
    final lines = <LrcLine>[];

    for (final rawLine in lrc.split('\n')) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      final match = _timestampRegex.firstMatch(trimmed);
      if (match == null) continue;

      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      final msRaw = match.group(3)!;
      final milliseconds = msRaw.length == 2
          ? int.parse(msRaw) * 10
          : int.parse(msRaw);

      final text = trimmed.substring(match.end).trim();
      if (text.isEmpty) continue;

      lines.add(LrcLine(
        timestampMs: minutes * 60000 + seconds * 1000 + milliseconds,
        text: text,
      ));
    }

    lines.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
    return lines;
  }

  static int currentLineIndex(List<LrcLine> lines, int positionMs) {
    if (lines.isEmpty) return -1;
    if (positionMs < lines.first.timestampMs) return -1;

    int result = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].timestampMs <= positionMs) {
        result = i;
      } else {
        break;
      }
    }
    return result;
  }
}
