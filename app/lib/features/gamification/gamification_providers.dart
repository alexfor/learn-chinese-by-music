import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';
import 'gamification_models.dart';

final streakProvider = FutureProvider<StreakInfo>((ref) async {
  final api = ref.read(apiProvider);
  try {
    final resp = await api.get('/api/streak');
    return StreakInfo.fromJson(resp.data as Map<String, dynamic>);
  } catch (_) {
    return const StreakInfo(
      currentStreak: 0,
      longestStreak: 0,
      checkedInToday: false,
    );
  }
});

final checkinProvider = FutureProvider<bool>((ref) async {
  final api = ref.read(apiProvider);
  final resp = await api.post('/api/streak/checkin');
  if (resp.statusCode == 200) {
    ref.invalidate(streakProvider);
    return true;
  }
  return false;
});

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final api = ref.read(apiProvider);
  try {
    final resp = await api.get('/api/achievements');
    final list = resp.data as List<dynamic>;
    return list
        .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});

final achievementDefinitionsProvider =
    FutureProvider<List<AchievementDefinition>>((ref) async {
  final api = ref.read(apiProvider);
  try {
    final resp = await api.get('/api/achievements/definitions');
    final list = resp.data as List<dynamic>;
    return list
        .map((e) => AchievementDefinition.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});
