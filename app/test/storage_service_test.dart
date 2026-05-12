import 'package:flutter_test/flutter_test.dart';

import 'package:learn_chinese_by_music/services/storage_service.dart';

class FakeStorageBackend implements StorageBackend {
  final Map<String, Map<String, dynamic>> _progress = {};
  final Map<String, String> _settings = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> saveProgress({
    required String songId,
    required String sentenceScores,
    required double bestScore,
    required int passed,
  }) async {
    _progress[songId] = {
      'song_id': songId,
      'sentence_scores': sentenceScores,
      'best_score': bestScore,
      'passed': passed,
    };
  }

  @override
  Future<Map<String, dynamic>?> getProgress(String songId) async {
    return _progress[songId];
  }

  @override
  Future<List<Map<String, dynamic>>> getAllProgress() async {
    return _progress.values.toList();
  }

  @override
  Future<void> deleteProgress(String songId) async {
    _progress.remove(songId);
  }

  @override
  Future<void> saveSetting(String key, String value) async {
    _settings[key] = value;
  }

  @override
  Future<String?> getSetting(String key) async {
    return _settings[key];
  }
}

void main() {
  group('StorageService', () {
    late StorageService storage;

    setUp(() {
      storage = StorageService(backend: FakeStorageBackend());
    });

    test('save and get progress', () async {
      await storage.saveProgress(
        songId: 'song-1',
        sentenceScores: [85.0, 90.0, 78.5],
        bestScore: 90.0,
        passed: true,
      );

      final progress = await storage.getProgress('song-1');
      expect(progress, isNotNull);
      expect(progress!['song_id'], equals('song-1'));
      expect(progress['best_score'], equals(90.0));
      expect(progress['passed'], equals(1));
    });

    test('update existing progress', () async {
      await storage.saveProgress(
        songId: 'song-1',
        sentenceScores: [60.0],
        bestScore: 60.0,
        passed: false,
      );

      await storage.saveProgress(
        songId: 'song-1',
        sentenceScores: [95.0],
        bestScore: 95.0,
        passed: true,
      );

      final progress = await storage.getProgress('song-1');
      expect(progress!['best_score'], equals(95.0));
      expect(progress['passed'], equals(1));
    });

    test('getAllProgress returns all records', () async {
      await storage.saveProgress(songId: 's1', sentenceScores: [80], bestScore: 80, passed: true);
      await storage.saveProgress(songId: 's2', sentenceScores: [90], bestScore: 90, passed: true);

      final all = await storage.getAllProgress();
      expect(all.length, equals(2));
    });

    test('save and get setting', () async {
      await storage.saveSetting('language', 'en');
      final value = await storage.getSetting('language');
      expect(value, equals('en'));
    });

    test('getSetting returns null for missing key', () async {
      final value = await storage.getSetting('nonexistent');
      expect(value, isNull);
    });

    test('getProgress returns null for missing song', () async {
      final progress = await storage.getProgress('nonexistent');
      expect(progress, isNull);
    });

    test('deleteProgress removes a record', () async {
      await storage.saveProgress(songId: 'song-d', sentenceScores: [70], bestScore: 70, passed: true);
      await storage.deleteProgress('song-d');
      final progress = await storage.getProgress('song-d');
      expect(progress, isNull);
    });
  });
}
