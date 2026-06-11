import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/data/services/llm/local_summary_chunker.dart';

void main() {
  group('splitTranscriptIntoWindows', () {
    test('returns empty for blank input', () {
      expect(
        splitTranscriptIntoWindows('   ', windowSize: 100, maxWindows: 4),
        isEmpty,
      );
    });

    test('returns a single window when text fits the budget', () {
      const text = 'Kısa bir toplantı metni. İkinci cümle.';
      final windows = splitTranscriptIntoWindows(
        text,
        windowSize: 100,
        maxWindows: 4,
      );
      expect(windows, [text]);
    });

    test('splits on sentence boundaries within the window size', () {
      final text = List.generate(10, (i) => 'Cümle numara $i.').join(' ');
      final windows = splitTranscriptIntoWindows(
        text,
        windowSize: 40,
        maxWindows: 20,
      );
      expect(windows.length, greaterThan(1));
      for (final window in windows) {
        expect(window.length, lessThanOrEqualTo(40));
      }
      // No sentence is lost.
      expect(windows.join(' '), contains('Cümle numara 0.'));
      expect(windows.join(' '), contains('Cümle numara 9.'));
    });

    test('never exceeds maxWindows even for very long text', () {
      final text = List.generate(200, (i) => 'Cümle $i.').join(' ');
      final windows = splitTranscriptIntoWindows(
        text,
        windowSize: 30,
        maxWindows: 5,
      );
      expect(windows.length, lessThanOrEqualTo(5));
      expect(windows, isNotEmpty);
    });

    test('hard-splits a single sentence longer than the window', () {
      final text = 'a' * 250;
      final windows = splitTranscriptIntoWindows(
        text,
        windowSize: 100,
        maxWindows: 10,
      );
      expect(windows.length, 3);
      for (final window in windows) {
        expect(window.length, lessThanOrEqualTo(100));
      }
      expect(windows.join().length, 250);
    });
  });
}
