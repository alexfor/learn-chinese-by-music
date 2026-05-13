class CommunityPost {
  final String id;
  final String userId;
  final String nickname;
  final String songId;
  final String title;
  final String? audioUrl;
  final int likes;
  final bool likedByMe;
  final String createdAt;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.songId,
    required this.title,
    this.audioUrl,
    required this.likes,
    required this.likedByMe,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      nickname: json['nickname'] as String? ?? '',
      songId: json['song_id'] as String,
      title: json['title'] as String? ?? '',
      audioUrl: json['audio_url'] as String?,
      likes: (json['likes'] as num).toInt(),
      likedByMe: json['liked_by_me'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  CommunityPost copyWith({int? likes, bool? likedByMe}) {
    return CommunityPost(
      id: id,
      userId: userId,
      nickname: nickname,
      songId: songId,
      title: title,
      audioUrl: audioUrl,
      likes: likes ?? this.likes,
      likedByMe: likedByMe ?? this.likedByMe,
      createdAt: createdAt,
    );
  }
}
