import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  Duration? get duration => _player.duration;
  Duration get position => _player.position;
  bool get isPlaying => _player.playing;

  Future<void> setUrl(String url) async {
    await _player.setUrl(url);
  }

  Future<void> setLocalFile(String filePath) async {
    await _player.setFilePath(filePath);
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}
