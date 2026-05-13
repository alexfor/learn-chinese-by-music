import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';
import 'community_models.dart';
import 'community_providers.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPosts = ref.watch(communityListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: asyncPosts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Failed to load community posts',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(communityListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (posts) => posts.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No posts yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Sing a song and share your recording!',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(communityListProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) =>
                      _PostCard(post: posts[index]),
                ),
              ),
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final CommunityPost post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    post.nickname.isNotEmpty
                        ? post.nickname[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.nickname,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(post.title,
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _toggleLike(ref),
                  child: Row(
                    children: [
                      Icon(
                        post.likedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: post.likedByMe ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text('${post.likes}'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(WidgetRef ref) async {
    try {
      final api = ref.read(apiProvider);
      if (post.likedByMe) {
        await api.delete('/api/community/posts/${post.id}/like');
      } else {
        await api.post('/api/community/posts/${post.id}/like');
      }
      ref.invalidate(communityListProvider);
    } catch (_) {}
  }
}
