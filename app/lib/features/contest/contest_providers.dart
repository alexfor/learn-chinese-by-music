import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';
import 'contest_models.dart';

final contestListProvider =
    FutureProvider<List<ContestSummary>>((ref) async {
  final api = ref.read(apiProvider);
  final resp = await api.get('/api/contests');
  final list = resp.data as List<dynamic>;
  return list
      .map((e) => ContestSummary.fromJson(e as Map<String, dynamic>))
      .toList();
});

final contestDetailProvider =
    FutureProvider.family<ContestDetail, String>((ref, contestId) async {
  final api = ref.read(apiProvider);
  final resp = await api.get('/api/contests/$contestId');
  return ContestDetail.fromJson(resp.data as Map<String, dynamic>);
});
