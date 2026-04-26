import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/utils/text_utils.dart';

// Kept as an interface so app state can inject local/cloud summary engines.
// ignore: one_member_abstracts
abstract class SummaryService {
  Future<Summary> generate({
    required Transcript transcript,
    required String transcriptText,
    required String provider,
    required String length,
  });
}

class LocalSummaryService implements SummaryService {
  const LocalSummaryService();

  @override
  Future<Summary> generate({
    required Transcript transcript,
    required String transcriptText,
    required String provider,
    required String length,
  }) async {
    final normalized = normalizeWhitespace(transcriptText);
    final sentences = normalized
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((item) => item.trim().isNotEmpty)
        .toList();

    final takeCount = switch (length) {
      'short' => 1,
      'long' => 4,
      _ => 2,
    };

    final selected = sentences.isEmpty
        ? [normalized]
        : sentences.take(takeCount).toList();
    final summaryText = selected
        .where((item) => item.trim().isNotEmpty)
        .map((item) => '- ${item.trim()}')
        .join('\n');

    final now = DateTime.now();
    return Summary(
      id: 'summary-${now.microsecondsSinceEpoch}',
      transcriptId: transcript.id,
      providerKey: provider,
      model: provider == 'cloud' ? 'cloud-default' : 'local-default',
      summaryText: summaryText,
      tokenCount: normalized.split(' ').where((e) => e.isNotEmpty).length,
      processingTimeMs: 0,
      createdAt: now,
    );
  }
}
