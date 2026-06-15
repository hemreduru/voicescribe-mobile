import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/data/services/llm/local_llm_runtime.dart';
import 'package:voicescribe_mobile/data/services/llm/local_llm_summary_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';

import '../../../helpers/fakes.dart';

/// Records every `userText` handed to inference so we can assert the map step
/// summarizes the whole transcript instead of silently dropping the tail of
/// each (formerly grown-then-truncated) window. Returns valid MeetingSummary
/// JSON for every call so both the map (notes) and reduce (structured) paths
/// succeed without touching flutter_gemma.
class _RecordingRuntime extends LocalLlmRuntime {
  final List<String> inputs = [];

  @override
  void acquire() {}

  @override
  Future<void> release() async {}

  @override
  Future<String> generate({
    required String systemInstruction,
    required String userText,
    int maxTokens = 2048,
  }) async {
    inputs.add(userText);
    return '{"title":"T","executive_summary":["ok"]}';
  }
}

void main() {
  // Mirrors `_localInputCharBudget` in local_llm_summary_service.dart.
  const budget = 2200;

  Transcript transcriptFor(String id) {
    final now = DateTime(2026, 6, 15);
    return Transcript(
      id: id,
      localId: id,
      title: null,
      durationSeconds: 600,
      status: TranscriptStatus.completed,
      recordedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  test(
    'map step covers every sentence and never exceeds the budget per inference',
    () async {
      // ~6800 chars: longer than a single window, shorter than the window cap,
      // so the whole transcript should be covered with no truncation.
      final sentences = List.generate(
        400,
        (i) => 'Sentence number $i is here.',
      );
      final input = sentences.join(' ');
      expect(input.length, greaterThan(budget));

      final runtime = _RecordingRuntime();
      final service = LocalLlmSummaryService(
        modelService: FakeLocalLlmModelService(),
        runtime: runtime,
      );

      await service.generate(
        transcript: transcriptFor('t1'),
        transcriptText: input,
        provider: 'local',
      );

      // The map inputs are the ones drawn from the transcript itself.
      final mapInputs = runtime.inputs
          .where((text) => input.contains(text.trim()))
          .toList();
      expect(mapInputs, isNotEmpty);

      // No inference is ever fed more than the budget.
      for (final text in runtime.inputs) {
        expect(text.length, lessThanOrEqualTo(budget));
      }

      // Every sentence appears in some map window — nothing is silently dropped
      // (the old grow-then-truncate path lost the tail of each window).
      final covered = mapInputs.join(' ');
      for (var i = 0; i < sentences.length; i++) {
        expect(
          covered.contains('Sentence number $i is here.'),
          isTrue,
          reason: 'sentence $i was dropped from the on-device summary input',
        );
      }
    },
  );
}
