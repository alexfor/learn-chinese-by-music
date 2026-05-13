import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learn_chinese_by_music/services/api_service.dart';
import 'package:learn_chinese_by_music/features/gamification/gamification_models.dart';
import 'package:learn_chinese_by_music/features/gamification/gamification_providers.dart';

class FakeStreakApi extends ApiService {
  FakeStreakApi() : super();

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final ro = RequestOptions(path: path);
    if (path == '/api/streak') {
      return Response(
        requestOptions: ro,
        data: {
          'current_streak': 5,
          'longest_streak': 7,
          'last_checkin': '2026-05-13T10:00:00Z',
          'checked_in_today': true,
        },
        statusCode: 200,
      );
    }
    if (path == '/api/achievements') {
      return Response(
        requestOptions: ro,
        data: [
          {
            'id': 'ach-1',
            'achievement_key': 'first_singalong',
            'unlocked_at': '2026-05-10T10:00:00Z',
            'title': 'First Singalong',
            'description': 'Complete your first singalong session',
          },
        ],
        statusCode: 200,
      );
    }
    if (path == '/api/achievements/definitions') {
      return Response(
        requestOptions: ro,
        data: [
          {
            'key': 'first_singalong',
            'title': 'First Singalong',
            'description': 'Complete your first singalong session',
            'icon': 'mic',
          },
          {
            'key': 'perfect_score',
            'title': 'Perfect Score',
            'description': 'Get a score of 100 on any song',
            'icon': 'emoji_events',
          },
        ],
        statusCode: 200,
      );
    }
    throw Exception('Unexpected path: $path');
  }

  @override
  Future<Response> post(String path, {dynamic data}) async {
    final ro = RequestOptions(path: path);
    if (path == '/api/streak/checkin') {
      return Response(
        requestOptions: ro,
        data: {
          'current_streak': 6,
          'longest_streak': 7,
          'last_checkin': '2026-05-13T10:00:00Z',
          'checked_in_today': true,
        },
        statusCode: 200,
      );
    }
    throw Exception('Unexpected path: $path');
  }

  @override
  Future<Response> put(String path, {dynamic data}) =>
      throw UnimplementedError();

  @override
  Future<Response> delete(String path) => throw UnimplementedError();
}

class FakeEmptyAchievementsApi extends ApiService {
  FakeEmptyAchievementsApi() : super();

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final ro = RequestOptions(path: path);
    if (path == '/api/streak') {
      return Response(
        requestOptions: ro,
        data: {
          'current_streak': 0,
          'longest_streak': 0,
          'last_checkin': null,
          'checked_in_today': false,
        },
        statusCode: 200,
      );
    }
    if (path == '/api/achievements') {
      return Response(
        requestOptions: ro,
        data: [],
        statusCode: 200,
      );
    }
    if (path == '/api/achievements/definitions') {
      return Response(
        requestOptions: ro,
        data: [],
        statusCode: 200,
      );
    }
    throw Exception('Unexpected path: $path');
  }

  @override
  Future<Response> post(String path, {dynamic data}) =>
      throw UnimplementedError();

  @override
  Future<Response> put(String path, {dynamic data}) =>
      throw UnimplementedError();

  @override
  Future<Response> delete(String path) => throw UnimplementedError();
}

class FakeErrorApi extends ApiService {
  FakeErrorApi() : super();

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    throw DioException(
      requestOptions: RequestOptions(path: path),
      error: 'Network error',
    );
  }

  @override
  Future<Response> post(String path, {dynamic data}) =>
      throw UnimplementedError();

  @override
  Future<Response> put(String path, {dynamic data}) =>
      throw UnimplementedError();

  @override
  Future<Response> delete(String path) => throw UnimplementedError();
}

void main() {
  group('StreakInfo', () {
    test('fromJson parses correctly', () {
      final info = StreakInfo.fromJson({
        'current_streak': 5,
        'longest_streak': 7,
        'last_checkin': '2026-05-13T10:00:00Z',
        'checked_in_today': true,
      });

      expect(info.currentStreak, 5);
      expect(info.longestStreak, 7);
      expect(info.checkedInToday, true);
    });

    test('fromJson handles empty', () {
      final info = StreakInfo.fromJson({});
      expect(info.currentStreak, 0);
      expect(info.longestStreak, 0);
      expect(info.checkedInToday, false);
    });
  });

  group('Achievement', () {
    test('fromJson parses correctly', () {
      final ach = Achievement.fromJson({
        'id': 'ach-1',
        'achievement_key': 'first_singalong',
        'unlocked_at': '2026-05-10T10:00:00Z',
        'title': 'First Singalong',
        'description': 'desc',
      });

      expect(ach.achievementKey, 'first_singalong');
      expect(ach.title, 'First Singalong');
    });
  });

  group('AchievementDefinition', () {
    test('fromJson parses correctly', () {
      final def = AchievementDefinition.fromJson({
        'key': 'first_singalong',
        'title': 'First Singalong',
        'description': 'desc',
        'icon': 'mic',
      });

      expect(def.key, 'first_singalong');
      expect(def.icon, 'mic');
    });

    test('fromJson uses default icon', () {
      final def = AchievementDefinition.fromJson({
        'key': 'test',
        'title': 'Test',
        'description': 'desc',
      });

      expect(def.icon, 'emoji_events');
    });
  });

  group('streakProvider', () {
    test('returns streak info', () async {
      final container = ProviderContainer(overrides: [
        apiProvider.overrideWithValue(FakeStreakApi()),
      ]);

      final info = await container.read(streakProvider.future);
      expect(info.currentStreak, 5);
      expect(info.longestStreak, 7);
      expect(info.checkedInToday, true);

      container.dispose();
    });

    test('returns default on error', () async {
      final container = ProviderContainer(overrides: [
        apiProvider.overrideWithValue(FakeErrorApi()),
      ]);

      final info = await container.read(streakProvider.future);
      expect(info.currentStreak, 0);
      expect(info.checkedInToday, false);

      container.dispose();
    });
  });

  group('achievementsProvider', () {
    test('returns list of achievements', () async {
      final container = ProviderContainer(overrides: [
        apiProvider.overrideWithValue(FakeStreakApi()),
      ]);

      final achievements = await container.read(achievementsProvider.future);
      expect(achievements.length, 1);
      expect(achievements[0].achievementKey, 'first_singalong');

      container.dispose();
    });
  });

  group('achievementDefinitionsProvider', () {
    test('returns list of definitions', () async {
      final container = ProviderContainer(overrides: [
        apiProvider.overrideWithValue(FakeStreakApi()),
      ]);

      final defs =
          await container.read(achievementDefinitionsProvider.future);
      expect(defs.length, 2);
      expect(defs[0].key, 'first_singalong');

      container.dispose();
    });

    test('returns empty list on error', () async {
      final container = ProviderContainer(overrides: [
        apiProvider.overrideWithValue(FakeErrorApi()),
      ]);

      final defs =
          await container.read(achievementDefinitionsProvider.future);
      expect(defs, isEmpty);

      container.dispose();
    });
  });
}
