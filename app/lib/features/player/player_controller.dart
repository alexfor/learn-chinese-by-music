import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/lrc_parser.dart';
import '../../services/audio_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) => AudioService());

class PlayerControllerLogic {
  List<LrcLine> _lines = [];
  int _currentLineIndex = -1;

  int get currentLineIndex => _currentLineIndex;

  void setLrcLines(List<LrcLine> lines) {
    _lines = lines;
    _currentLineIndex = -1;
  }

  void updatePosition(int positionMs) {
    _currentLineIndex = LrcParser.currentLineIndex(_lines, positionMs);
  }

  int? seekTargetMs(int lineIndex) {
    if (lineIndex < 0 || lineIndex >= _lines.length) return null;
    return _lines[lineIndex].timestampMs;
  }
}

final playerControllerProvider =
    NotifierProvider<PlayerControllerNotifier, PlayerControllerLogic>(
  PlayerControllerNotifier.new,
);

class PlayerControllerNotifier extends Notifier<PlayerControllerLogic> {
  @override
  PlayerControllerLogic build() {
    return PlayerControllerLogic();
  }

  void setLrcLines(List<LrcLine> lines) => state.setLrcLines(lines);

  void updatePosition(int positionMs) => state.updatePosition(positionMs);

  Future<void> play() => ref.read(audioServiceProvider).play();

  Future<void> pause() => ref.read(audioServiceProvider).pause();

  Future<void> seekToLine(int lineIndex) async {
    final target = state.seekTargetMs(lineIndex);
    if (target != null) {
      await ref.read(audioServiceProvider).seek(Duration(milliseconds: target));
    }
  }
}
