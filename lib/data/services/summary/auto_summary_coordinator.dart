import 'dart:async';

import 'package:voicescribe_mobile/data/services/llm/llm_model_service.dart';
import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/domain/use_cases/generate_summary.dart';
import 'package:voicescribe_mobile/domain/utils/text_utils.dart';
import 'package:voicescribe_mobile/ui/core/utils/logger.dart';

/// Watches the transcript snapshot stream and **auto-generates a summary** as
/// soon as a recording finishes transcribing — the proactive behavior every
/// competitor ships (Plaud AutoFlow, Granola). The manual "Generate summary"
/// button still works; this just removes the need to press it.
///
/// Gated by [AppPreferences.autoSummarize] (default on). A summary is started
/// for a transcript only when:
/// - it is fully transcribed (`completed`) with non-empty text,
/// - it has no summary yet,
/// - it isn't already being summarized (here or, best-effort, manually), and
/// - the chosen engine is usable: the on-device model is downloaded/supported,
///   or — for cloud — the transcript is already synced and a token is present.
///
/// The snapshot stream re-fires when sync metadata lands, so a cloud summary
/// that wasn't yet synced is picked up automatically once `remoteId` appears
/// (no separate queue needed). Failures are remembered for the session so a
/// broken engine isn't hammered every snapshot.
class AutoSummaryCoordinator {
  AutoSummaryCoordinator({
    required TranscriptRepository transcriptRepository,
    required SummaryService summaryService,
    required LocalLlmModelService localLlmModelService,
    required String? Function() tokenProvider,
  }) : _transcriptRepository = transcriptRepository,
       _summaryService = summaryService,
       _localLlmModelService = localLlmModelService,
       _tokenProvider = tokenProvider;

  final TranscriptRepository _transcriptRepository;
  final SummaryService _summaryService;
  final LocalLlmModelService _localLlmModelService;
  final String? Function() _tokenProvider;

  StreamSubscription<TranscriptSnapshot>? _subscription;

  /// Transcript ids with an in-flight auto-summary (prevents double runs).
  final Set<String> _inFlight = <String>{};

  /// Transcript ids whose auto-summary failed this session — not retried
  /// automatically (the user can still trigger it manually).
  final Set<String> _failed = <String>{};

  void start() {
    _subscription ??= _transcriptRepository.watchSnapshot().listen(
      _onSnapshot,
      onError: (Object error, StackTrace stack) {
        AppLogger.error('[AutoSummary] Snapshot stream error', error, stack);
      },
    );
  }

  void _onSnapshot(TranscriptSnapshot snapshot) {
    if (!snapshot.preferences.autoSummarize) {
      return;
    }
    for (final transcript in snapshot.transcripts) {
      if (!_isCandidate(transcript, snapshot)) {
        continue;
      }
      _inFlight.add(transcript.id);
      unawaited(_run(transcript, snapshot.preferences));
    }
  }

  /// Cheap, synchronous gate. Engine readiness (async) is checked in [_run].
  bool _isCandidate(Transcript transcript, TranscriptSnapshot snapshot) {
    if (transcript.status != TranscriptStatus.completed) return false;
    if (transcript.deletedAt != null) return false;
    if (_inFlight.contains(transcript.id)) return false;
    if (_failed.contains(transcript.id)) return false;
    if (snapshot.latestSummaryFor(transcript.id) != null) return false;
    final text = mergeTranscriptChunks(snapshot.chunksFor(transcript.id));
    if (text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _run(Transcript transcript, AppPreferences preferences) async {
    try {
      if (!await _engineReady(transcript, preferences)) {
        // Not ready yet (e.g. cloud transcript not synced, model not
        // downloaded). Release the id so a later snapshot can retry once the
        // engine becomes usable. Not a failure.
        _inFlight.remove(transcript.id);
        return;
      }
      // Re-read the latest snapshot text so a chunk update between the snapshot
      // and now is included.
      final latest = await _transcriptRepository.loadSnapshot();
      // A manual run (or a delete) may have happened in the meantime.
      if (latest.latestSummaryFor(transcript.id) != null) {
        _inFlight.remove(transcript.id);
        return;
      }
      final text = mergeTranscriptChunks(latest.chunksFor(transcript.id));
      if (text.trim().isEmpty) {
        _inFlight.remove(transcript.id);
        return;
      }
      AppLogger.info('[AutoSummary] Generating | id=${transcript.id}');
      await GenerateSummaryUseCase(
        repository: _transcriptRepository,
        summaryService: _summaryService,
      ).execute(
        transcript: transcript,
        transcriptText: text,
        preferences: preferences,
      );
      AppLogger.info('[AutoSummary] Done | id=${transcript.id}');
    } catch (error, stack) {
      // Remember the failure so we don't loop on a broken engine; manual
      // generation (with its own error UI) remains available.
      _failed.add(transcript.id);
      AppLogger.error(
        '[AutoSummary] Failed | id=${transcript.id}',
        error,
        stack,
      );
    } finally {
      _inFlight.remove(transcript.id);
    }
  }

  Future<bool> _engineReady(
    Transcript transcript,
    AppPreferences preferences,
  ) async {
    final useCloud =
        AppPreferences.normalizeSummaryProvider(preferences.summaryProvider) ==
        'cloud';
    if (useCloud) {
      final remoteId = transcript.remoteId?.trim();
      final token = _tokenProvider()?.trim();
      return remoteId != null &&
          remoteId.isNotEmpty &&
          token != null &&
          token.isNotEmpty;
    }
    // On-device: only attempt when the model is supported and downloaded, so we
    // never kick off a multi-hundred-MB download as a silent side effect.
    try {
      return await _localLlmModelService.isSupported() &&
          await _localLlmModelService.isDownloaded();
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
