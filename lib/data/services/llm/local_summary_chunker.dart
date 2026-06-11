// Pure helpers for the on-device map-reduce summary path. Kept free of any
// flutter_gemma / IO dependency so they can be unit-tested directly.

/// Splits [text] into windows that each fit (where possible) within
/// [windowSize] characters, breaking on sentence/paragraph boundaries rather
/// than mid-word so each window stays coherent.
///
/// At most [maxWindows] windows are produced. When the text is longer than
/// `windowSize * maxWindows`, the window size is grown so the whole transcript
/// is still covered by [maxWindows] windows (the caller truncates an oversized
/// window before inference) — this bounds total inference time on very long
/// meetings while never silently dropping the tail the way a single hard
/// truncation would.
List<String> splitTranscriptIntoWindows(
  String text, {
  required int windowSize,
  required int maxWindows,
}) {
  assert(windowSize > 0, 'windowSize must be positive');
  assert(maxWindows > 0, 'maxWindows must be positive');
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const [];
  if (trimmed.length <= windowSize) return [trimmed];

  // Grow the effective window so the whole transcript fits in maxWindows.
  final needed = (trimmed.length / windowSize).ceil();
  final effectiveSize = needed > maxWindows
      ? (trimmed.length / maxWindows).ceil()
      : windowSize;

  final sentences = _splitIntoSentences(trimmed);
  final windows = <String>[];
  final buffer = StringBuffer();

  void flush() {
    final chunk = buffer.toString().trim();
    if (chunk.isNotEmpty) windows.add(chunk);
    buffer.clear();
  }

  for (final sentence in sentences) {
    // A single sentence longer than the window: flush what we have, then emit
    // the long sentence as its own window (hard-split if truly enormous).
    if (sentence.length > effectiveSize) {
      flush();
      for (var i = 0; i < sentence.length; i += effectiveSize) {
        final end = (i + effectiveSize).clamp(0, sentence.length);
        windows.add(sentence.substring(i, end).trim());
      }
      continue;
    }
    if (buffer.isNotEmpty &&
        buffer.length + 1 + sentence.length > effectiveSize) {
      flush();
    }
    if (buffer.isNotEmpty) buffer.write(' ');
    buffer.write(sentence);
  }
  flush();

  // Hard cap: sentence packing can leave gaps that spill into an extra window,
  // so merge any overflow tail into the last allowed window. The caller bounds
  // an oversized window to the budget before inference.
  if (windows.length > maxWindows) {
    final tail = windows.sublist(maxWindows - 1).join(' ');
    return [...windows.sublist(0, maxWindows - 1), tail];
  }

  return windows;
}

/// Splits text into sentence-ish units on `.!?` and newlines, keeping the
/// delimiter so the rejoined window reads naturally.
List<String> _splitIntoSentences(String text) {
  final matches = RegExp(r'[^.!?\n]*[.!?\n]+|[^.!?\n]+$')
      .allMatches(text)
      .map((m) => m.group(0)!.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  return matches.isEmpty ? [text] : matches;
}
