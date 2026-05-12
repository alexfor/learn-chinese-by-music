import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'progress_controller.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressControllerProvider.notifier).getAllSavedProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(progressControllerProvider);
    final records = state.records.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: records.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_note, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No progress yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sing a song to see your scores here!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return Card(
                  child: ListTile(
                    title: Text('Song ${record.songId}'),
                    trailing: Text(
                      '${record.bestScore.toStringAsFixed(0)} pts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: record.passed ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
