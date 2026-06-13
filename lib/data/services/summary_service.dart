import 'package:voicescribe_mobile/domain/models/app_error.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/utils/text_utils.dart';

/// Marker for summary errors the UI can surface safely (no class names or
/// stack traces). [code] is mapped to the active locale by the UI; [message]
/// is the log-friendly description.
abstract interface class SummaryFailure {
  String get message;
  AppErrorCode get code;
}

/// Progress of a multi-step summary (on-device map-reduce over a long
/// transcript). [current] is the 1-based step just completed, [total] the total
/// step count; when [total] is 1 there is nothing useful to show.
class SummaryProgress {
  const SummaryProgress({required this.current, required this.total});

  final int current;
  final int total;

  bool get isMultiStep => total > 1;
}

/// Optional callback invoked as a summary advances through its steps.
typedef SummaryProgressCallback = void Function(SummaryProgress progress);

/// Single, fixed summary format sent to the backend. The app no longer exposes a
/// short/medium/long choice; "medium" maps to a rich-but-not-bloated summary
/// (short exec summary + all decisions + all action items + open questions). The
/// backend still expects a `length` field, so this constant preserves that
/// contract while keeping the choice out of the UI.
const String kFixedSummaryLength = 'medium';

// Kept as an interface so app state can inject local/cloud summary engines.
// ignore: one_member_abstracts
abstract class SummaryService {
  Future<Summary> generate({
    required Transcript transcript,
    required String transcriptText,
    required String provider,
    SummaryProgressCallback? onProgress,
  });
}

class LocalSummaryService implements SummaryService {
  const LocalSummaryService();

  @override
  Future<Summary> generate({
    required Transcript transcript,
    required String transcriptText,
    required String provider,
    SummaryProgressCallback? onProgress,
  }) async {
    final normalized = normalizeWhitespace(transcriptText);
    final sentences = normalized
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((item) => item.trim().isNotEmpty)
        .toList();

    const takeCount = 2;

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
