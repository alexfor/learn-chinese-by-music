class LeaderboardEntry {
  final int rank;
  final String userId;
  final String nickname;
  final double score;
  final int attempts;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.nickname,
    required this.score,
    required this.attempts,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      userId: json['user_id'] as String,
      nickname: json['nickname'] as String? ?? '',
      score: (json['score'] as num).toDouble(),
      attempts: (json['attempts'] as num).toInt(),
    );
  }
}

class MyRank {
  final int rank;
  final double score;
  final int attempts;

  const MyRank({
    required this.rank,
    required this.score,
    required this.attempts,
  });

  factory MyRank.fromJson(Map<String, dynamic> json) {
    return MyRank(
      rank: (json['rank'] as num).toInt(),
      score: (json['score'] as num).toDouble(),
      attempts: (json['attempts'] as num).toInt(),
    );
  }
}

class LeaderboardData {
  final String songId;
  final List<LeaderboardEntry> entries;
  final MyRank? myRank;

  const LeaderboardData({
    required this.songId,
    required this.entries,
    this.myRank,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    final entriesList = (json['entries'] as List<dynamic>)
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return LeaderboardData(
      songId: json['song_id'] as String,
      entries: entriesList,
    );
  }
}
