import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'leaderboard_provider.dart';
import 'leaderboard_models.dart';

class LeaderboardScreen extends ConsumerWidget {
  final String songId;
  final String? songTitle;

  const LeaderboardScreen({
    super.key,
    required this.songId,
    this.songTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(leaderboardProvider(songId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(songTitle ?? 'Leaderboard'),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Failed to load leaderboard',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(leaderboardProvider(songId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) => data.entries.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.leaderboard, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No scores yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Be the first to sing this song!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (data.myRank != null) _MyRankCard(myRank: data.myRank!),
                  if (data.myRank != null) const SizedBox(height: 16),
                  ...data.entries.map((e) => _LeaderboardRow(entry: e)),
                ],
              ),
      ),
    );
  }
}

class _MyRankCard extends StatelessWidget {
  final MyRank myRank;

  const _MyRankCard({required this.myRank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Rank',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    )),
                Text('#${myRank.rank}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    )),
              ],
            ),
            const Spacer(),
            Text(
              '${myRank.score.toStringAsFixed(0)} pts',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankColor = entry.rank <= 3
        ? [Colors.amber, Colors.grey[400]!, Colors.brown[300]!][entry.rank - 1]
        : null;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rankColor ?? theme.colorScheme.surfaceContainerHighest,
          child: Text(
            '#${entry.rank}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: rankColor != null ? Colors.white : null,
            ),
          ),
        ),
        title: Text(entry.nickname),
        trailing: Text(
          '${entry.score.toStringAsFixed(0)} pts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
