import '../../shared/lrc_parser.dart';
import '../../services/audio_service.dart';
import 'audio_recorder.dart';
import 'reference_processor.dart';
import 'scoring_engine.dart';

enum SingalongState { idle, recording, paused, completed }

class LineScore {
  final int lineIndex;
  final int score;
  final String text;

  const LineScore({required this.lineIndex, required this.score, required this.text});
}

class ScoringPipeline {
  final AudioService _audioService;
  final AudioRecorderService _recorder;
  final ReferenceProcessor _refProcessor;
  final ScoringEngine _engine;

  SingalongState _state = SingalongState.idle;
  final List<LineScore> _lineScores = [];
  List<LrcLine> _lrcLines = [];
  List<List<double?>> _refCurves = [];
  String? _recordingPath;
  int _currentLineIndex = -1;

  SingalongState get state => _state;
  List<LineScore> get lineScores => List.unmodifiable(_lineScores);
  int get currentLineIndex => _currentLineIndex;
  String? get recordingPath => _recordingPath;

  int get totalScore {
    if (_lineScores.isEmpty) return 0;
    return (_lineScores.map((s) => s.score).reduce((a, b) => a + b) /
            _lineScores.length)
        .round();
  }

  ScoringPipeline({
    required AudioService audioService,
    required AudioRecorderService recorder,
    double sampleRate = 16000.0,
  })  : _audioService = audioService,
        _recorder = recorder,
        _refProcessor = ReferenceProcessor(sampleRate: sampleRate),
        _engine = ScoringEngine(sampleRate: sampleRate);

  /// Configure the pipeline with LRC data and reference audio.
  void configure(List<LrcLine> lrcLines, List<double> vocalSamples) {
    _lrcLines = lrcLines;
    _refCurves = _refProcessor.process(vocalSamples, lrcLines);
    _lineScores.clear();
    _currentLineIndex = -1;
  }

  /// Start singalong: play accompaniment and begin recording.
  Future<void> start(String accompanimentUrl) async {
    if (_state == SingalongState.recording) return;

    await _audioService.setUrl(accompanimentUrl);
    await _recorder.start();
    await _audioService.play();
    _state = SingalongState.recording;
  }

  /// Update position from audio stream — checks if a line has ended.
  void onPositionUpdate(int positionMs) {
    if (_state != SingalongState.recording) return;

    final newIndex = LrcParser.currentLineIndex(_lrcLines, positionMs);
    if (newIndex != _currentLineIndex && newIndex >= 0) {
      // Score the previous line when we move past it
      if (_currentLineIndex >= 0 && _currentLineIndex < _refCurves.length) {
        _scoreLine(_currentLineIndex);
      }
      _currentLineIndex = newIndex;
    }
  }

  /// Pause recording and accompaniment.
  Future<void> pause() async {
    if (_state != SingalongState.recording) return;
    await _audioService.pause();
    await _recorder.pause();
    _state = SingalongState.paused;
  }

  /// Resume after pause.
  Future<void> resume() async {
    if (_state != SingalongState.paused) return;
    await _recorder.resume();
    await _audioService.play();
    _state = SingalongState.recording;
  }

  /// Stop singalong: score remaining lines, stop recording.
  Future<void> stop() async {
    // Score any remaining lines
    if (_currentLineIndex >= 0 && _currentLineIndex < _refCurves.length) {
      _scoreLine(_currentLineIndex);
    }
    // Score any lines we haven't reached (as 0)
    for (int i = _lineScores.length; i < _refCurves.length; i++) {
      _lineScores.add(LineScore(
        lineIndex: i,
        score: 0,
        text: i < _lrcLines.length ? _lrcLines[i].text : '',
      ));
    }

    _recordingPath = await _recorder.stop();
    await _audioService.stop();
    _state = SingalongState.completed;
  }

  void _scoreLine(int lineIndex) {
    if (lineIndex >= _refCurves.length) return;

    final refCurve = _refCurves[lineIndex];
    // In a full implementation, we'd slice the user recording for this line.
    // For now, score against a placeholder — the actual recording slicing
    // will be done when we have real audio pipeline integration.
    final score = refCurve.isEmpty ? 0 : _engine.score(refCurve, refCurve);
    _lineScores.add(LineScore(
      lineIndex: lineIndex,
      score: score,
      text: lineIndex < _lrcLines.length ? _lrcLines[lineIndex].text : '',
    ));
  }
}
