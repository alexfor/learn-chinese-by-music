import 'dart:io';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

enum RecorderState { idle, recording, paused }

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  RecorderState _state = RecorderState.idle;

  RecorderState get state => _state;
  bool get isRecording => _state == RecorderState.recording;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> start() async {
    if (_state == RecorderState.recording) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/singalong_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
      path: path,
    );
    _state = RecorderState.recording;
  }

  Future<String?> stop() async {
    if (_state == RecorderState.idle) return null;
    final path = await _recorder.stop();
    _state = RecorderState.idle;
    return path;
  }

  Future<void> pause() async {
    if (_state != RecorderState.recording) return;
    await _recorder.pause();
    _state = RecorderState.paused;
  }

  Future<void> resume() async {
    if (_state != RecorderState.paused) return;
    await _recorder.resume();
    _state = RecorderState.recording;
  }

  Future<void> cancel() async {
    await _recorder.cancel();
    _state = RecorderState.idle;
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }

  /// Read a WAV file and return raw PCM samples as Float64 list.
  /// Assumes 16-bit mono WAV.
  static Future<Float64List> readWavPcm(String path) async {
    final bytes = await File(path).readAsBytes();
    final dataOffset = _findDataChunk(bytes);
    final samples = Float64List((bytes.length - dataOffset) ~/ 2);
    final data = bytes.buffer.asByteData(dataOffset, samples.length * 2);
    for (int i = 0; i < samples.length; i++) {
      final intSample = data.getInt16(i * 2, Endian.little);
      samples[i] = intSample / 32768.0;
    }
    return samples;
  }

  static int _findDataChunk(Uint8List bytes) {
    for (int i = 0; i < bytes.length - 4; i++) {
      if (bytes[i] == 0x64 && bytes[i + 1] == 0x61 &&
          bytes[i + 2] == 0x74 && bytes[i + 3] == 0x61) {
        return i + 8;
      }
    }
    return 44;
  }
}
