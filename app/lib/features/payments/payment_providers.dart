import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';
import 'payment_models.dart';

final subscriptionProvider =
    FutureProvider<SubscriptionInfo>((ref) async {
  final api = ref.read(apiProvider);
  try {
    final resp = await api.get('/api/payments/subscription');
    return SubscriptionInfo.fromJson(resp.data as Map<String, dynamic>);
  } catch (_) {
    return const SubscriptionInfo(
      subscription: 'free',
      purchasedSongs: [],
      hasAccess: false,
    );
  }
});

final verifyPurchaseProvider =
    FutureProvider.family<bool, PurchaseRequest>((ref, purchase) async {
  final api = ref.read(apiProvider);
  final resp = await api.post('/api/payments/verify', data: {
    'product_id': purchase.productId,
    'receipt': purchase.receipt,
    'platform': purchase.platform,
  });
  if (resp.statusCode == 200) {
    ref.invalidate(subscriptionProvider);
    return true;
  }
  return false;
});
