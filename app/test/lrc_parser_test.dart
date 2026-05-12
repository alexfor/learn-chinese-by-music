import 'package:flutter_test/flutter_test.dart';
import 'package:learn_chinese_by_music/shared/lrc_parser.dart';

void main() {
  group('LrcParser', () {
    test('parses single line with timestamp', () {
      const lrc = '[00:05.50]朋友一生一起走';
      final lines = LrcParser.parse(lrc);
      expect(lines, hasLength(1));
      expect(lines[0].timestampMs, equals(5500));
      expect(lines[0].text, equals('朋友一生一起走'));
    });

    test('parses multiple lines in order', () {
      const lrc = '[00:00.00]朋友一生一起走\n[00:05.50]那些日子不再有\n[00:11.00]一句话一辈子';
      final lines = LrcParser.parse(lrc);
      expect(lines, hasLength(3));
      expect(lines[0].timestampMs, equals(0));
      expect(lines[0].text, equals('朋友一生一起走'));
      expect(lines[1].timestampMs, equals(5500));
      expect(lines[1].text, equals('那些日子不再有'));
      expect(lines[2].timestampMs, equals(11000));
      expect(lines[2].text, equals('一句话一辈子'));
    });

    test('sorts lines by timestamp', () {
      const lrc = '[00:11.00]C line\n[00:00.00]A line\n[00:05.50]B line';
      final lines = LrcParser.parse(lrc);
      expect(lines[0].text, equals('A line'));
      expect(lines[1].text, equals('B line'));
      expect(lines[2].text, equals('C line'));
    });

    test('handles millisecond precision with two digits', () {
      const lrc = '[01:23.45]test';
      final lines = LrcParser.parse(lrc);
      expect(lines[0].timestampMs, equals(83450));
    });

    test('handles millisecond precision with three digits', () {
      const lrc = '[01:23.456]test';
      final lines = LrcParser.parse(lrc);
      expect(lines[0].timestampMs, equals(83456));
    });

    test('ignores metadata tags like [ti:], [ar:], etc.', () {
      const lrc = '[ti:朋友]\n[ar:周华健]\n[00:05.50]朋友一生一起走';
      final lines = LrcParser.parse(lrc);
      expect(lines, hasLength(1));
      expect(lines[0].text, equals('朋友一生一起走'));
    });

    test('skips blank lines', () {
      const lrc = '[00:00.00]line1\n\n[00:05.50]line2\n';
      final lines = LrcParser.parse(lrc);
      expect(lines, hasLength(2));
    });

    test('returns empty list for empty input', () {
      expect(LrcParser.parse(''), isEmpty);
    });

    test('skips lines without valid timestamp', () {
      const lrc = 'no timestamp here\n[00:05.50]valid line';
      final lines = LrcParser.parse(lrc);
      expect(lines, hasLength(1));
      expect(lines[0].text, equals('valid line'));
    });

    test('finds current line index for a given position', () {
      const lrc = '[00:00.00]line0\n[00:05.00]line1\n[00:10.00]line2\n[00:15.00]line3';
      final lines = LrcParser.parse(lrc);

      expect(LrcParser.currentLineIndex(lines, 0), equals(0));
      expect(LrcParser.currentLineIndex(lines, 3000), equals(0));
      expect(LrcParser.currentLineIndex(lines, 5000), equals(1));
      expect(LrcParser.currentLineIndex(lines, 7499), equals(1));
      expect(LrcParser.currentLineIndex(lines, 10000), equals(2));
      expect(LrcParser.currentLineIndex(lines, 16000), equals(3));
    });

    test('returns -1 when position is before first line', () {
      // Edge: timestamps don't start at 0
      const lrc = '[00:05.00]line1\n[00:10.00]line2';
      final lines = LrcParser.parse(lrc);
      expect(LrcParser.currentLineIndex(lines, 2000), equals(-1));
    });

    test('handles duplicate timestamps by keeping all lines sorted', () {
      const lrc = '[00:05.00]line A\n[00:05.00]line B';
      final lines = LrcParser.parse(lrc);
      expect(lines, hasLength(2));
      expect(lines[0].text, equals('line A'));
      expect(lines[1].text, equals('line B'));
    });
  });
}
