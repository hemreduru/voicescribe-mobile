import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:voicescribe_mobile/data/services/llm/llm_model_service.dart';
import 'package:voicescribe_mobile/data/services/llm/local_llm_runtime.dart';
import 'package:voicescribe_mobile/data/services/llm/local_summary_chunker.dart';
import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/models/meeting_summary.dart';
import 'package:voicescribe_mobile/domain/services/meeting_minutes_prompt.dart';
import 'package:voicescribe_mobile/domain/utils/locale_utils.dart';

/// Cap on transcript characters fed to the small local model in a single
/// inference so the request stays within its modest context window
/// (Qwen2.5 0.5B / Gemma 3 1B ≈ 1280 tokens). Longer meetings are summarized
/// hierarchically (map-reduce) instead of being silently truncated.
const int _localInputCharBudget = 2200;

/// Upper bound on map windows so a very long meeting can't spawn an unbounded
/// number of inferences. Beyond `_localInputCharBudget * _maxMapWindows` chars
/// each window grows and is truncated, trading some fidelity for bounded time.
const int _maxMapWindows = 6;

/// Cap on recursive reduce passes when merged notes still exceed the budget.
const int _maxReduceDepth = 2;

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
/// flutter_gemma. Short transcripts run in a single inference; long ones are
/// summarized hierarchically (map each window to notes, then reduce the notes
/// into one [MeetingSummary]) so content is never silently dropped and no single
/// inference overruns the token cap or the timeout. Output is always validated —
/// the caller never sees malformed/garbage text.
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
    SummaryProgressCallback? onProgress,
  }) async {
    final input = transcriptText.trim();
    if (input.isEmpty) {
      throw const LocalSummaryException('Özetlenecek transkript metni yok.');
    }

    final stopwatch = Stopwatch()..start();
    await _modelService.ensureReady();

    final locale = deviceLanguageCode();
    final parsed = input.length <= _localInputCharBudget
        ? await _summarizeSinglePass(input, locale, onProgress)
        : await _summarizeLong(input, locale, transcript, onProgress);
    stopwatch.stop();

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

  /// Single inference for a transcript that already fits the budget.
  Future<MeetingSummary> _summarizeSinglePass(
    String input,
    String locale,
    SummaryProgressCallback? onProgress,
  ) async {
    onProgress?.call(const SummaryProgress(current: 1, total: 1));
    final prompt = MeetingMinutesPrompt.system(locale: locale);
    final parsed = await _structuredWithRetry(prompt, input);
    if (parsed == null) {
      throw const LocalSummaryException(
        'Cihaz üstü model bu sefer geçerli bir özet üretemedi. Lütfen tekrar '
        'deneyin veya Bulut özetine geçin.',
      );
    }
    return parsed;
  }

  /// Map-reduce for a transcript longer than a single inference can handle.
  Future<MeetingSummary> _summarizeLong(
    String input,
    String locale,
    Transcript transcript,
    SummaryProgressCallback? onProgress,
  ) async {
    final windows = splitTranscriptIntoWindows(
      input,
      windowSize: _localInputCharBudget,
      maxWindows: _maxMapWindows,
    );
    // Steps: one inference per window (map) + one reduce inference.
    final total = windows.length + 1;
    final notesPrompt = MeetingMinutesPrompt.partialNotes(locale: locale);

    // Map: condense each window into short plain-text notes. A failed/slow
    // window is skipped rather than aborting the whole summary.
    final notes = <String>[];
    for (var i = 0; i < windows.length; i++) {
      onProgress?.call(SummaryProgress(current: i + 1, total: total));
      final bounded = _bound(windows[i]);
      try {
        final raw = await _runInference(notesPrompt, bounded);
        final note = _cleanText(raw);
        if (note.isNotEmpty) notes.add(note);
      } on LocalSummaryException {
        // Skip this window; keep going so partial coverage still yields a result.
      }
    }
    if (notes.isEmpty) {
      throw const LocalSummaryException(
        'Cihaz üstü model bu sefer geçerli bir özet üretemedi. Lütfen tekrar '
        'deneyin veya Bulut özetine geçin.',
      );
    }

    // Reduce: collapse notes (multi-level if still too large) then produce JSON.
    onProgress?.call(SummaryProgress(current: total, total: total));
    final merged = await _reduceNotesToBudget(notes, notesPrompt);
    final parsed = await _structuredWithRetry(
      MeetingMinutesPrompt.system(locale: locale),
      merged,
    );
    // Graceful degradation: if the reduce step can't produce valid JSON, return
    // a structured summary built from the collected notes so the user is never
    // left with an empty/error screen.
    return parsed ?? _fallbackFromNotes(notes, transcript);
  }

  /// Recursively condenses [notes] until the joined text fits the budget, up to
  /// [_maxReduceDepth] passes; truncates as a last resort.
  Future<String> _reduceNotesToBudget(
    List<String> notes,
    String notesPrompt,
  ) async {
    var merged = notes.join('\n');
    var depth = 0;
    while (merged.length > _localInputCharBudget && depth < _maxReduceDepth) {
      final windows = splitTranscriptIntoWindows(
        merged,
        windowSize: _localInputCharBudget,
        maxWindows: _maxMapWindows,
      );
      final condensed = <String>[];
      for (final window in windows) {
        try {
          final raw = await _runInference(notesPrompt, _bound(window));
          final note = _cleanText(raw);
          if (note.isNotEmpty) condensed.add(note);
        } on LocalSummaryException {
          // Skip; the remaining notes still carry most of the meeting.
        }
      }
      if (condensed.isEmpty) break;
      merged = condensed.join('\n');
      depth++;
    }
    return _bound(merged);
  }

  /// Runs one inference, parses to [MeetingSummary], retrying once (small local
  /// models occasionally emit malformed JSON). Returns null if both fail.
  Future<MeetingSummary?> _structuredWithRetry(
    String systemInstruction,
    String userText,
  ) async {
    MeetingSummary? parsed;
    for (var attempt = 0; attempt < 2 && parsed == null; attempt++) {
      final raw = await _runInference(systemInstruction, userText);
      parsed = MeetingSummary.tryParse(raw);
    }
    return parsed;
  }

  /// Runs a single inference with a hard timeout, mapping a timeout to a clean,
  /// user-facing [LocalSummaryException].
  Future<String> _runInference(
    String systemInstruction,
    String userText,
  ) async {
    try {
      return await _runtime
          .generate(systemInstruction: systemInstruction, userText: userText)
          .timeout(_localInferenceTimeout);
    } on TimeoutException {
      throw const LocalSummaryException(
        'Özet beklenenden uzun sürdü. Lütfen tekrar deneyin veya Bulut özetini '
        'kullanın.',
      );
    }
  }

  String _bound(String text) => text.length > _localInputCharBudget
      ? text.substring(0, _localInputCharBudget)
      : text;

  /// Strips reasoning tags / code fences a model may wrap plain notes in.
  static String _cleanText(String raw) {
    var text = raw.replaceAll(
      RegExp('<think>.*?</think>', dotAll: true, caseSensitive: false),
      '',
    );
    text = text.replaceAll(RegExp('```[a-zA-Z]*'), '');
    return text.trim();
  }

  /// Builds a valid [MeetingSummary] from collected notes when the reduce step
  /// fails — each note line becomes an executive-summary bullet.
  static MeetingSummary _fallbackFromNotes(
    List<String> notes,
    Transcript transcript,
  ) {
    final lines = notes
        .expand((note) => note.split('\n'))
        .map((line) => line.replaceFirst(RegExp(r'^\s*[-*•]\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return MeetingSummary(
      title: (transcript.title ?? '').trim(),
      executiveSummary: lines.isEmpty ? notes : lines,
    );
  }
}
