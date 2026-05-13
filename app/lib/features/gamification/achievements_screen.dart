import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gamification_models.dart';
import 'gamification_providers.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAchievements = ref.watch(achievementsProvider);
    final asyncDefs = ref.watch(achievementDefinitionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: asyncAchievements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Failed to load achievements',
                  style: theme.textTheme.titleMedium),
              TextButton(
                onPressed: () {
                  ref.invalidate(achievementsProvider);
                  ref.invalidate(achievementDefinitionsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (achievements) {
          final unlockedKeys =
              achievements.map((a) => a.achievementKey).toSet();
          final defs = asyncDefs.valueOrNull ?? [];

          if (defs.isEmpty) {
            return const Center(child: Text('No achievements defined'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: defs.map((def) {
              final isUnlocked = unlockedKeys.contains(def.key);
              return _AchievementCard(
                definition: def,
                isUnlocked: isUnlocked,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementDefinition definition;
  final bool isUnlocked;

  const _AchievementCard({
    required this.definition,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Icon(
            _iconFor(definition.icon),
            size: 36,
            color: isUnlocked ? Colors.amber : Colors.grey,
          ),
          title: Text(
            definition.title,
            style: TextStyle(
              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(definition.description),
          trailing: isUnlocked
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.lock_outline, color: Colors.grey),
        ),
      ),
    );
  }

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'mic':
        return Icons.mic;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'library_music':
        return Icons.library_music;
      case 'whatshot':
        return Icons.whatshot;
      case 'share':
        return Icons.share;
      default:
        return Icons.emoji_events;
    }
  }
}
