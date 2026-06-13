import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/domain/models/app_error.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/domain/use_cases/generate_summary.dart';
import 'package:voicescribe_mobile/domain/utils/text_utils.dart';

sealed class TranscriptDetailEvent {
  const TranscriptDetailEvent();
}

final class TranscriptDetailSubscriptionRequested
    extends TranscriptDetailEvent {
  const TranscriptDetailSubscriptionRequested();
}

final class TranscriptDetailTitleSubmitted extends TranscriptDetailEvent {
  const TranscriptDetailTitleSubmitted(this.title);

  final String title;
}

final class TranscriptDetailSummaryRequested extends TranscriptDetailEvent {
  const TranscriptDetailSummaryRequested();
}

final class TranscriptDetailTabChanged extends TranscriptDetailEvent {
  const TranscriptDetailTabChanged(this.index);

  final int index;
}

final class _TranscriptDetailSnapshotChanged extends TranscriptDetailEvent {
  const _TranscriptDetailSnapshotChanged(this.snapshot);

  final TranscriptSnapshot snapshot;
}

class TranscriptDetailState {
  const TranscriptDetailState({
    required this.transcriptId,
    this.snapshot,
    this.transcript,
    this.chunks = const [],
    this.summary,
    this.mergedText = '',
    this.tabIndex = 0,
    this.generatingSummary = false,
    this.summaryProgress,
    this.errorCode,
    this.errorMessage,
    this.completedChunkCount = 0,
    this.totalChunkCount = 0,
  });

  final String transcriptId;
  final TranscriptSnapshot? snapshot;
  final Transcript? transcript;
  final List<TranscriptChunk> chunks;
  final Summary? summary;
  final String mergedText;
  final int tabIndex;
  final bool generatingSummary;

  /// Progress of an in-flight on-device summary (map-reduce over a long
  /// transcript). Null for a single-pass run with nothing useful to show.
  final SummaryProgress? summaryProgress;

  /// Machine-readable failure of the last summary attempt; the UI maps it to
  /// the active locale. [errorMessage] is kept for raw/legacy surfaces.
  final AppErrorCode? errorCode;
  final String? errorMessage;
  final int completedChunkCount;
  final int totalChunkCount;

  TranscriptDetailState copyWith({
    TranscriptSnapshot? snapshot,
    Transcript? transcript,
    bool clearTranscript = false,
    List<TranscriptChunk>? chunks,
    Summary? summary,
    bool clearSummary = false,
    String? mergedText,
    int? tabIndex,
    bool? generatingSummary,
    SummaryProgress? summaryProgress,
    bool clearSummaryProgress = false,
    AppErrorCode? errorCode,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? completedChunkCount,
    int? totalChunkCount,
  }) {
    return TranscriptDetailState(
      transcriptId: transcriptId,
      snapshot: snapshot ?? this.snapshot,
      transcript: clearTranscript ? null : transcript ?? this.transcript,
      chunks: chunks ?? this.chunks,
      summary: clearSummary ? null : summary ?? this.summary,
      mergedText: mergedText ?? this.mergedText,
      tabIndex: tabIndex ?? this.tabIndex,
      generatingSummary: generatingSummary ?? this.generatingSummary,
      summaryProgress: clearSummaryProgress
          ? null
          : summaryProgress ?? this.summaryProgress,
      errorCode: clearErrorMessage ? null : errorCode ?? this.errorCode,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      completedChunkCount: completedChunkCount ?? this.completedChunkCount,
      totalChunkCount: totalChunkCount ?? this.totalChunkCount,
    );
  }
}

class TranscriptDetailBloc
    extends Bloc<TranscriptDetailEvent, TranscriptDetailState> {
  TranscriptDetailBloc({
    required String transcriptId,
    required TranscriptRepository transcriptRepository,
    required SummaryService summaryService,
    required SyncQueueService syncQueueService,
  }) : _transcriptRepository = transcriptRepository,
       _summaryService = summaryService,
       _syncQueueService = syncQueueService,
       super(TranscriptDetailState(transcriptId: transcriptId)) {
    on<TranscriptDetailSubscriptionRequested>(_onSubscriptionRequested);
    on<_TranscriptDetailSnapshotChanged>(_onSnapshotChanged);
    on<TranscriptDetailTitleSubmitted>(_onTitleSubmitted);
    on<TranscriptDetailSummaryRequested>(_onSummaryRequested);
    on<TranscriptDetailTabChanged>(_onTabChanged);
  }

  final TranscriptRepository _transcriptRepository;
  final SummaryService _summaryService;
  final SyncQueueService _syncQueueService;
  StreamSubscription<TranscriptSnapshot>? _snapshotSubscription;

  Future<void> _onSubscriptionRequested(
    TranscriptDetailSubscriptionRequested event,
    Emitter<TranscriptDetailState> emit,
  ) async {
    await _snapshotSubscription?.cancel();
    final snapshot = await _transcriptRepository.loadSnapshot();
    emit(_stateFor(snapshot));
    _snapshotSubscription = _transcriptRepository.watchSnapshot().listen(
      (snapshot) => add(_TranscriptDetailSnapshotChanged(snapshot)),
    );
  }

  void _onSnapshotChanged(
    _TranscriptDetailSnapshotChanged event,
    Emitter<TranscriptDetailState> emit,
  ) {
    emit(_stateFor(event.snapshot));
  }

  Future<void> _onTitleSubmitted(
    TranscriptDetailTitleSubmitted event,
    Emitter<TranscriptDetailState> emit,
  ) async {
    final transcript = state.transcript;
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
    emit(state.copyWith(transcript: updated));
    await _transcriptRepository.saveTranscript(updated);
    _syncQueueService.scheduleSync();
  }

  Future<void> _onSummaryRequested(
    TranscriptDetailSummaryRequested event,
    Emitter<TranscriptDetailState> emit,
  ) async {
    final transcript = state.transcript;
    final snapshot = state.snapshot;
    if (transcript == null || snapshot == null || state.mergedText.isEmpty) {
      return;
    }
    emit(
      state.copyWith(
        generatingSummary: true,
        clearSummaryProgress: true,
        clearErrorMessage: true,
      ),
    );
    try {
      final summary =
          await GenerateSummaryUseCase(
            repository: _transcriptRepository,
            summaryService: _summaryService,
          ).execute(
            transcript: transcript,
            transcriptText: state.mergedText,
            preferences: snapshot.preferences,
            // Surface multi-step progress (long-transcript map-reduce) so the
            // UI can show "Özetleniyor… (3/7)". Fires while this handler awaits.
            onProgress: (progress) {
              if (progress.isMultiStep) {
                emit(state.copyWith(summaryProgress: progress));
              }
            },
          );
      emit(
        state.copyWith(
          summary: summary,
          clearSummary: summary == null,
          generatingSummary: false,
          clearSummaryProgress: true,
        ),
      );
      if (summary != null) {
        _syncQueueService.scheduleSync();
      }
    } catch (error) {
      // Only ever surface a machine-readable code — the UI maps it to the
      // active locale; never an exception class name or stack trace.
      emit(
        state.copyWith(
          generatingSummary: false,
          clearSummaryProgress: true,
          errorCode: error is SummaryFailure
              ? error.code
              : AppErrorCode.summaryGeneric,
          errorMessage: error is SummaryFailure ? error.message : null,
        ),
      );
    }
  }

  void _onTabChanged(
    TranscriptDetailTabChanged event,
    Emitter<TranscriptDetailState> emit,
  ) {
    emit(state.copyWith(tabIndex: event.index));
  }

  TranscriptDetailState _stateFor(TranscriptSnapshot snapshot) {
    final transcript = snapshot.transcripts
        .where((item) => item.id == state.transcriptId)
        .firstOrNull;
    final chunks = snapshot.chunksFor(state.transcriptId);
    final summary = snapshot.latestSummaryFor(state.transcriptId);
    final totalChunkCount = chunks.length;
    final completedChunkCount = chunks.where((c) => c.text.isNotEmpty).length;
    return state.copyWith(
      snapshot: snapshot,
      transcript: transcript,
      clearTranscript: transcript == null,
      chunks: chunks,
      summary: summary,
      clearSummary: summary == null,
      mergedText: mergeTranscriptChunks(chunks),
      completedChunkCount: completedChunkCount,
      totalChunkCount: totalChunkCount,
    );
  }

  @override
  Future<void> close() async {
    await _snapshotSubscription?.cancel();
    return super.close();
  }
}
