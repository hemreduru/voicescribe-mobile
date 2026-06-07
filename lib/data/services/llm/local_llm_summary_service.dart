import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:voicescribe_mobile/data/services/llm/llm_model_service.dart';
import 'package:voicescribe_mobile/data/services/llm/local_llm_runtime.dart';
import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/models/meeting_summary.dart';
import 'package:voicescribe_mobile/domain/services/meeting_minutes_prompt.dart';

/// Cap on transcript characters fed to the small local model so the request
/// stays within its modest context window (Qwen2.5 0.5B ≈ 1280 tokens). Longer
/// meetings are truncated locally; the cloud path handles them fully via backend
/// chunking.
const int _localInputCharBudget = 2200;

/// Maximum time to wait for a single on-device inference before giving up, so a
/// stuck/very-slow run never spins forever.
const Duration _localInferenceTimeout = Duration(minutes: 4);

/// Thrown when the on-device model cannot produce a usable structured summary.
/// The UI surfaces [message]; no garbage is persisted.
class LocalSummaryException implements Exception, SummaryFailure {
  const LocalSummaryException(this.message);

  @override
  final String message;

  @override
  String toString() => 'LocalSummaryException: $message';
}

/// Generates a structured meeting-minutes summary fully on-device using
/// flutter_gemma. Validates the model output (must parse to a [MeetingSummary])
/// and retries once before failing — never returns malformed/garbage text.
class LocalLlmSummaryService implements SummaryService {
  LocalLlmSummaryService({
    required LocalLlmModelService modelService,
    LocalLlmRuntime runtime = const LocalLlmRuntime(),
    Uuid uuid = const Uuid(),
  }) : _modelService = modelService,
       _runtime = runtime,
       _uuid = uuid;

  final LocalLlmModelService _modelService;
  final LocalLlmRuntime _runtime;
  final Uuid _uuid;

  @override
  Future<Summary> generate({
    required Transcript transcript,
    required String transcriptText,
    required String provider,
    required String length,
  }) async {
    final input = transcriptText.trim();
    if (input.isEmpty) {
      throw const LocalSummaryException('Özetlenecek transkript metni yok.');
    }

    final stopwatch = Stopwatch()..start();
    await _modelService.ensureReady();

    final prompt = MeetingMinutesPrompt.system(length: length);
    final boundedInput = input.length > _localInputCharBudget
        ? input.substring(0, _localInputCharBudget)
        : input;

    // Validate the output parses; retry once (a small local model occasionally
    // emits malformed JSON). Never persist unparseable output.
    MeetingSummary? parsed;
    for (var attempt = 0; attempt < 2 && parsed == null; attempt++) {
      String raw;
      try {
        raw = await _runtime
            .generate(systemInstruction: prompt, userText: boundedInput)
            .timeout(_localInferenceTimeout);
      } on TimeoutException {
        throw const LocalSummaryException(
          'Özet beklenenden uzun sürdü. Lütfen tekrar deneyin veya Bulut özetini kullanın.',
        );
      }
      parsed = MeetingSummary.tryParse(raw);
    }
    stopwatch.stop();

    if (parsed == null) {
      throw const LocalSummaryException(
        'Cihaz üstü model bu sefer geçerli bir özet üretemedi. Lütfen tekrar '
        'deneyin veya Bulut özetine geçin.',
      );
    }

    return Summary(
      id: _uuid.v4(),
      transcriptId: transcript.id,
      providerKey: 'local',
      model: _modelService.modelFileName,
      // Persist the normalized JSON so the stored value is always valid.
      summaryText: parsed.toJsonString(),
      tokenCount: null,
      processingTimeMs: stopwatch.elapsedMilliseconds,
      createdAt: DateTime.now(),
    );
  }
}
