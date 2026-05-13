import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';
import 'community_models.dart';

final communityListProvider =
    FutureProvider<List<CommunityPost>>((ref) async {
  final api = ref.read(apiProvider);
  final resp = await api.get('/api/community/posts');
  final list = resp.data as List<dynamic>;
  return list
      .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
      .toList();
});
