import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/song.dart';
import '../../models/lyric.dart';
import 'song_providers.dart';

String _difficultyLabel(double d) {
  if (d <= 2) return 'Easy';
  if (d <= 4) return 'Beginner';
  if (d <= 6) return 'Intermediate';
  if (d <= 8) return 'Advanced';
  return 'Expert';
}

Color _difficultyColor(double d) {
  if (d <= 2) return Colors.green;
  if (d <= 4) return Colors.lightGreen;
  if (d <= 6) return Colors.orange;
  if (d <= 8) return Colors.deepOrange;
  return Colors.red;
}

class SongDetailScreen extends ConsumerWidget {
  final String songId;
  const SongDetailScreen({super.key, required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(songDetailProvider(songId));

    return Scaffold(
      appBar: AppBar(title: const Text('Song Detail')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load song',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(songDetailProvider(songId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (song) => _SongDetailContent(song: song),
      ),
    );
  }
}

class _SongDetailContent extends StatelessWidget {
  final SongDetail song;
  const _SongDetailContent({required this.song});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + style + difficulty
          Text(song.title,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(
                label: Text(song.style),
                side: BorderSide.none,
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                    '${_difficultyLabel(song.difficulty)} (${song.difficulty.toStringAsFixed(1)})'),
                backgroundColor:
                    _difficultyColor(song.difficulty).withAlpha(40),
                side: BorderSide.none,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push('/songs/${song.id}/play'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => context.push('/songs/${song.id}/sing'),
                  icon: const Icon(Icons.mic),
                  label: const Text('Sing'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lyrics with pinyin
          if (song.lyricJson != null) ...[
            Text('Lyrics', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...song.lyricJson!.lines.map((line) => _LyricLineTile(line: line)),
          ],
        ],
      ),
    );
  }
}

class _LyricLineTile extends StatelessWidget {
  final LyricLine line;
  const _LyricLineTile({required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(line.zh, style: const TextStyle(fontSize: 18)),
          Text(line.pinyin,
              style: TextStyle(
                  fontSize: 14, color: Theme.of(context).colorScheme.outline)),
          if (line.vocab.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: line.vocab
                  .map((v) => Chip(
                        label: Text('${v.word} ${v.pinyin}'),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: const TextStyle(fontSize: 12),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
