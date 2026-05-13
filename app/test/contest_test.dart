import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learn_chinese_by_music/services/api_service.dart';
import 'package:learn_chinese_by_music/features/contest/contest_models.dart';
import 'package:learn_chinese_by_music/features/contest/contest_providers.dart';

class FakeContestApi extends ApiService {
  FakeContestApi() : super();

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final ro = RequestOptions(path: path);
    if (path == '/api/contests') {
      return Response(
        requestOptions: ro,
        data: [
          {
            'id': 'contest-1',
            'title': 'Weekly Contest',
            'song_ids': ['song-1', 'song-2'],
            'start_date': '2026-05-11',
            'end_date': '2026-05-18',
            'status': 'active',
            'created_at': '2026-05-10T00:00:00Z',
          },
          {
            'id': 'contest-2',
            'title': 'Upcoming Contest',
            'song_ids': ['song-3'],
            'start_date': '2026-05-25',
            'end_date': '2026-06-01',
            'status': 'upcoming',
            'created_at': '2026-05-12T00:00:00Z',
          },
        ],
        statusCode: 200,
      );
    }
    if (path == '/api/contests/contest-1') {
      return Response(
        requestOptions: ro,
        data: {
          'id': 'contest-1',
          'title': 'Weekly Contest',
          'song_ids': ['song-1', 'song-2'],
          'start_date': '2026-05-11',
          'end_date': '2026-05-18',
          'status': 'active',
          'created_at': '2026-05-10T00:00:00Z',
          'entries': [
            {'rank': 1, 'user_id': 'user-2', 'nickname': 'Alice', 'song_id': 'song-1', 'score': 95.0},
            {'rank': 2, 'user_id': 'user-1', 'nickname': 'Bob', 'song_id': 'song-1', 'score': 80.0},
          ],
        },
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
  group('ContestModels', () {
    test('ContestSummary.fromJson parses correctly', () {
      final summary = ContestSummary.fromJson({
        'id': 'contest-1',
        'title': 'Weekly Contest',
        'song_ids': ['song-1', 'song-2'],
        'start_date': '2026-05-11',
        'end_date': '2026-05-18',
        'status': 'active',
        'created_at': '2026-05-10T00:00:00Z',
      });

      expect(summary.id, 'contest-1');
      expect(summary.title, 'Weekly Contest');
      expect(summary.songIds, ['song-1', 'song-2']);
      expect(summary.status, 'active');
    });

    test('ContestEntry.fromJson parses correctly', () {
      final entry = ContestEntry.fromJson({
        'rank': 1,
        'user_id': 'u-1',
        'nickname': 'Alice',
        'song_id': 'song-1',
        'score': 95.0,
      });

      expect(entry.rank, 1);
      expect(entry.userId, 'u-1');
      expect(entry.nickname, 'Alice');
      expect(entry.score, 95.0);
    });
  });

  group('ContestProviders', () {
    test('contestListProvider returns list of contests', () async {
      final container = ProviderContainer(overrides: [
        apiProvider.overrideWithValue(FakeContestApi()),
      ]);

      final contests = await container.read(contestListProvider.future);

      expect(contests.length, 2);
      expect(contests[0].title, 'Weekly Contest');
      expect(contests[0].status, 'active');
      expect(contests[1].status, 'upcoming');

      container.dispose();
    });

    test('contestDetailProvider returns contest with entries', () async {
      final container = ProviderContainer(overrides: [
        apiProvider.overrideWithValue(FakeContestApi()),
      ]);

      final detail = await container.read(
        contestDetailProvider('contest-1').future,
      );

      expect(detail.id, 'contest-1');
      expect(detail.entries.length, 2);
      expect(detail.entries[0].score, 95.0);
      expect(detail.entries[0].nickname, 'Alice');

      container.dispose();
    });
  });
}
