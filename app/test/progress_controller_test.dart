import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learn_chinese_by_music/services/storage_service.dart';
import 'package:learn_chinese_by_music/services/connectivity_service.dart';
import 'package:learn_chinese_by_music/features/progress/progress_controller.dart';

class FakeStorageBackend implements StorageBackend {
  final Map<String, Map<String, dynamic>> _progress = {};
  final Map<String, String> _settings = {};
  int saveCallCount = 0;

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
    saveCallCount++;
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

class FakeConnectivity implements ConnectivityChecker {
  bool connected = true;

  @override
  Future<bool> checkConnectivity() async => connected;

  @override
  Stream<bool> get connectivityStream => Stream.value(connected);
}

void main() {
  group('ProgressController', () {
    late FakeStorageBackend fakeBackend;
    late StorageService storage;
    late FakeConnectivity fakeConnectivity;
    late ProviderContainer container;

    setUp(() {
      fakeBackend = FakeStorageBackend();
      storage = StorageService(backend: fakeBackend);
      fakeConnectivity = FakeConnectivity();
      // No real API calls expected in these tests — set offline to avoid sync
      fakeConnectivity.connected = false;

      container = ProviderContainer(overrides: [
        storageServiceProvider.overrideWithValue(storage),
        connectivityServiceProvider.overrideWithValue(fakeConnectivity),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    test('saveProgress records a new score', () async {
      final notifier = container.read(progressControllerProvider.notifier);
      await notifier.saveSongProgress(
        songId: 'song-1',
        sentenceScores: [85.0, 92.0],
        bestScore: 92.0,
        passed: true,
      );

      final progress = await storage.getProgress('song-1');
      expect(progress, isNotNull);
      expect(progress!['best_score'], equals(92.0));
      expect(fakeBackend.saveCallCount, equals(1));
    });

    test('loadProgress loads from storage into state', () async {
      await storage.saveProgress(
        songId: 'song-1',
        sentenceScores: [75.0],
        bestScore: 75.0,
        passed: false,
      );

      final notifier = container.read(progressControllerProvider.notifier);
      final state = await notifier.loadProgress('song-1');

      expect(state, isNotNull);
      expect(state!.bestScore, equals(75.0));
    });

    test('getAllSavedProgress returns list of saved songs', () async {
      await storage.saveProgress(songId: 's1', sentenceScores: [80], bestScore: 80, passed: true);
      await storage.saveProgress(songId: 's2', sentenceScores: [90], bestScore: 90, passed: true);

      final notifier = container.read(progressControllerProvider.notifier);
      final list = await notifier.getAllSavedProgress();

      expect(list.length, equals(2));
    });
  });
}
