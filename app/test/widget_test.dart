import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learn_chinese_by_music/app.dart';
import 'package:learn_chinese_by_music/features/songs/song_providers.dart';
import 'package:learn_chinese_by_music/models/song.dart';

void main() {
  testWidgets('App launches with song list', (WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      songListProvider.overrideWith(() => _FakeSongListNotifier()),
    ]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LearnChineseByMusicApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Songs'), findsOneWidget);
  });
}

class _FakeSongListNotifier extends SongListNotifier {
  @override
  Future<SongListResponse> build() async {
    return const SongListResponse(songs: [], total: 0, page: 1, pageSize: 20);
  }
}
