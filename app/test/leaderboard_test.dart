import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learn_chinese_by_music/services/api_service.dart';
import 'package:learn_chinese_by_music/features/leaderboard/leaderboard_provider.dart';
import 'package:learn_chinese_by_music/features/leaderboard/leaderboard_models.dart';

class FakeApiService extends ApiService {
  FakeApiService() : super();

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final requestOptions = RequestOptions(path: path);
    if (path == '/api/leaderboard/songs/song-1') {
      return Response(
        requestOptions: requestOptions,
        data: {
          'song_id': 'song-1',
          'entries': [
            {'rank': 1, 'user_id': 'user-2', 'nickname': 'Alice', 'score': 95.0, 'attempts': 3},
            {'rank': 2, 'user_id': 'user-1', 'nickname': 'Bob', 'score': 88.0, 'attempts': 5},
          ],
        },
        statusCode: 200,
      );
    }
    if (path == '/api/leaderboard/songs/song-1/me') {
      return Response(
        requestOptions: requestOptions,
        data: {'rank': 2, 'score': 88.0, 'attempts': 5},
        statusCode: 200,
      );
    }
    if (path == '/api/leaderboard/songs/song-empty') {
      return Response(
        requestOptions: requestOptions,
        data: {'song_id': 'song-empty', 'entries': []},
        statusCode: 200,
      );
    }
    if (path == '/api/leaderboard/songs/song-empty/me') {
      return Response(
        requestOptions: requestOptions,
        data: {'rank': 0, 'score': 0.0, 'attempts': 0},
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

void main() {
  group('LeaderboardProvider', () {
    test('returns leaderboard entries sorted by score', () async {
      final container = ProviderContainer(overrides: [
        apiProvider.overrideWithValue(FakeApiService()),
      ]);

      final asyncData = await container.read(
        leaderboardProvider('song-1').future,
      );

      expect(asyncData.songId, 'song-1');
      expect(asyncData.entries.length, 2);
      expect(asyncData.entries[0].score, 95.0);
      expect(asyncData.entries[0].nickname, 'Alice');
      expect(asyncData.entries[1].score, 88.0);
      expect(asyncData.entries[1].nickname, 'Bob');

      expect(asyncData.myRank, isNotNull);
      expect(asyncData.myRank!.rank, 2);
      expect(asyncData.myRank!.score, 88.0);

      container.dispose();
    });

    test('returns empty entries when no scores', () async {
      final container = ProviderContainer(overrides: [
        apiProvider.overrideWithValue(FakeApiService()),
      ]);

      final asyncData = await container.read(
        leaderboardProvider('song-empty').future,
      );

      expect(asyncData.songId, 'song-empty');
      expect(asyncData.entries, isEmpty);
      expect(asyncData.myRank, isNull);

      container.dispose();
    });
  });

  group('LeaderboardEntry', () {
    test('fromJson parses correctly', () {
      final entry = LeaderboardEntry.fromJson({
        'rank': 1,
        'user_id': 'u-1',
        'nickname': 'Test',
        'score': 90.5,
        'attempts': 3,
      });

      expect(entry.rank, 1);
      expect(entry.userId, 'u-1');
      expect(entry.nickname, 'Test');
      expect(entry.score, 90.5);
      expect(entry.attempts, 3);
    });
  });

  group('MyRank', () {
    test('fromJson parses correctly', () {
      final rank = MyRank.fromJson({
        'rank': 3,
        'score': 85.0,
        'attempts': 2,
      });

      expect(rank.rank, 3);
      expect(rank.score, 85.0);
      expect(rank.attempts, 2);
    });
  });
}
