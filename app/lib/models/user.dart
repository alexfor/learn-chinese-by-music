class User {
  final String id;
  final String? authProvider;
  final String? providerId;
  final double levelScore;
  final String subscription;
  final String? createdAt;

  const User({
    required this.id,
    this.authProvider,
    this.providerId,
    this.levelScore = 0,
    this.subscription = 'free',
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        authProvider: json['auth_provider'] as String?,
        providerId: json['provider_id'] as String?,
        levelScore: (json['level_score'] as num?)?.toDouble() ?? 0,
        subscription: json['subscription'] as String? ?? 'free',
        createdAt: json['created_at'] as String?,
      );
}
