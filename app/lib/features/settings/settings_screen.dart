import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../gamification/gamification_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStreak = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Learning'),
          _MenuTile(
            icon: Icons.local_fire_department,
            title: 'Practice Streak',
            trailing: asyncStreak.valueOrNull != null
                ? Text(
                    '${asyncStreak.valueOrNull!.currentStreak} days',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
            onTap: () => context.push('/streak'),
          ),
          _MenuTile(
            icon: Icons.emoji_events,
            title: 'Achievements',
            onTap: () => context.push('/achievements'),
          ),
          const Divider(),
          _SectionHeader(title: 'Subscription'),
          _MenuTile(
            icon: Icons.subscriptions,
            title: 'Manage Subscription',
            onTap: () => context.push('/subscription'),
          ),
          _MenuTile(
            icon: Icons.verified,
            title: 'Upgrade to Premium',
            onTap: () => context.push('/paywall'),
          ),
          const Divider(),
          _SectionHeader(title: 'Preferences'),
          _MenuTile(
            icon: Icons.language,
            title: 'Language',
            trailing: const Text('English'),
            onTap: () {
              // Future: language selection
            },
          ),
          _PrecisionModeTile(),
          const Divider(),
          _SectionHeader(title: 'About'),
          _MenuTile(
            icon: Icons.info_outline,
            title: 'Version',
            trailing: const Text('1.0.0'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _PrecisionModeTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PrecisionModeTile> createState() => _PrecisionModeTileState();
}

class _PrecisionModeTileState extends ConsumerState<_PrecisionModeTile> {
  bool _isHighPrecision = true;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: const Icon(Icons.tune),
      title: const Text('High Precision Mode'),
      subtitle: const Text('Uses more processing for better scoring'),
      value: _isHighPrecision,
      onChanged: (value) {
        setState(() => _isHighPrecision = value);
      },
    );
  }
}
