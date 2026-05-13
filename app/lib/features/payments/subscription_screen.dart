import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'payment_models.dart';
import 'payment_providers.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSub = ref.watch(subscriptionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: asyncSub.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Failed to load subscription info',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(subscriptionProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (sub) => _buildContent(context, ref, sub, theme),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, SubscriptionInfo sub, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          sub.isPremium ? Icons.verified : Icons.lock_outline,
          size: 64,
          color: sub.isPremium ? Colors.amber : Colors.grey,
        ),
        const SizedBox(height: 16),
        Text(
          sub.isPremium ? 'Premium Member' : 'Free Plan',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (sub.isPremium)
          Text(
            'Your subscription is active',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Text(
            'Upgrade to access all songs and features',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 32),
        if (sub.expiresAt != null)
          _InfoRow(label: 'Expires', value: sub.expiresAt!),
        if (sub.purchasedSongs.isNotEmpty)
          _InfoRow(
            label: 'Purchased songs',
            value: '${sub.purchasedSongs.length} songs',
          ),
        const SizedBox(height: 24),
        if (!sub.isPremium)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.push('/paywall'),
              child: const Text('Upgrade to Premium'),
            ),
          ),
        if (sub.isPremium)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _restorePurchases(context, ref),
              child: const Text('Restore Purchases'),
            ),
          ),
      ],
    );
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    ref.invalidate(subscriptionProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restore complete')),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }
}
