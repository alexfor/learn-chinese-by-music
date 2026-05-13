class SubscriptionInfo {
  final String subscription;
  final String? expiresAt;
  final List<String> purchasedSongs;
  final bool hasAccess;

  const SubscriptionInfo({
    required this.subscription,
    this.expiresAt,
    required this.purchasedSongs,
    required this.hasAccess,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      subscription: json['subscription'] as String? ?? 'free',
      expiresAt: json['expires_at'] as String?,
      purchasedSongs: (json['purchased_songs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hasAccess: json['has_access'] as bool? ?? false,
    );
  }

  bool get isPremium => subscription == 'premium' && hasAccess;
}

class PurchaseRequest {
  final String productId;
  final String receipt;
  final String platform;

  const PurchaseRequest({
    required this.productId,
    required this.receipt,
    required this.platform,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseRequest &&
          productId == other.productId &&
          receipt == other.receipt &&
          platform == other.platform;

  @override
  int get hashCode => Object.hash(productId, receipt, platform);
}

class PaymentProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final bool isPopular;

  const PaymentProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.isPopular = false,
  });
}
