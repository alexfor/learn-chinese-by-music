import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../models/song.dart';
import '../../services/api_service.dart';

final apiProvider = Provider<ApiService>((ref) => ApiService());

class SongFilter {
  final String? style;
  final double? difficultyMin;
  final double? difficultyMax;
  final String? keyword;

  const SongFilter({this.style, this.difficultyMin, this.difficultyMax, this.keyword});

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (style != null) params['style'] = style;
    if (difficultyMin != null) params['difficulty_min'] = difficultyMin;
    if (difficultyMax != null) params['difficulty_max'] = difficultyMax;
    if (keyword != null) params['keyword'] = keyword;
    return params;
  }
}

final songFilterProvider = StateProvider<SongFilter>((_) => const SongFilter());

final songListProvider = AsyncNotifierProvider<SongListNotifier, SongListResponse>(
  SongListNotifier.new,
);

class SongListNotifier extends AsyncNotifier<SongListResponse> {
  @override
  Future<SongListResponse> build() async {
    final api = ref.read(apiProvider);
    final filter = ref.watch(songFilterProvider);
    final resp = await api.get('/api/songs', queryParameters: {
      ...filter.toQueryParams(),
      'page': 1,
      'page_size': 20,
    });
    return SongListResponse.fromJson(resp.data);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final songDetailProvider =
    FutureProvider.family<SongDetail, String>((ref, songId) async {
  final api = ref.read(apiProvider);
  final resp = await api.get('/api/songs/$songId');
  return SongDetail.fromJson(resp.data);
});
