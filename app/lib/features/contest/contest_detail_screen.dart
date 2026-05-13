import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'contest_providers.dart';
import 'contest_models.dart';

class ContestDetailScreen extends ConsumerWidget {
  final String contestId;

  const ContestDetailScreen({super.key, required this.contestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(contestDetailProvider(contestId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Contest')),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Failed to load contest',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(contestDetailProvider(contestId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (detail) => _ContestDetailContent(detail: detail),
      ),
    );
  }
}

class _ContestDetailContent extends StatelessWidget {
  final ContestDetail detail;

  const _ContestDetailContent({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Contest header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.title,
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.emoji_events,
                      label: detail.status,
                      color:
                          detail.status == 'active' ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.music_note,
                      label: '${detail.songIds.length} songs',
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${detail.startDate} — ${detail.endDate}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Leaderboard section
        Text('Leaderboard',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),

        if (detail.entries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.emoji_events, size: 48,
                        color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('No entries yet',
                        style: TextStyle(color: Colors.grey[500])),
                    const SizedBox(height: 4),
                    Text('Sing a contest song to join!',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
              ),
            ),
          )
        else
          ...detail.entries.map((entry) => _EntryRow(
                entry: entry,
                isCurrentSong: entry.songId == detail.songIds.first,
              )),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.only(left: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _EntryRow extends StatelessWidget {
  final ContestEntry entry;
  final bool isCurrentSong;

  const _EntryRow({required this.entry, required this.isCurrentSong});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankColor = entry.rank <= 3
        ? [Colors.amber, Colors.grey[400]!, Colors.brown[300]!][entry.rank - 1]
        : null;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              rankColor ?? theme.colorScheme.surfaceContainerHighest,
          child: Text(
            '#${entry.rank}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: rankColor != null ? Colors.white : null,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(entry.nickname),
        subtitle: isCurrentSong ? null : Text('Song: ${entry.songId}'),
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
