import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gamification_models.dart';
import 'gamification_providers.dart';

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStreak = ref.watch(streakProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Practice Streak')),
      body: asyncStreak.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Failed to load streak',
                  style: theme.textTheme.titleMedium),
              TextButton(
                onPressed: () => ref.invalidate(streakProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (streak) => _buildContent(context, ref, streak, theme),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, StreakInfo streak, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: streak.currentStreak > 0
                      ? (streak.currentStreak % 7) / 7.0
                      : 0,
                  strokeWidth: 12,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: streak.checkedInToday
                      ? Colors.orange
                      : theme.colorScheme.primary,
                ),
              ),
              Column(
                children: [
                  Text(
                    '${streak.currentStreak}',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('days', style: theme.textTheme.bodyLarge),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (!streak.checkedInToday)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _doCheckin(context, ref),
              icon: const Icon(Icons.check_circle),
              label: const Text('Check In Today'),
            ),
          )
        else
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text("Today's practice done!",
                      style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 32),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn(
                    label: 'Current', value: '${streak.currentStreak}'),
                _StatColumn(
                    label: 'Longest', value: '${streak.longestStreak}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Practice every day to build your streak! '
          '7-day streak unlocks the "Dedicated Learner" achievement.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _doCheckin(BuildContext context, WidgetRef ref) async {
    try {
      ref.invalidate(checkinProvider);
      await ref.read(checkinProvider.future);
      ref.invalidate(streakProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in failed: $e')),
        );
      }
    }
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        )),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        )),
      ],
    );
  }
}
