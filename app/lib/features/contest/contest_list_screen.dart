import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'contest_providers.dart';
import 'contest_models.dart';

class ContestListScreen extends ConsumerWidget {
  const ContestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncContests = ref.watch(contestListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Contests')),
      body: asyncContests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Failed to load contests',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(contestListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (contests) => contests.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No contests yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: contests.length,
                itemBuilder: (context, index) =>
                    _ContestCard(contest: contests[index]),
              ),
      ),
    );
  }
}

class _ContestCard extends StatelessWidget {
  final ContestSummary contest;

  const _ContestCard({required this.contest});

  @override
  Widget build(BuildContext context) {
    final statusColor = contest.isActive ? Colors.green : Colors.grey;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contest.isActive
              ? Colors.green.withAlpha(30)
              : Colors.grey.withAlpha(30),
          child: Icon(
            contest.isActive ? Icons.emoji_events : Icons.event,
            color: statusColor,
          ),
        ),
        title: Text(contest.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          contest.isActive ? 'Active' : contest.status,
          style: TextStyle(color: statusColor),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/contest/${contest.id}'),
      ),
    );
  }
}
