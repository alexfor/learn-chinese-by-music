import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized before use');
});

/// Low-level database interface (swappable for testing).
abstract class StorageBackend {
  Future<void> init();
  Future<void> close();
  Future<void> saveProgress({
    required String songId,
    required String sentenceScores,
    required double bestScore,
    required int passed,
  });
  Future<Map<String, dynamic>?> getProgress(String songId);
  Future<List<Map<String, dynamic>>> getAllProgress();
  Future<void> deleteProgress(String songId);
  Future<void> saveSetting(String key, String value);
  Future<String?> getSetting(String key);
}

/// sqflite-based implementation of [StorageBackend].
class SqfliteStorageBackend implements StorageBackend {
  Database? _db;

  @override
  Future<void> init() async {
    _db = await openDatabase(
      'learn_chinese.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS cached_progress (
            song_id TEXT PRIMARY KEY,
            sentence_scores TEXT NOT NULL,
            best_score REAL NOT NULL,
            passed INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT DEFAULT (datetime('now'))
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Database get _database {
    if (_db == null) throw StateError('StorageService not initialized');
    return _db!;
  }

  @override
  Future<void> saveProgress({
    required String songId,
    required String sentenceScores,
    required double bestScore,
    required int passed,
  }) async {
    await _database.insert(
      'cached_progress',
      {
        'song_id': songId,
        'sentence_scores': sentenceScores,
        'best_score': bestScore,
        'passed': passed,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Map<String, dynamic>?> getProgress(String songId) async {
    final results = await _database.query(
      'cached_progress',
      where: 'song_id = ?',
      whereArgs: [songId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getAllProgress() async {
    return _database.query('cached_progress');
  }

  @override
  Future<void> deleteProgress(String songId) async {
    await _database.delete(
      'cached_progress',
      where: 'song_id = ?',
      whereArgs: [songId],
    );
  }

  @override
  Future<void> saveSetting(String key, String value) async {
    await _database.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<String?> getSetting(String key) async {
    final results = await _database.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return results.isNotEmpty ? results.first['value'] as String : null;
  }
}

/// High-level storage service that serializes/deserializes data.
class StorageService {
  final StorageBackend _backend;

  StorageService({StorageBackend? backend})
      : _backend = backend ?? SqfliteStorageBackend();

  Future<void> init() => _backend.init();
  Future<void> close() => _backend.close();

  Future<void> saveProgress({
    required String songId,
    required List<double> sentenceScores,
    required double bestScore,
    required bool passed,
  }) async {
    await _backend.saveProgress(
      songId: songId,
      sentenceScores: jsonEncode(sentenceScores),
      bestScore: bestScore,
      passed: passed ? 1 : 0,
    );
  }

  Future<Map<String, dynamic>?> getProgress(String songId) async {
    final raw = await _backend.getProgress(songId);
    if (raw == null) return null;
    return {
      ...raw,
      'sentence_scores': jsonDecode(raw['sentence_scores'] as String) as List<dynamic>,
    };
  }

  Future<List<Map<String, dynamic>>> getAllProgress() async {
    final rawList = await _backend.getAllProgress();
    return rawList.map((raw) {
      return {
        ...raw,
        'sentence_scores': jsonDecode(raw['sentence_scores'] as String) as List<dynamic>,
      };
    }).toList();
  }

  Future<void> deleteProgress(String songId) async {
    await _backend.deleteProgress(songId);
  }

  Future<void> saveSetting(String key, String value) async {
    await _backend.saveSetting(key, value);
  }

  Future<String?> getSetting(String key) async {
    return _backend.getSetting(key);
  }
}
