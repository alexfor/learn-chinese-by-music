import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learn_chinese_by_music/app.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LearnChineseByMusicApp()));
    expect(find.text('Songs'), findsOneWidget);
  });
}
