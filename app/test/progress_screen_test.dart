import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learn_chinese_by_music/features/progress/progress_screen.dart';
import 'package:learn_chinese_by_music/services/storage_service.dart';
import 'package:learn_chinese_by_music/services/connectivity_service.dart';

class FakeStorageBackend implements StorageBackend {
  final Map<String, Map<String, dynamic>> _progress = {};

  @override Future<void> init() async {}
  @override Future<void> close() async {}

  @override
  Future<void> saveProgress({
    required String songId, required String sentenceScores,
    required double bestScore, required int passed,
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

  @override Future<void> deleteProgress(String songId) async { _progress.remove(songId); }
  @override Future<void> saveSetting(String key, String value) async {}
  @override Future<String?> getSetting(String key) async => null;
}

class FakeConnectivity implements ConnectivityChecker {
  @override Future<bool> checkConnectivity() async => true;
  @override Stream<bool> get connectivityStream => Stream.value(true);
}

void main() {
  testWidgets('Progress screen shows empty state', (WidgetTester tester) async {
    final storage = StorageService(backend: FakeStorageBackend());
    final connectivity = FakeConnectivity();

    await tester.pumpWidget(
      ProviderScope(overrides: [
        storageServiceProvider.overrideWithValue(storage),
        connectivityServiceProvider.overrideWithValue(connectivity),
      ], child: const MaterialApp(home: ProgressScreen())),
    );
    await tester.pump();

    expect(find.text('My Progress'), findsOneWidget);
  });

  testWidgets('Progress screen shows records', (WidgetTester tester) async {
    final backend = FakeStorageBackend();
    await backend.saveProgress(
      songId: 'song-1', sentenceScores: '[85,90]',
      bestScore: 90.0, passed: 1,
    );

    final storage = StorageService(backend: backend);
    final connectivity = FakeConnectivity();

    await tester.pumpWidget(
      ProviderScope(overrides: [
        storageServiceProvider.overrideWithValue(storage),
        connectivityServiceProvider.overrideWithValue(connectivity),
      ], child: const MaterialApp(home: ProgressScreen())),
    );

    // Allow async getAllSavedProgress to complete
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('90 pts'), findsOneWidget);
  });
}
