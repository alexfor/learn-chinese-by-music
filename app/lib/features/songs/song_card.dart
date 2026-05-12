import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/song.dart';

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

class SongCard extends StatelessWidget {
  final SongListItem song;
  const SongCard({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(song.title, style: const TextStyle(fontSize: 18)),
        subtitle: Row(
          children: [
            Chip(
              label: Text(_difficultyLabel(song.difficulty),
                  style: const TextStyle(fontSize: 12)),
              backgroundColor: _difficultyColor(song.difficulty).withAlpha(40),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(song.style,
                  style: const TextStyle(fontSize: 12)),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/songs/${song.id}'),
      ),
    );
  }
}
