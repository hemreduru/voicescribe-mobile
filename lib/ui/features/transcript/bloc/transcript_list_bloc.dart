import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/domain/utils/text_utils.dart';

enum TranscriptSort { newest, oldest, longest }

enum TranscriptFilter { all, ready, processing, issue }

enum TranscriptDisplayStatus { active, processing, ready, issue }

sealed class TranscriptListEvent {
  const TranscriptListEvent();
}

final class TranscriptListSubscriptionRequested extends TranscriptListEvent {
  const TranscriptListSubscriptionRequested();
}

final class TranscriptListQueryChanged extends TranscriptListEvent {
  const TranscriptListQueryChanged(this.query);

  final String query;
}

final class TranscriptListSortChanged extends TranscriptListEvent {
  const TranscriptListSortChanged(this.sort);

  final TranscriptSort sort;
}

final class TranscriptListFilterChanged extends TranscriptListEvent {
  const TranscriptListFilterChanged(this.filter);

  final TranscriptFilter filter;
}

final class TranscriptListSelectionToggled extends TranscriptListEvent {
  const TranscriptListSelectionToggled(this.id);

  final String id;
}

final class TranscriptListSelectionCleared extends TranscriptListEvent {
  const TranscriptListSelectionCleared();
}

final class TranscriptListSelectedDeleted extends TranscriptListEvent {
  const TranscriptListSelectedDeleted();
}

final class TranscriptListRefreshRequested extends TranscriptListEvent {
  const TranscriptListRefreshRequested({this.completer});

  final Completer<void>? completer;
}

final class _TranscriptListSnapshotChanged extends TranscriptListEvent {
  const _TranscriptListSnapshotChanged(this.snapshot);

  final TranscriptSnapshot snapshot;
}

class TranscriptListItem {
  const TranscriptListItem({
    required this.transcript,
    required this.mergedText,
    this.completedChunkCount = 0,
    this.totalChunkCount = 0,
  });

  final Transcript transcript;
  final String mergedText;
  final int completedChunkCount;
  final int totalChunkCount;
}

class TranscriptListState {
  const TranscriptListState({
    this.snapshot,
    this.items = const [],
    this.query = '',
    this.sort = TranscriptSort.newest,
    this.filter = TranscriptFilter.all,
    this.selectedIds = const {},
  });

  final TranscriptSnapshot? snapshot;
  final List<TranscriptListItem> items;
  final String query;
  final TranscriptSort sort;
  final TranscriptFilter filter;
  final Set<String> selectedIds;

  TranscriptListState copyWith({
    TranscriptSnapshot? snapshot,
    List<TranscriptListItem>? items,
    String? query,
    TranscriptSort? sort,
    TranscriptFilter? filter,
    Set<String>? selectedIds,
  }) {
    return TranscriptListState(
      snapshot: snapshot ?? this.snapshot,
      items: items ?? this.items,
      query: query ?? this.query,
      sort: sort ?? this.sort,
      filter: filter ?? this.filter,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class TranscriptListBloc
    extends Bloc<TranscriptListEvent, TranscriptListState> {
  TranscriptListBloc({
    required TranscriptRepository transcriptRepository,
    required SyncQueueService syncQueueService,
  })
    : _transcriptRepository = transcriptRepository,
      _syncQueueService = syncQueueService,
      super(const TranscriptListState()) {
    on<TranscriptListSubscriptionRequested>(_onSubscriptionRequested);
    on<_TranscriptListSnapshotChanged>(_onSnapshotChanged);
    on<TranscriptListQueryChanged>(_onQueryChanged);
    on<TranscriptListSortChanged>(_onSortChanged);
    on<TranscriptListFilterChanged>(_onFilterChanged);
    on<TranscriptListSelectionToggled>(_onSelectionToggled);
    on<TranscriptListSelectionCleared>(_onSelectionCleared);
    on<TranscriptListSelectedDeleted>(_onSelectedDeleted);
    on<TranscriptListRefreshRequested>(_onRefreshRequested);
  }

  final TranscriptRepository _transcriptRepository;
  final SyncQueueService _syncQueueService;
  StreamSubscription<TranscriptSnapshot>? _snapshotSubscription;

  Future<void> _onSubscriptionRequested(
    TranscriptListSubscriptionRequested event,
    Emitter<TranscriptListState> emit,
  ) async {
    await _snapshotSubscription?.cancel();
    final snapshot = await _transcriptRepository.loadSnapshot();
    emit(_stateFor(snapshot: snapshot));
    _snapshotSubscription = _transcriptRepository.watchSnapshot().listen(
      (snapshot) => add(_TranscriptListSnapshotChanged(snapshot)),
    );
  }

  void _onSnapshotChanged(
    _TranscriptListSnapshotChanged event,
    Emitter<TranscriptListState> emit,
  ) {
    emit(_stateFor(snapshot: event.snapshot));
  }

  void _onQueryChanged(
    TranscriptListQueryChanged event,
    Emitter<TranscriptListState> emit,
  ) {
    emit(_stateFor(query: event.query));
  }

  void _onSortChanged(
    TranscriptListSortChanged event,
    Emitter<TranscriptListState> emit,
  ) {
    emit(_stateFor(sort: event.sort));
  }

  void _onFilterChanged(
    TranscriptListFilterChanged event,
    Emitter<TranscriptListState> emit,
  ) {
    emit(_stateFor(filter: event.filter));
  }

  void _onSelectionToggled(
    TranscriptListSelectionToggled event,
    Emitter<TranscriptListState> emit,
  ) {
    final next = {...state.selectedIds};
    if (!next.add(event.id)) {
      next.remove(event.id);
    }
    emit(_stateFor(selectedIds: next));
  }

  void _onSelectionCleared(
    TranscriptListSelectionCleared event,
    Emitter<TranscriptListState> emit,
  ) {
    emit(_stateFor(selectedIds: const <String>{}));
  }

  Future<void> _onSelectedDeleted(
    TranscriptListSelectedDeleted event,
    Emitter<TranscriptListState> emit,
  ) async {
    final selected = state.selectedIds.toList(growable: false);
    for (final id in selected) {
      await _transcriptRepository.deleteTranscript(id);
    }
    emit(_stateFor(selectedIds: const <String>{}));
    _syncQueueService.scheduleSync();
  }

  Future<void> _onRefreshRequested(
    TranscriptListRefreshRequested event,
    Emitter<TranscriptListState> emit,
  ) async {
    try {
      await _syncQueueService.runManualSync(trigger: SyncTrigger.refresh);
      event.completer?.complete();
    } catch (error, stackTrace) {
      event.completer?.completeError(error, stackTrace);
    }
  }

  TranscriptListState _stateFor({
    TranscriptSnapshot? snapshot,
    String? query,
    TranscriptSort? sort,
    TranscriptFilter? filter,
    Set<String>? selectedIds,
  }) {
    final nextSnapshot =
        snapshot ?? state.snapshot ?? TranscriptSnapshot.empty();
    final nextQuery = query ?? state.query;
    final nextSort = sort ?? state.sort;
    final nextFilter = filter ?? state.filter;
    final items = _buildItems(
      snapshot: nextSnapshot,
      query: nextQuery,
      sort: nextSort,
      filter: nextFilter,
    );
    final validIds = {for (final item in items) item.transcript.id};
    final nextSelected = (selectedIds ?? state.selectedIds)
        .where(validIds.contains)
        .toSet();
    return state.copyWith(
      snapshot: nextSnapshot,
      items: items,
      query: nextQuery,
      sort: nextSort,
      filter: nextFilter,
      selectedIds: nextSelected,
    );
  }

  List<TranscriptListItem> _buildItems({
    required TranscriptSnapshot snapshot,
    required String query,
    required TranscriptSort sort,
    required TranscriptFilter filter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final items = <TranscriptListItem>[];
    for (final transcript in snapshot.transcripts) {
      if (!_matchesFilter(transcript.status, filter)) {
        continue;
      }
      final chunks = snapshot.chunksFor(transcript.id);
      final mergedText = mergeTranscriptChunks(chunks);
      final totalChunkCount = chunks.length;
      final completedChunkCount = chunks.where((c) => c.text.isNotEmpty).length;
      final title = (transcript.title ?? '').toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty ||
          title.contains(normalizedQuery) ||
          mergedText.toLowerCase().contains(normalizedQuery);
      if (!matchesQuery) {
        continue;
      }
      items.add(
        TranscriptListItem(
          transcript: transcript,
          mergedText: mergedText,
          completedChunkCount: completedChunkCount,
          totalChunkCount: totalChunkCount,
        ),
      );
    }

    items.sort((a, b) {
      final aTranscript = a.transcript;
      final bTranscript = b.transcript;
      final aSortTime = _sortTimeFor(aTranscript);
      final bSortTime = _sortTimeFor(bTranscript);
      return switch (sort) {
        TranscriptSort.newest => bSortTime.compareTo(aSortTime),
        TranscriptSort.oldest => aSortTime.compareTo(bSortTime),
        TranscriptSort.longest => bTranscript.durationSeconds.compareTo(
          aTranscript.durationSeconds,
        ),
      };
    });
    return List.unmodifiable(items);
  }

  DateTime _sortTimeFor(Transcript transcript) {
    return transcript.updatedAt;
  }

  bool _matchesFilter(TranscriptStatus status, TranscriptFilter filter) {
    final display = displayStatusFor(status);
    return switch (filter) {
      TranscriptFilter.all => true,
      TranscriptFilter.ready => display == TranscriptDisplayStatus.ready,
      TranscriptFilter.processing =>
        display == TranscriptDisplayStatus.processing ||
            display == TranscriptDisplayStatus.active,
      TranscriptFilter.issue => display == TranscriptDisplayStatus.issue,
    };
  }

  @override
  Future<void> close() async {
    await _snapshotSubscription?.cancel();
    return super.close();
  }
}

TranscriptDisplayStatus displayStatusFor(TranscriptStatus status) {
  return switch (status) {
    TranscriptStatus.recording => TranscriptDisplayStatus.active,
    TranscriptStatus.transcriptionError => TranscriptDisplayStatus.issue,
    TranscriptStatus.completed => TranscriptDisplayStatus.ready,
    TranscriptStatus.transcribing => TranscriptDisplayStatus.processing,
    TranscriptStatus.transcriptionCompleted => TranscriptDisplayStatus.ready,
    TranscriptStatus.empty => TranscriptDisplayStatus.processing,
  };
}
