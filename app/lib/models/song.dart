import 'lyric.dart';

class SongListItem {
  final String id;
  final String title;
  final String style;
  final double difficulty;
  final String status;

  const SongListItem({
    required this.id,
    required this.title,
    required this.style,
    required this.difficulty,
    required this.status,
  });

  factory SongListItem.fromJson(Map<String, dynamic> json) => SongListItem(
        id: json['id'] as String,
        title: json['title'] as String,
        style: json['style'] as String,
        difficulty: (json['difficulty'] as num).toDouble(),
        status: json['status'] as String,
      );
}

class SongDetail {
  final String id;
  final String title;
  final String style;
  final double difficulty;
  final LyricJson? lyricJson;
  final String? lrc;
  final String? vocalUrl;
  final String? accompanimentUrl;
  final String? fullSongUrl;
  final String status;

  const SongDetail({
    required this.id,
    required this.title,
    required this.style,
    required this.difficulty,
    this.lyricJson,
    this.lrc,
    this.vocalUrl,
    this.accompanimentUrl,
    this.fullSongUrl,
    required this.status,
  });

  factory SongDetail.fromJson(Map<String, dynamic> json) => SongDetail(
        id: json['id'] as String,
        title: json['title'] as String,
        style: json['style'] as String,
        difficulty: (json['difficulty'] as num).toDouble(),
        lyricJson: LyricJson.tryParse(json['lyric_json'] as String?),
        lrc: json['lrc'] as String?,
        vocalUrl: json['vocal_url'] as String?,
        accompanimentUrl: json['accompaniment_url'] as String?,
        fullSongUrl: json['full_song_url'] as String?,
        status: json['status'] as String,
      );
}

class SongListResponse {
  final List<SongListItem> songs;
  final int total;
  final int page;
  final int pageSize;

  const SongListResponse({
    required this.songs,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory SongListResponse.fromJson(Map<String, dynamic> json) =>
      SongListResponse(
        songs: (json['songs'] as List<dynamic>)
            .map((s) => SongListItem.fromJson(s as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['page_size'] as int,
      );
}
