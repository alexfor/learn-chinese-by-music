class ContestSummary {
  final String id;
  final String title;
  final List<String> songIds;
  final String startDate;
  final String endDate;
  final String status;
  final String createdAt;

  const ContestSummary({
    required this.id,
    required this.title,
    required this.songIds,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
  });

  bool get isActive => status == 'active';

  factory ContestSummary.fromJson(Map<String, dynamic> json) {
    return ContestSummary(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      songIds: (json['song_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class ContestEntry {
  final int rank;
  final String userId;
  final String nickname;
  final String songId;
  final double score;

  const ContestEntry({
    required this.rank,
    required this.userId,
    required this.nickname,
    required this.songId,
    required this.score,
  });

  factory ContestEntry.fromJson(Map<String, dynamic> json) {
    return ContestEntry(
      rank: (json['rank'] as num).toInt(),
      userId: json['user_id'] as String,
      nickname: json['nickname'] as String? ?? '',
      songId: json['song_id'] as String,
      score: (json['score'] as num).toDouble(),
    );
  }
}

class ContestDetail {
  final String id;
  final String title;
  final List<String> songIds;
  final String startDate;
  final String endDate;
  final String status;
  final String createdAt;
  final List<ContestEntry> entries;

  const ContestDetail({
    required this.id,
    required this.title,
    required this.songIds,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.entries,
  });

  factory ContestDetail.fromJson(Map<String, dynamic> json) {
    final entriesList = (json['entries'] as List<dynamic>?)
            ?.map((e) => ContestEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return ContestDetail(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      songIds: (json['song_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      entries: entriesList,
    );
  }
}
