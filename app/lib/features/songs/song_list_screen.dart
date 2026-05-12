import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'song_providers.dart';
import 'song_card.dart';
import 'song_filter.dart';

class SongListScreen extends ConsumerWidget {
  const SongListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songListAsync = ref.watch(songListProvider);
    final filter = ref.watch(songFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Songs')),
      body: Column(
        children: [
          SongFilterBar(
            selectedStyle: filter.style,
            onStyleChanged: (style) {
              ref.read(songFilterProvider.notifier).state =
                  SongFilter(
                style: style,
                difficultyMin: filter.difficultyMin,
                difficultyMax: filter.difficultyMax,
                keyword: filter.keyword,
              );
              ref.invalidate(songListProvider);
            },
          ),
          Expanded(
            child: songListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to load songs',
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(songListProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (response) {
                if (response.songs.isEmpty) {
                  return const Center(child: Text('No songs found'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(songListProvider.notifier).refresh(),
                  child: ListView.builder(
                    itemCount: response.songs.length,
                    itemBuilder: (context, index) =>
                        SongCard(song: response.songs[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
