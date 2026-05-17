import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_queue_service.dart';
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
    emit(state.copyWith(generatingSummary: true, clearErrorMessage: true));
    try {
      final summary =
          await GenerateSummaryUseCase(
            repository: _transcriptRepository,
            summaryService: _summaryService,
          ).execute(
            transcript: transcript,
            transcriptText: state.mergedText,
            preferences: snapshot.preferences,
          );
      emit(
        state.copyWith(
          summary: summary,
          clearSummary: summary == null,
          generatingSummary: false,
        ),
      );
      if (summary != null) {
        _syncQueueService.scheduleSync();
      }
    } catch (error) {
      emit(
        state.copyWith(
          generatingSummary: false,
          errorMessage: error.toString(),
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
