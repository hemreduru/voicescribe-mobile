import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:voicescribe_mobile/data/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/models/transcript_extensions.dart';
import 'package:voicescribe_mobile/domain/repositories/auth_repository.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/domain/utils/text_utils.dart';
import 'package:voicescribe_mobile/ui/core/utils/logger.dart';

part 'recording_bloc.freezed.dart';

// =============================================================================
// Events
// =============================================================================

sealed class RecordingEvent {
  const RecordingEvent();
}

final class RecordingSubscriptionRequested extends RecordingEvent {
  const RecordingSubscriptionRequested();
}

final class RecordingStarted extends RecordingEvent {
  const RecordingStarted(this.title);

  final String? title;
}

final class RecordingStopped extends RecordingEvent {
  const RecordingStopped();
}

final class RecordingPauseToggled extends RecordingEvent {
  const RecordingPauseToggled();
}

final class RecordingTitleChanged extends RecordingEvent {
  const RecordingTitleChanged(this.title);

  final String title;
}

final class RecordingChunkRetryRequested extends RecordingEvent {
  const RecordingChunkRetryRequested({
    required this.transcriptId,
    required this.chunkIds,
  });

  final String transcriptId;
  final List<String> chunkIds;
}

final class _RecordingSnapshotChanged extends RecordingEvent {
  const _RecordingSnapshotChanged(this.snapshot);

  final TranscriptSnapshot snapshot;
}

final class _RecordingAudioChunkReceived extends RecordingEvent {
  const _RecordingAudioChunkReceived(this.chunk);

  final RecordedAudioChunk chunk;
}

final class _RecordingAudioLevelChanged extends RecordingEvent {
  const _RecordingAudioLevelChanged(this.level);

  final double level;
}

final class _RecordingDurationTicked extends RecordingEvent {
  const _RecordingDurationTicked();
}

final class _RecordingTranscriptionSucceeded extends RecordingEvent {
  const _RecordingTranscriptionSucceeded({
    required this.chunkId,
    required this.text,
  });

  final String chunkId;
  final String text;
}

final class _RecordingTranscriptionFailed extends RecordingEvent {
  const _RecordingTranscriptionFailed({
    required this.chunkId,
    required this.error,
  });

  final String chunkId;
  final Object error;
}

// =============================================================================
// State
// =============================================================================

@freezed
abstract class RecordingState with _$RecordingState {
  const factory RecordingState({
    @Default(<Transcript>[]) List<Transcript> transcripts,
    @Default(<TranscriptChunk>[]) List<TranscriptChunk> allChunks,
    Transcript? currentTranscript,
    @Default(<TranscriptChunk>[]) List<TranscriptChunk> currentChunks,
    @Default(false) bool isRecording,
    @Default(false) bool isPaused,
    @Default(0) int durationSeconds,
    @Default(0) int chunkCount,
    @Default(0.0) double audioLevel,
    @Default('') String liveTranscriptPreview,
    String? errorMessage,
    String? userMessage,
    @Default(<String>{}) Set<String> retryingChunkIds,
  }) = _RecordingState;
}

// =============================================================================
// Bloc
// =============================================================================

class RecordingBloc extends Bloc<RecordingEvent, RecordingState> {
  RecordingBloc({
    required TranscriptRepository transcriptRepository,
    required RecordingService recordingService,
    required TranscriptionService transcriptionService,
    required AuthRepository authRepository,
    required SyncQueueService syncQueueService,
  }) : _transcriptRepository = transcriptRepository,
       _recordingService = recordingService,
       _transcriptionService = transcriptionService,
       _authRepository = authRepository,
       _syncQueueService = syncQueueService,
       super(const RecordingState()) {
    on<RecordingSubscriptionRequested>(_onSubscriptionRequested);
    on<RecordingStarted>(_onStarted, transformer: droppable());
    on<RecordingStopped>(_onStopped, transformer: sequential());
    on<RecordingPauseToggled>(_onPauseToggled, transformer: droppable());
    on<RecordingTitleChanged>(_onTitleChanged);
    on<RecordingChunkRetryRequested>(_onChunkRetryRequested);
    on<_RecordingSnapshotChanged>(_onSnapshotChanged);
    on<_RecordingAudioChunkReceived>(_onAudioChunkReceived);
    on<_RecordingAudioLevelChanged>(_onAudioLevelChanged);
    on<_RecordingDurationTicked>(_onDurationTicked);
    on<_RecordingTranscriptionSucceeded>(_onTranscriptionSucceeded);
    on<_RecordingTranscriptionFailed>(_onTranscriptionFailed);

    _chunkSubscription = _recordingService.chunks.listen(
      (chunk) => add(_RecordingAudioChunkReceived(chunk)),
    );
    _levelSubscription = _recordingService.levels.listen(
      (level) => add(_RecordingAudioLevelChanged(level)),
    );
  }

  final TranscriptRepository _transcriptRepository;
  final RecordingService _recordingService;
  final TranscriptionService _transcriptionService;
  final AuthRepository _authRepository;
  final SyncQueueService _syncQueueService;

  StreamSubscription<TranscriptSnapshot>? _snapshotSubscription;
  StreamSubscription<RecordedAudioChunk>? _chunkSubscription;
  StreamSubscription<double>? _levelSubscription;
  Timer? _durationTimer;
  // Serialized DB-save queue so out-of-order writes for the same row never
  // race (e.g. an "empty text" insert clobbering a "transcribed text" insert).
  Future<void> _pendingSave = Future<void>.value();
  DateTime? _lastAudioLevelNotifyAt;
  double _lastNotifiedAudioLevel = 0;

  static const Duration _audioLevelNotifyInterval = Duration(milliseconds: 120);
  static const int _maxLivePreviewChars = 500;

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  Future<void> _onSubscriptionRequested(
    RecordingSubscriptionRequested event,
    Emitter<RecordingState> emit,
  ) async {
    await _snapshotSubscription?.cancel();
    final snapshot = await _transcriptRepository.loadSnapshot();
    emit(_stateForSnapshot(state, snapshot));
    _snapshotSubscription = _transcriptRepository.watchSnapshot().listen(
      (snapshot) => add(_RecordingSnapshotChanged(snapshot)),
      onError: (Object error, StackTrace stack) {
        AppLogger.error('[Recording] Snapshot stream error', error, stack);
      },
    );

    // Recover chunks that were never transcribed (app killed mid-recording).
    final inFlight = <String>{...state.retryingChunkIds};
    for (final chunk in snapshot.chunks) {
      if (chunk.isTranscribed || chunk.transcriptionError != null) {
        continue;
      }
      final audioPath = chunk.audioPath;
      if (audioPath == null || audioPath.isEmpty) {
        continue;
      }
      if (inFlight.contains(chunk.id)) {
        continue;
      }
      inFlight.add(chunk.id);
      AppLogger.info(
        '[Recording] Recovering pending chunk | id=${chunk.id} | path=$audioPath',
      );
      unawaited(_transcribe(chunk));
    }
    if (inFlight.length != state.retryingChunkIds.length) {
      emit(state.copyWith(retryingChunkIds: inFlight));
    }
  }

  Future<void> _onStarted(
    RecordingStarted event,
    Emitter<RecordingState> emit,
  ) async {
    if (state.isRecording) {
      return;
    }
    final session = _authRepository.currentSession();
    if (session?.isAuthenticated != true) {
      emit(state.copyWith(userMessage: 'Authentication is required.'));
      return;
    }

    final transcript = _newSession(event.title, userId: session?.userId);
    emit(
      state.copyWith(
        transcripts: [transcript, ...state.transcripts],
        currentTranscript: transcript,
        currentChunks: const [],
        isRecording: true,
        isPaused: false,
        durationSeconds: 0,
        chunkCount: 0,
        audioLevel: 0,
        liveTranscriptPreview: '',
        errorMessage: null,
        userMessage: null,
      ),
    );

    try {
      await _recordingService.start();
      _startTimer();
      await _enqueueSave(
        () => _transcriptRepository.saveTranscript(transcript),
      );
      AppLogger.info('[Recording] Session started | id=${transcript.id}');
    } catch (error, stackTrace) {
      AppLogger.error(
        '[Recording] Failed to start session | id=${transcript.id}',
        error,
        stackTrace,
      );
      emit(
        state.copyWith(
          transcripts: state.transcripts
              .where((item) => item.id != transcript.id)
              .toList(),
          currentTranscript: null,
          currentChunks: const [],
          isRecording: false,
          isPaused: false,
          durationSeconds: 0,
          chunkCount: 0,
          audioLevel: 0,
          userMessage: _userMessageFor(error),
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onStopped(
    RecordingStopped event,
    Emitter<RecordingState> emit,
  ) async {
    if (!state.isRecording) {
      return;
    }
    final recordedDurationSeconds = state.durationSeconds;
    _stopTimer();
    await _recordingService.stop();

    final current = state.currentTranscript;
    if (current == null) {
      emit(
        state.copyWith(
          isRecording: false,
          isPaused: false,
          durationSeconds: 0,
          chunkCount: 0,
          audioLevel: 0,
          liveTranscriptPreview: '',
        ),
      );
      return;
    }

    final stopped = current.markPendingSync(
      status: TranscriptStatus.deriveFromChunks(state.currentChunks),
      durationSeconds: recordedDurationSeconds,
    );
    emit(
      _replaceTranscript(
        state.copyWith(
          currentTranscript: stopped,
          isRecording: false,
          isPaused: false,
          durationSeconds: 0,
          chunkCount: 0,
          audioLevel: 0,
          liveTranscriptPreview: '',
        ),
        stopped,
      ),
    );
    unawaited(_enqueueSave(() => _transcriptRepository.saveTranscript(stopped)));
    _syncQueueService.scheduleSync();
    AppLogger.info(
      '[Recording] Session stopped | id=${stopped.id} | '
      'duration=${recordedDurationSeconds}s | chunks=${state.currentChunks.length} | '
      'status=${stopped.status.key}',
    );
  }

  Future<void> _onPauseToggled(
    RecordingPauseToggled event,
    Emitter<RecordingState> emit,
  ) async {
    if (!state.isRecording) {
      return;
    }
    if (state.isPaused) {
      await _recordingService.resume();
      emit(state.copyWith(isPaused: false));
      _startTimer();
      AppLogger.info('[Recording] Resumed');
    } else {
      await _recordingService.pause();
      emit(state.copyWith(isPaused: true));
      _stopTimer();
      // Persist the duration accumulated up to this pause so we don't lose
      // it if the app dies while paused.
      final transcript = state.currentTranscript;
      if (transcript != null) {
        final updated = transcript.markPendingSync(
          durationSeconds: state.durationSeconds,
        );
        emit(
          _replaceTranscript(
            state.copyWith(currentTranscript: updated),
            updated,
          ),
        );
        unawaited(
          _enqueueSave(() => _transcriptRepository.saveTranscript(updated)),
        );
      }
      AppLogger.info('[Recording] Paused | duration=${state.durationSeconds}s');
    }
  }

  Future<void> _onTitleChanged(
    RecordingTitleChanged event,
    Emitter<RecordingState> emit,
  ) async {
    final transcript = state.currentTranscript;
    if (transcript == null) {
      return;
    }
    final normalized = event.title.trim();
    final updated = transcript.markPendingSync(
      title: normalized.isEmpty ? null : normalized,
      overrideTitle: true,
    );
    emit(
      _replaceTranscript(state.copyWith(currentTranscript: updated), updated),
    );
    unawaited(
      _enqueueSave(() => _transcriptRepository.saveTranscript(updated)),
    );
    _syncQueueService.scheduleSync();
  }

  Future<void> _onChunkRetryRequested(
    RecordingChunkRetryRequested event,
    Emitter<RecordingState> emit,
  ) async {
    final chunks = state.allChunks
        .where(
          (chunk) =>
              chunk.transcriptId == event.transcriptId &&
              event.chunkIds.contains(chunk.id) &&
              chunk.text.isEmpty &&
              chunk.transcriptionError != null &&
              chunk.audioPath != null &&
              chunk.audioPath!.isNotEmpty &&
              !state.retryingChunkIds.contains(chunk.id),
        )
        .toList();

    if (chunks.isEmpty) {
      return;
    }

    final retryingIds = <String>{...state.retryingChunkIds};
    for (final chunk in chunks) {
      retryingIds.add(chunk.id);
      AppLogger.info(
        '[Recording] Retrying chunk | id=${chunk.id} | path=${chunk.audioPath}',
      );
      unawaited(_transcribe(chunk));
    }
    emit(state.copyWith(retryingChunkIds: retryingIds));

    final transcript = state.transcripts
        .where((t) => t.id == event.transcriptId)
        .firstOrNull;
    if (transcript != null) {
      final updated = transcript.markPendingSync(
        status: TranscriptStatus.transcribing,
      );
      emit(
        _replaceTranscript(state.copyWith(currentTranscript: updated), updated),
      );
      unawaited(
        _enqueueSave(() => _transcriptRepository.saveTranscript(updated)),
      );
      _syncQueueService.scheduleSync();
    }
  }

  void _onSnapshotChanged(
    _RecordingSnapshotChanged event,
    Emitter<RecordingState> emit,
  ) {
    emit(_stateForSnapshot(state, event.snapshot));
  }

  void _onAudioChunkReceived(
    _RecordingAudioChunkReceived event,
    Emitter<RecordingState> emit,
  ) {
    final transcript = state.currentTranscript;
    if (transcript == null) {
      return;
    }

    final previousEnd = state.currentChunks.isEmpty
        ? 0.0
        : state.currentChunks.last.endTime;
    final now = DateTime.now();
    final chunk = TranscriptChunk(
      id: '${transcript.id}-chunk-${state.currentChunks.length + 1}',
      transcriptId: transcript.id,
      chunkIndex: state.currentChunks.length + 1,
      text: '',
      audioPath: event.chunk.path,
      recordedAt: now,
      startTime: previousEnd,
      endTime: previousEnd + event.chunk.durationSeconds,
      confidence: null,
      transcriptionError: null,
      audioLevel: event.chunk.averageLevel,
    );
    final chunks = [...state.currentChunks, chunk];
    final allChunks = [...state.allChunks, chunk];
    final updatedTranscript = transcript.markPendingSync(
      status: TranscriptStatus.transcribing,
      durationSeconds: chunk.endTime.round(),
    );
    final retryingIds = <String>{...state.retryingChunkIds, chunk.id};
    emit(
      _replaceTranscript(
        state.copyWith(
          currentTranscript: updatedTranscript,
          currentChunks: chunks,
          allChunks: allChunks,
          chunkCount: state.chunkCount + 1,
          errorMessage: null,
          retryingChunkIds: retryingIds,
        ),
        updatedTranscript,
      ),
    );
    unawaited(
      _enqueueSave(() async {
        await _transcriptRepository.saveChunk(chunk);
        await _transcriptRepository.saveTranscript(updatedTranscript);
      }),
    );
    AppLogger.info(
      '[Recording] Chunk received | id=${chunk.id} | '
      'index=${chunk.chunkIndex} | duration=${event.chunk.durationSeconds.toStringAsFixed(2)}s',
    );
    unawaited(_transcribe(chunk));
  }

  void _onAudioLevelChanged(
    _RecordingAudioLevelChanged event,
    Emitter<RecordingState> emit,
  ) {
    final now = DateTime.now();
    final previousAt = _lastAudioLevelNotifyAt;
    final previousLevel = _lastNotifiedAudioLevel;
    final isResetEvent = event.level <= 0.01 && previousLevel > 0.01;
    final changedEnough = (event.level - previousLevel).abs() >= 0.06;
    final elapsedEnough =
        previousAt == null ||
        now.difference(previousAt) >= _audioLevelNotifyInterval;
    if (!(isResetEvent || changedEnough || elapsedEnough)) {
      return;
    }
    _lastAudioLevelNotifyAt = now;
    _lastNotifiedAudioLevel = event.level;
    emit(state.copyWith(audioLevel: event.level));
  }

  void _onDurationTicked(
    _RecordingDurationTicked event,
    Emitter<RecordingState> emit,
  ) {
    if (!state.isRecording || state.isPaused) {
      return;
    }
    // Only updates the in-memory counter for the UI; persistence happens on
    // chunk receive, pause, and stop to keep DB writes off the per-second
    // hot path.
    emit(state.copyWith(durationSeconds: state.durationSeconds + 1));
  }

  void _onTranscriptionSucceeded(
    _RecordingTranscriptionSucceeded event,
    Emitter<RecordingState> emit,
  ) {
    final retryingIds = <String>{...state.retryingChunkIds}
      ..remove(event.chunkId);
    emit(state.copyWith(retryingChunkIds: retryingIds));

    final current = state.allChunks
        .where((item) => item.id == event.chunkId)
        .firstOrNull;
    if (current == null) {
      return;
    }
    final previousChunk = state.currentChunks
        .where((item) => item.chunkIndex == current.chunkIndex - 1)
        .firstOrNull;
    final normalized = normalizeWhitespace(event.text);
    final deduped = previousChunk == null
        ? normalized
        : removeOverlap(previousChunk.text, normalized);
    AppLogger.info(
      '[Recording] Transcribe ok | id=${current.id} | chars=${deduped.length}',
    );
    _emitChunkUpdate(
      emit,
      current.copyWith(
        text: deduped,
        transcriptionError: null,
        isTranscribed: true,
        syncStatus: SyncStatus.pending,
        syncError: null,
      ),
      appendPreview: deduped,
    );
  }

  void _onTranscriptionFailed(
    _RecordingTranscriptionFailed event,
    Emitter<RecordingState> emit,
  ) {
    final retryingIds = <String>{...state.retryingChunkIds}
      ..remove(event.chunkId);
    emit(state.copyWith(retryingChunkIds: retryingIds));

    final current = state.allChunks
        .where((item) => item.id == event.chunkId)
        .firstOrNull;
    if (current == null) {
      return;
    }
    final message = event.error.toString();
    _emitChunkUpdate(
      emit,
      current.copyWith(
        transcriptionError: message,
        isTranscribed: true,
        syncStatus: SyncStatus.pending,
        syncError: null,
      ),
      errorMessage: message,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _emitChunkUpdate(
    Emitter<RecordingState> emit,
    TranscriptChunk updatedChunk, {
    String? appendPreview,
    String? errorMessage,
  }) {
    final currentChunks = state.currentChunks
        .map((item) => item.id == updatedChunk.id ? updatedChunk : item)
        .toList();
    final allChunks = state.allChunks
        .map((item) => item.id == updatedChunk.id ? updatedChunk : item)
        .toList();
    final transcript = state.transcripts
        .where((item) => item.id == updatedChunk.transcriptId)
        .firstOrNull;
    if (transcript == null) {
      return;
    }
    final updatedTranscript = transcript.markPendingSync(
      status: TranscriptStatus.deriveFromChunks(currentChunks),
    );
    final livePreview = appendPreview == null || appendPreview.trim().isEmpty
        ? state.liveTranscriptPreview
        : _appendPreview(state.liveTranscriptPreview, appendPreview);
    emit(
      _replaceTranscript(
        state.copyWith(
          allChunks: allChunks,
          currentChunks: currentChunks,
          currentTranscript: updatedTranscript,
          liveTranscriptPreview: livePreview,
          errorMessage: errorMessage,
        ),
        updatedTranscript,
      ),
    );
    // Funnel through the save chain so an out-of-order earlier write of the
    // same chunk can't clobber this update (which would re-write text='' and
    // pin the transcript to `transcribing` forever).
    unawaited(
      _enqueueSave(() async {
        await _transcriptRepository.saveChunk(updatedChunk);
        await _transcriptRepository.saveTranscript(updatedTranscript);
      }),
    );
    if (updatedTranscript.status != TranscriptStatus.transcribing) {
      _syncQueueService.scheduleSync();
    }
  }

  RecordingState _stateForSnapshot(
    RecordingState currentState,
    TranscriptSnapshot snapshot,
  ) {
    final active = currentState.currentTranscript;
    if (active == null) {
      return currentState.copyWith(
        transcripts: snapshot.transcripts,
        allChunks: snapshot.chunks,
      );
    }

    // Preserve the in-memory active session, but fold in any sync metadata
    // (remoteId, lastSyncedAt) the DB already knew about. Without this merge
    // a sync that lands mid-recording would wipe our just-emitted chunks.
    final savedTranscript = snapshot.transcripts
        .where((item) => item.id == active.id)
        .firstOrNull;
    final preservedTranscript = active.copyWith(
      remoteId: active.remoteId ?? savedTranscript?.remoteId,
      lastSyncedAt: active.lastSyncedAt ?? savedTranscript?.lastSyncedAt,
    );
    final savedChunksById = {
      for (final chunk in snapshot.chunks) chunk.id: chunk,
    };
    final preservedCurrentChunks = currentState.currentChunks
        .map(
          (chunk) => chunk.copyWith(
            remoteId: chunk.remoteId ?? savedChunksById[chunk.id]?.remoteId,
            lastSyncedAt:
                chunk.lastSyncedAt ?? savedChunksById[chunk.id]?.lastSyncedAt,
          ),
        )
        .toList(growable: false);
    final transcripts = [
      preservedTranscript,
      for (final transcript in snapshot.transcripts)
        if (transcript.id != preservedTranscript.id) transcript,
    ];
    final allChunks = [
      for (final chunk in snapshot.chunks)
        if (chunk.transcriptId != preservedTranscript.id) chunk,
      ...preservedCurrentChunks,
    ];
    return currentState.copyWith(
      transcripts: transcripts,
      allChunks: allChunks,
      currentTranscript: preservedTranscript,
      currentChunks: preservedCurrentChunks,
    );
  }

  Transcript _newSession(String? title, {String? userId}) {
    final now = DateTime.now();
    final id = 'local-${now.microsecondsSinceEpoch}';
    final trimmed = title?.trim();
    return Transcript(
      id: id,
      localId: id,
      title: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      durationSeconds: 0,
      status: TranscriptStatus.recording,
      recordedAt: now,
      createdAt: now,
      updatedAt: now,
      userId: userId,
    );
  }

  RecordingState _replaceTranscript(
    RecordingState base,
    Transcript transcript,
  ) {
    var found = false;
    final transcripts = base.transcripts.map((item) {
      if (item.id != transcript.id) {
        return item;
      }
      found = true;
      return transcript;
    }).toList();
    if (!found) {
      transcripts.insert(0, transcript);
    }
    return base.copyWith(transcripts: transcripts);
  }

  Future<void> _transcribe(TranscriptChunk chunk) async {
    try {
      final transcription = await _transcriptionService.transcribeChunk(
        chunk.audioPath ?? '',
        audioLevel: chunk.audioLevel,
      );
      add(
        _RecordingTranscriptionSucceeded(
          chunkId: chunk.id,
          text: transcription.text,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        '[Recording] Transcribe failed | id=${chunk.id} | path=${chunk.audioPath}',
        error,
        stackTrace,
      );
      add(_RecordingTranscriptionFailed(chunkId: chunk.id, error: error));
    }
  }

  /// Serializes DB writes so out-of-order completions of the same row don't
  /// overwrite each other.
  Future<void> _enqueueSave(Future<void> Function() task) {
    final next = _pendingSave
        .catchError((Object error, StackTrace stack) {
          AppLogger.error('[Recording] DB save chain error', error, stack);
        })
        .then((_) => task());
    _pendingSave = next;
    return next;
  }

  String _appendPreview(String current, String value) {
    var preview = normalizeWhitespace('$current ${normalizeWhitespace(value)}');
    if (preview.length > _maxLivePreviewChars) {
      preview = preview.substring(
        math.max(0, preview.length - _maxLivePreviewChars),
      );
    }
    return preview;
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const _RecordingDurationTicked());
    });
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  String _userMessageFor(Object error) {
    if (error is RecordingPermissionException) {
      return 'Microphone permission is required.';
    }
    return error.toString();
  }

  @override
  Future<void> close() async {
    _stopTimer();
    await _snapshotSubscription?.cancel();
    await _chunkSubscription?.cancel();
    await _levelSubscription?.cancel();
    return super.close();
  }
}
