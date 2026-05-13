import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learn_chinese_by_music/services/api_service.dart';
import 'package:learn_chinese_by_music/features/community/community_models.dart';
import 'package:learn_chinese_by_music/features/community/community_providers.dart';

class FakeCommunityApi extends ApiService {
  FakeCommunityApi() : super();

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final ro = RequestOptions(path: path);
    if (path == '/api/community/posts' || path.startsWith('/api/community/posts?')) {
      return Response(
        requestOptions: ro,
        data: [
          {
            'id': 'post-1',
            'user_id': 'user-1',
            'nickname': 'Alice',
            'song_id': 'song-1',
            'title': 'Great song!',
            'audio_url': null,
            'likes': 5,
            'liked_by_me': false,
            'created_at': '2026-05-13T10:00:00Z',
          },
          {
            'id': 'post-2',
            'user_id': 'user-2',
            'nickname': 'Bob',
            'song_id': 'song-1',
            'title': 'My first cover',
            'audio_url': 'https://example.com/audio.wav',
            'likes': 3,
            'liked_by_me': true,
            'created_at': '2026-05-12T10:00:00Z',
          },
        ],
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
  group('CommunityModels', () {
    test('CommunityPost.fromJson parses correctly', () {
      final post = CommunityPost.fromJson({
        'id': 'post-1',
        'user_id': 'user-1',
        'nickname': 'Alice',
        'song_id': 'song-1',
        'title': 'Great song!',
        'audio_url': null,
        'likes': 5,
        'liked_by_me': false,
        'created_at': '2026-05-13T10:00:00Z',
      });

      expect(post.id, 'post-1');
      expect(post.nickname, 'Alice');
      expect(post.likes, 5);
      expect(post.likedByMe, false);
    });

    test('CommunityPost.fromJson parses liked post', () {
      final post = CommunityPost.fromJson({
        'id': 'post-2',
        'user_id': 'user-2',
        'nickname': 'Bob',
        'song_id': 'song-1',
        'title': 'My first cover',
        'audio_url': 'https://example.com/audio.wav',
        'likes': 3,
        'liked_by_me': true,
        'created_at': '2026-05-12T10:00:00Z',
      });

      expect(post.likedByMe, true);
      expect(post.audioUrl, 'https://example.com/audio.wav');
    });
  });

  group('CommunityProviders', () {
    test('communityListProvider returns list of posts', () async {
      final container = ProviderContainer(overrides: [
        apiProvider.overrideWithValue(FakeCommunityApi()),
      ]);

      final posts = await container.read(communityListProvider.future);

      expect(posts.length, 2);
      expect(posts[0].title, 'Great song!');
      expect(posts[0].likes, 5);
      expect(posts[1].likedByMe, true);

      container.dispose();
    });
  });
}
