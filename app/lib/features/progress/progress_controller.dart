import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/storage_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/api_service.dart';

class ProgressRecord {
  final String songId;
  final List<double> sentenceScores;
  final double bestScore;
  final bool passed;

  const ProgressRecord({
    required this.songId,
    required this.sentenceScores,
    required this.bestScore,
    required this.passed,
  });
}

class ProgressState {
  final Map<String, ProgressRecord> records;
  final bool isSyncing;

  const ProgressState({this.records = const {}, this.isSyncing = false});
}

final progressControllerProvider =
    NotifierProvider<ProgressController, ProgressState>(
  ProgressController.new,
);

class ProgressController extends Notifier<ProgressState> {
  @override
  ProgressState build() => const ProgressState();

  Future<void> saveSongProgress({
    required String songId,
    required List<double> sentenceScores,
    required double bestScore,
    required bool passed,
  }) async {
    final storage = ref.read(storageServiceProvider);

    await storage.saveProgress(
      songId: songId,
      sentenceScores: sentenceScores,
      bestScore: bestScore,
      passed: passed,
    );

    final record = ProgressRecord(
      songId: songId,
      sentenceScores: sentenceScores,
      bestScore: bestScore,
      passed: passed,
    );

    state = ProgressState(
      records: {...state.records, songId: record},
      isSyncing: state.isSyncing,
    );

    // Try to sync if online
    final connectivity = ref.read(connectivityServiceProvider);
    final isOnline = await connectivity.checkConnectivity();
    if (isOnline) {
      await _syncSingleSong(songId, record);
    }
  }

  Future<ProgressRecord?> loadProgress(String songId) async {
    final storage = ref.read(storageServiceProvider);
    final raw = await storage.getProgress(songId);
    if (raw == null) return null;

    final record = ProgressRecord(
      songId: raw['song_id'] as String,
      sentenceScores: (raw['sentence_scores'] as List<dynamic>).cast<double>(),
      bestScore: (raw['best_score'] as num).toDouble(),
      passed: raw['passed'] == 1,
    );

    state = ProgressState(
      records: {...state.records, songId: record},
      isSyncing: state.isSyncing,
    );

    return record;
  }

  Future<List<ProgressRecord>> getAllSavedProgress() async {
    final storage = ref.read(storageServiceProvider);
    final rawList = await storage.getAllProgress();

    final records = rawList.map((raw) {
      return ProgressRecord(
        songId: raw['song_id'] as String,
        sentenceScores: (raw['sentence_scores'] as List<dynamic>)
            .cast<double>(),
        bestScore: (raw['best_score'] as num).toDouble(),
        passed: raw['passed'] == 1,
      );
    }).toList();

    final recordMap = {for (final r in records) r.songId: r};
    state = ProgressState(
      records: recordMap,
      isSyncing: state.isSyncing,
    );

    return records;
  }

  Future<void> syncPendingProgress() async {
    final connectivity = ref.read(connectivityServiceProvider);
    final isOnline = await connectivity.checkConnectivity();
    if (!isOnline) return;

    state = ProgressState(records: state.records, isSyncing: true);

    try {
      final storage = ref.read(storageServiceProvider);
      final rawList = await storage.getAllProgress();

      for (final raw in rawList) {
        final songId = raw['song_id'] as String;
        final record = ProgressRecord(
          songId: songId,
          sentenceScores:
              (raw['sentence_scores'] as List<dynamic>).cast<double>(),
          bestScore: (raw['best_score'] as num).toDouble(),
          passed: raw['passed'] == 1,
        );
        await _syncSingleSong(songId, record);
      }
    } finally {
      state = ProgressState(records: state.records, isSyncing: false);
    }
  }

  Future<void> _syncSingleSong(String songId, ProgressRecord record) async {
    try {
      final api = ref.read(apiProvider);
      await api.post('/api/progress/sync', data: {
        'song_id': songId,
        'sentence_scores': record.sentenceScores,
        'best_score': record.bestScore,
        'passed': record.passed,
      });
    } catch (_) {
      // Will retry on next syncPendingProgress call
    }
  }
}
