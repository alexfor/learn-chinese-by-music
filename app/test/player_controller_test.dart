import 'package:flutter_test/flutter_test.dart';
import 'package:learn_chinese_by_music/shared/lrc_parser.dart';
import 'package:learn_chinese_by_music/features/player/player_controller.dart';

void main() {
  group('PlayerControllerLogic', () {
    late PlayerControllerLogic logic;

    setUp(() {
      logic = PlayerControllerLogic();
    });

    test('currentLineIndex starts at -1', () {
      expect(logic.currentLineIndex, equals(-1));
    });

    test('updatePosition sets currentLineIndex based on LRC lines', () {
      const lrc = '[00:00.00]line0\n[00:05.00]line1\n[00:10.00]line2';
      final lines = LrcParser.parse(lrc);
      logic.setLrcLines(lines);

      logic.updatePosition(0);
      expect(logic.currentLineIndex, equals(0));

      logic.updatePosition(3000);
      expect(logic.currentLineIndex, equals(0));

      logic.updatePosition(5000);
      expect(logic.currentLineIndex, equals(1));

      logic.updatePosition(12000);
      expect(logic.currentLineIndex, equals(2));
    });

    test('updatePosition returns -1 before first timestamp', () {
      const lrc = '[00:05.00]line1\n[00:10.00]line2';
      final lines = LrcParser.parse(lrc);
      logic.setLrcLines(lines);

      logic.updatePosition(2000);
      expect(logic.currentLineIndex, equals(-1));
    });

    test('seekTargetMs returns timestamp of selected line', () {
      const lrc = '[00:00.00]line0\n[00:05.00]line1\n[00:10.00]line2';
      final lines = LrcParser.parse(lrc);
      logic.setLrcLines(lines);

      expect(logic.seekTargetMs(0), equals(0));
      expect(logic.seekTargetMs(1), equals(5000));
      expect(logic.seekTargetMs(2), equals(10000));
    });

    test('seekTargetMs returns null for out-of-range index', () {
      const lrc = '[00:00.00]line0';
      final lines = LrcParser.parse(lrc);
      logic.setLrcLines(lines);

      expect(logic.seekTargetMs(-1), isNull);
      expect(logic.seekTargetMs(1), isNull);
    });

    test('setLrcLines resets currentLineIndex', () {
      const lrc = '[00:00.00]line0\n[00:05.00]line1';
      logic.setLrcLines(LrcParser.parse(lrc));
      logic.updatePosition(5000);
      expect(logic.currentLineIndex, equals(1));

      logic.setLrcLines([]);
      expect(logic.currentLineIndex, equals(-1));
    });
  });
}
