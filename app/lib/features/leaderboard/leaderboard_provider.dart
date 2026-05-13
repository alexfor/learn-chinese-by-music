import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';
import 'leaderboard_models.dart';

final leaderboardProvider =
    FutureProvider.family<LeaderboardData, String>((ref, songId) async {
  final api = ref.read(apiProvider);

  final resp = await api.get('/api/leaderboard/songs/$songId');
  final json = Map<String, dynamic>.from(resp.data as Map);
  final entriesList = (json['entries'] as List<dynamic>)
      .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
      .toList();

  MyRank? myRank;
  try {
    final meResp = await api.get('/api/leaderboard/songs/$songId/me');
    final meData = meResp.data as Map<String, dynamic>?;
    if (meData != null && (meData['rank'] as num?)?.toInt() != 0) {
      myRank = MyRank.fromJson(meData);
    }
  } catch (_) {
    // User may not have a score yet — ignore
  }

  return LeaderboardData(
    songId: json['song_id'] as String,
    entries: entriesList,
    myRank: myRank,
  );
});
