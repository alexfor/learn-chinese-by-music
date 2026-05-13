class StreakInfo {
  final int currentStreak;
  final int longestStreak;
  final String? lastCheckin;
  final bool checkedInToday;

  const StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    this.lastCheckin,
    required this.checkedInToday,
  });

  factory StreakInfo.fromJson(Map<String, dynamic> json) {
    return StreakInfo(
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      lastCheckin: json['last_checkin'] as String?,
      checkedInToday: json['checked_in_today'] as bool? ?? false,
    );
  }
}

class Achievement {
  final String id;
  final String achievementKey;
  final String unlockedAt;
  final String? title;
  final String? description;

  const Achievement({
    required this.id,
    required this.achievementKey,
    required this.unlockedAt,
    this.title,
    this.description,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      achievementKey: json['achievement_key'] as String,
      unlockedAt: json['unlocked_at'] as String? ?? '',
      title: json['title'] as String?,
      description: json['description'] as String?,
    );
  }
}

class AchievementDefinition {
  final String key;
  final String title;
  final String description;
  final String icon;

  const AchievementDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  factory AchievementDefinition.fromJson(Map<String, dynamic> json) {
    return AchievementDefinition(
      key: json['key'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String? ?? 'emoji_events',
    );
  }
}
