import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:voicescribe_mobile/data/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/auth_repository.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/domain/utils/text_utils.dart';

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

class RecordingState {
  const RecordingState({
    this.transcripts = const [],
    this.allChunks = const [],
    this.currentTranscript,
    this.currentChunks = const [],
    this.isRecording = false,
    this.isPaused = false,
    this.durationSeconds = 0,
    this.chunkCount = 0,
    this.audioLevel = 0,
    this.liveTranscriptPreview = '',
    this.errorMessage,
    this.userMessage,
  });

  final List<Transcript> transcripts;
  final List<TranscriptChunk> allChunks;
  final Transcript? currentTranscript;
  final List<TranscriptChunk> currentChunks;
  final bool isRecording;
  final bool isPaused;
  final int durationSeconds;
  final int chunkCount;
  final double audioLevel;
  final String liveTranscriptPreview;
  final String? errorMessage;
  final String? userMessage;

  RecordingState copyWith({
    List<Transcript>? transcripts,
    List<TranscriptChunk>? allChunks,
    Transcript? currentTranscript,
    bool clearCurrentTranscript = false,
    List<TranscriptChunk>? currentChunks,
    bool? isRecording,
    bool? isPaused,
    int? durationSeconds,
    int? chunkCount,
    double? audioLevel,
    String? liveTranscriptPreview,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? userMessage,
    bool clearUserMessage = false,
  }) {
    return RecordingState(
      transcripts: transcripts ?? this.transcripts,
      allChunks: allChunks ?? this.allChunks,
      currentTranscript: clearCurrentTranscript
          ? null
          : currentTranscript ?? this.currentTranscript,
      currentChunks: currentChunks ?? this.currentChunks,
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      chunkCount: chunkCount ?? this.chunkCount,
      audioLevel: audioLevel ?? this.audioLevel,
      liveTranscriptPreview:
          liveTranscriptPreview ?? this.liveTranscriptPreview,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      userMessage: clearUserMessage ? null : userMessage ?? this.userMessage,
    );
  }
}

class RecordingBloc extends Bloc<RecordingEvent, RecordingState> {
  RecordingBloc({
    required TranscriptRepository transcriptRepository,
    required RecordingService recordingService,
    required TranscriptionService transcriptionService,
    required AuthRepository authRepository,
  }) : _transcriptRepository = transcriptRepository,
       _recordingService = recordingService,
       _transcriptionService = transcriptionService,
       _authRepository = authRepository,
       super(const RecordingState()) {
    on<RecordingSubscriptionRequested>(_onSubscriptionRequested);
    on<RecordingStarted>(_onStarted, transformer: droppable());
    on<RecordingStopped>(_onStopped, transformer: sequential());
    on<RecordingPauseToggled>(_onPauseToggled, transformer: droppable());
    on<RecordingTitleChanged>(_onTitleChanged);
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

  StreamSubscription<TranscriptSnapshot>? _snapshotSubscription;
  StreamSubscription<RecordedAudioChunk>? _chunkSubscription;
  StreamSubscription<double>? _levelSubscription;
  Timer? _durationTimer;
  Future<void> _pendingTranscriptSave = Future<void>.value();
  DateTime? _lastAudioLevelNotifyAt;
  double _lastNotifiedAudioLevel = 0;

  static const Duration _audioLevelNotifyInterval = Duration(milliseconds: 120);

  Future<void> _onSubscriptionRequested(
    RecordingSubscriptionRequested event,
    Emitter<RecordingState> emit,
  ) async {
    await _snapshotSubscription?.cancel();
    final snapshot = await _transcriptRepository.loadSnapshot();
    emit(_stateForSnapshot(state, snapshot));
    _snapshotSubscription = _transcriptRepository.watchSnapshot().listen(
      (snapshot) => add(_RecordingSnapshotChanged(snapshot)),
    );
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

    final transcript = _startSession(event.title, userId: session?.userId);
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
        clearErrorMessage: true,
        clearUserMessage: true,
      ),
    );

    try {
      await _recordingService.start();
      _startTimer();
      await _saveTranscript(transcript);
    } catch (error) {
      emit(
        state.copyWith(
          transcripts: state.transcripts
              .where((item) => item.id != transcript.id)
              .toList(),
          clearCurrentTranscript: true,
          currentChunks: const [],
          isRecording: false,
          isPaused: false,
          durationSeconds: 0,
          chunkCount: 0,
          audioLevel: 0,
          userMessage: _messageFor(error),
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

    final stopped = current.copyWith(
      status: _aggregateStatus(state.currentChunks),
      durationSeconds: recordedDurationSeconds,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      syncError: null,
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
    unawaited(_saveTranscript(stopped));
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
    } else {
      await _recordingService.pause();
      emit(state.copyWith(isPaused: true));
      _stopTimer();
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
    final updated = transcript.copyWith(
      title: normalized.isEmpty ? null : normalized,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      syncError: null,
    );
    emit(
      _replaceTranscript(state.copyWith(currentTranscript: updated), updated),
    );
    unawaited(_saveTranscript(updated));
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
    );
    final chunks = [...state.currentChunks, chunk];
    final allChunks = [...state.allChunks, chunk];
    final updatedTranscript = transcript.copyWith(
      status: TranscriptStatus.transcribing,
      durationSeconds: chunk.endTime.round(),
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      syncError: null,
    );
    emit(
      _replaceTranscript(
        state.copyWith(
          currentTranscript: updatedTranscript,
          currentChunks: chunks,
          allChunks: allChunks,
          chunkCount: state.chunkCount + 1,
          clearErrorMessage: true,
        ),
        updatedTranscript,
      ),
    );
    unawaited(_saveChunkAndTranscript(chunk, updatedTranscript));
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
    final transcript = state.currentTranscript;
    if (transcript == null) {
      return;
    }
    final duration = state.durationSeconds + 1;
    final updated = transcript.copyWith(
      durationSeconds: duration,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      syncError: null,
    );
    emit(
      _replaceTranscript(
        state.copyWith(durationSeconds: duration, currentTranscript: updated),
        updated,
      ),
    );
    unawaited(_saveTranscript(updated));
  }

  void _onTranscriptionSucceeded(
    _RecordingTranscriptionSucceeded event,
    Emitter<RecordingState> emit,
  ) {
    final chunk = state.allChunks.where((item) => item.id == event.chunkId);
    if (chunk.isEmpty) {
      return;
    }
    final current = chunk.first;
    final previousChunk = state.currentChunks
        .where((item) => item.chunkIndex == current.chunkIndex - 1)
        .firstOrNull;
    final normalized = normalizeWhitespace(event.text);
    final deduped = previousChunk == null
        ? normalized
        : removeOverlap(previousChunk.text, normalized);
    _updateChunkAndTranscript(
      emit,
      current.copyWith(
        text: deduped,
        transcriptionError: null,
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
    final chunk = state.allChunks.where((item) => item.id == event.chunkId);
    if (chunk.isEmpty) {
      return;
    }
    _updateChunkAndTranscript(
      emit,
      chunk.first.copyWith(
        transcriptionError: event.error.toString(),
        syncStatus: SyncStatus.pending,
        syncError: null,
      ),
      errorMessage: event.error.toString(),
    );
  }

  void _updateChunkAndTranscript(
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
    final updatedTranscript = transcript.copyWith(
      status: _aggregateStatus(currentChunks),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      syncError: null,
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
          clearErrorMessage: errorMessage == null,
        ),
        updatedTranscript,
      ),
    );
    unawaited(_transcriptRepository.saveChunk(updatedChunk));
    unawaited(_saveTranscript(updatedTranscript));
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

  Transcript _startSession(String? title, {String? userId}) {
    final now = DateTime.now();
    final id = 'local-${now.microsecondsSinceEpoch}';
    return Transcript(
      id: id,
      localId: id,
      title: title?.trim().isNotEmpty ?? false ? title!.trim() : null,
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

  TranscriptStatus _aggregateStatus(List<TranscriptChunk> chunks) {
    if (chunks.isEmpty) {
      return TranscriptStatus.empty;
    }
    final hasPending = chunks.any(
      (chunk) =>
          chunk.text.trim().isEmpty && (chunk.transcriptionError ?? '').isEmpty,
    );
    if (hasPending) {
      return TranscriptStatus.transcribing;
    }
    if (chunks.any((chunk) => (chunk.transcriptionError ?? '').isNotEmpty)) {
      return TranscriptStatus.transcriptionError;
    }
    if (chunks.any((chunk) => chunk.text.trim().isNotEmpty)) {
      return TranscriptStatus.completed;
    }
    return TranscriptStatus.empty;
  }

  Future<void> _transcribe(TranscriptChunk chunk) async {
    try {
      final transcription = await _transcriptionService.transcribeChunk(
        chunk.audioPath ?? '',
      );
      add(
        _RecordingTranscriptionSucceeded(
          chunkId: chunk.id,
          text: transcription.text,
        ),
      );
    } catch (error) {
      add(_RecordingTranscriptionFailed(chunkId: chunk.id, error: error));
    }
  }

  Future<void> _saveTranscript(Transcript transcript) {
    final next = _pendingTranscriptSave.catchError((_) {}).then((_) {
      return _transcriptRepository.saveTranscript(transcript);
    });
    _pendingTranscriptSave = next;
    return next;
  }

  Future<void> _saveChunkAndTranscript(
    TranscriptChunk chunk,
    Transcript transcript,
  ) {
    final next = _pendingTranscriptSave.catchError((_) {}).then((_) async {
      await _transcriptRepository.saveChunk(chunk);
      await _transcriptRepository.saveTranscript(transcript);
    });
    _pendingTranscriptSave = next;
    return next;
  }

  String _appendPreview(String current, String value) {
    var preview = normalizeWhitespace('$current ${normalizeWhitespace(value)}');
    if (preview.length > 500) {
      preview = preview.substring(math.max(0, preview.length - 500));
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

  String _messageFor(Object error) {
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
