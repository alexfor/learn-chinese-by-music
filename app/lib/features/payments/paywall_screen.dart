import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';
import 'payment_models.dart';
import 'payment_providers.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const products = [
    PaymentProduct(
      id: 'monthly_subscription',
      title: 'Monthly',
      description: 'Full access to all songs and features',
      price: '\$4.99/month',
    ),
    PaymentProduct(
      id: 'yearly_subscription',
      title: 'Yearly',
      description: 'Full access, 2 months free',
      price: '\$49.99/year',
      isPopular: true,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Unlock Premium')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.music_note, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Learn Chinese through Music',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get full access to the complete song library, '
            'singalong scoring, and progress tracking.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ...products.map((product) => _ProductCard(product: product)),
          const SizedBox(height: 24),
          Text(
            'Your subscription will auto-renew. Cancel anytime.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final PaymentProduct product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'BEST VALUE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(product.title,
                    style: theme.textTheme.titleLarge),
                Text(product.price,
                    style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                )),
              ],
            ),
            const SizedBox(height: 8),
            Text(product.description,
                style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _purchase(context, ref, product.id),
                child: Text('Subscribe - ${product.price}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchase(BuildContext context, WidgetRef ref, String productId) async {
    // In production, this would trigger the platform IAP flow.
    // For now, we use a mock receipt.
    final mockReceipt = 'mock-receipt-$productId';
    const platform = 'ios';

    try {
      final api = ref.read(apiProvider);
      final resp = await api.post('/api/payments/verify', data: {
        'product_id': productId,
        'receipt': mockReceipt,
        'platform': platform,
      });

      if (resp.statusCode == 200 && context.mounted) {
        ref.invalidate(subscriptionProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to Premium!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    }
  }
}
