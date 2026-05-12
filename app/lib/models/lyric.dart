import 'dart:convert' show JsonDecoder;

class VocabItem {
  final String word;
  final String pinyin;
  final Map<String, String> meaning;

  const VocabItem({
    required this.word,
    required this.pinyin,
    required this.meaning,
  });

  factory VocabItem.fromJson(Map<String, dynamic> json) => VocabItem(
        word: json['word'] as String,
        pinyin: json['pinyin'] as String,
        meaning: (json['meaning'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v.toString())),
      );
}

class LyricLine {
  final String zh;
  final String pinyin;
  final Map<String, String> translations;
  final List<VocabItem> vocab;

  const LyricLine({
    required this.zh,
    required this.pinyin,
    required this.translations,
    required this.vocab,
  });

  factory LyricLine.fromJson(Map<String, dynamic> json) => LyricLine(
        zh: json['zh'] as String,
        pinyin: json['pinyin'] as String,
        translations: (json['translations'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            {},
        vocab: (json['vocab'] as List<dynamic>?)
                ?.map((v) => VocabItem.fromJson(v as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class LyricJson {
  final String title;
  final List<LyricLine> lines;

  const LyricJson({required this.title, required this.lines});

  factory LyricJson.fromJson(Map<String, dynamic> json) => LyricJson(
        title: json['title'] as String,
        lines: (json['lines'] as List<dynamic>)
            .map((l) => LyricLine.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  static LyricJson? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return LyricJson.fromJson(
          Map<String, dynamic>.from(const JsonDecoder().convert(raw)));
    } catch (_) {
      return null;
    }
  }
}
