import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/services/summary_service.dart';

class SummaryController {
  List<Summary> summaries = [];
  String provider = 'local';
  String length = 'medium';
  bool generating = false;

  void hydrate({
    required List<Summary> summaries,
    required String provider,
    required String length,
  }) {
    this.summaries = summaries;
    this.provider = provider;
    this.length = length;
  }

  // Controller methods intentionally keep mutation explicit for AppController.
  // ignore: use_setters_to_change_properties
  void applyProvider(String value) {
    provider = value;
  }

  // Controller methods intentionally keep mutation explicit for AppController.
  // ignore: use_setters_to_change_properties
  void applyLength(String value) {
    length = value;
  }

  Summary? latestForTranscript(String transcriptId) {
    final items =
        summaries.where((item) => item.transcriptId == transcriptId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.isEmpty ? null : items.first;
  }

  Future<Summary?> generate({
    required Transcript transcript,
    required String transcriptText,
    required SummaryService summaryService,
  }) async {
    if (transcriptText.trim().isEmpty || generating) {
      return null;
    }

    generating = true;
    try {
      final summary = await summaryService.generate(
        transcript: transcript,
        transcriptText: transcriptText,
        provider: provider,
        length: length,
      );
      summaries = [
        summary,
        ...summaries.where((item) => item.id != summary.id),
      ];
      return summary;
    } finally {
      generating = false;
    }
  }
}
