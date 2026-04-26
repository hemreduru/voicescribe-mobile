import '../models/domain.dart';

String normalizeWhitespace(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String removeOverlap(String previous, String next) {
  final prev = normalizeWhitespace(previous);
  final incoming = normalizeWhitespace(next);
  if (prev.isEmpty || incoming.isEmpty) {
    return incoming;
  }

  final prevLower = prev.toLowerCase();
  final nextLower = incoming.toLowerCase();
  final maxChars = prevLower.length < nextLower.length
      ? prevLower.length
      : nextLower.length;

  for (var length = maxChars; length >= 8; length--) {
    if (prevLower.endsWith(nextLower.substring(0, length))) {
      return normalizeWhitespace(incoming.substring(length));
    }
  }

  final previousWords = prevLower.split(' ');
  final nextWords = incoming.split(' ');
  final nextWordsLower = nextLower.split(' ');
  final maxWords = previousWords.length < nextWords.length
      ? previousWords.length
      : nextWords.length;

  for (var length = maxWords; length >= 2; length--) {
    final prevTail = previousWords
        .sublist(previousWords.length - length)
        .join(' ');
    final nextHead = nextWordsLower.sublist(0, length).join(' ');
    if (prevTail == nextHead) {
      return normalizeWhitespace(nextWords.sublist(length).join(' '));
    }
  }

  return incoming;
}

String mergeTranscriptChunks(List<TranscriptChunk> chunks) {
  final ordered = [...chunks]
    ..sort((a, b) => a.chunkIndex.compareTo(b.chunkIndex));
  return normalizeWhitespace(
    ordered
        .map((chunk) => chunk.text.trim())
        .where((text) => text.isNotEmpty)
        .join(' '),
  );
}

String formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}

String formatCompactDuration(int seconds) {
  if (seconds <= 0) {
    return '0s';
  }
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  if (minutes == 0) {
    return '${remainingSeconds}s';
  }
  return '${minutes}m ${remainingSeconds}s';
}
