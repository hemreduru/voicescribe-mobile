import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/shared/utils/text_utils.dart';

class TranscriptController {
  List<Transcript> transcripts = [];
  Transcript? currentTranscript;
  List<TranscriptChunk> currentChunks = [];
  List<TranscriptChunk> allChunks = [];
  String? lastError;

  final Map<String, _TranscriptProcessingStats> _stats = {};
  final Map<String, List<TranscriptChunk>> _chunksByTranscript = {};
  final Map<String, String> _transcriptTextById = {};
  List<TranscriptChunk>? _indexedAllChunks;

  void hydrate(PersistedTranscriptState state) {
    transcripts = state.transcripts;
    currentTranscript = state.currentTranscript;
    currentChunks = state.currentChunks;
    allChunks = state.allChunks;
    _rebuildChunkIndex();
    _rebuildStats();
  }

  Transcript startSession(String? title, {String? userId}) {
    final now = DateTime.now();
    final id = 'local-${now.millisecondsSinceEpoch}';
    final transcript = Transcript(
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

    transcripts = [transcript, ...transcripts];
    currentTranscript = transcript;
    currentChunks = [];
    _stats[id] = _TranscriptProcessingStats();
    _chunksByTranscript[id] = const [];
    _transcriptTextById.remove(id);
    lastError = null;
    return transcript;
  }

  void removeTranscript(String id) {
    transcripts = transcripts.where((item) => item.id != id).toList();
    allChunks = allChunks.where((item) => item.transcriptId != id).toList();
    _stats.remove(id);
    _chunksByTranscript.remove(id);
    _transcriptTextById.remove(id);
    _indexedAllChunks = allChunks;
    if (currentTranscript?.id == id) {
      currentTranscript = null;
      currentChunks = [];
    }
  }

  Transcript? updateTranscriptTitle(String id, String title) {
    final normalized = title.trim();
    Transcript? updated;
    transcripts = transcripts.map((transcript) {
      if (transcript.id != id) {
        return transcript;
      }
      updated = transcript.copyWith(
        title: normalized.isEmpty ? null : normalized,
        clearTitle: normalized.isEmpty,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        clearSyncError: true,
      );
      return updated!;
    }).toList();

    if (currentTranscript?.id == id) {
      currentTranscript = updated;
    }
    return updated;
  }

  TranscriptChunk addRecordedChunk(RecordedAudioChunk audioChunk) {
    final transcript = currentTranscript;
    if (transcript == null) {
      throw StateError('No active transcript to attach chunk.');
    }

    final previousEnd = currentChunks.isEmpty
        ? 0.0
        : currentChunks.last.endTime;
    final now = DateTime.now();
    final chunk = TranscriptChunk(
      id: '${transcript.id}-chunk-${currentChunks.length + 1}',
      transcriptId: transcript.id,
      chunkIndex: currentChunks.length + 1,
      text: '',
      audioPath: audioChunk.path,
      recordedAt: now,
      startTime: previousEnd,
      endTime: previousEnd + audioChunk.durationSeconds,
      confidence: null,
      transcriptionError: null,
    );

    currentChunks = [...currentChunks, chunk];
    allChunks = [...allChunks, chunk];
    _setChunksFor(transcript.id, currentChunks);
    final stats = _stats.putIfAbsent(
      transcript.id,
      _TranscriptProcessingStats.new,
    );
    stats.total++;
    stats.pending++;
    _updateTranscript(
      transcript.id,
      status: TranscriptStatus.transcribing,
      durationSeconds: chunk.endTime.round(),
    );

    return chunk;
  }

  void markRecordingStopped({required int durationSeconds}) {
    final transcript = currentTranscript;
    if (transcript == null) {
      return;
    }
    final stats = _stats.putIfAbsent(
      transcript.id,
      _TranscriptProcessingStats.new,
    );
    final status = _aggregateStatus(stats, hasChunks: currentChunks.isNotEmpty);
    _updateTranscript(
      transcript.id,
      status: status,
      durationSeconds: durationSeconds,
    );
  }

  void updateCurrentDuration(int durationSeconds) {
    final transcript = currentTranscript;
    if (transcript == null) {
      return;
    }
    _updateTranscript(transcript.id, durationSeconds: durationSeconds);
  }

  void applyTranscriptionSuccess(TranscriptChunk chunk, String rawText) {
    final normalized = normalizeWhitespace(rawText);
    final previousChunk = chunksFor(
      chunk.transcriptId,
    ).where((item) => item.chunkIndex == chunk.chunkIndex - 1).firstOrNull;

    final deduped = previousChunk == null
        ? normalized
        : removeOverlap(previousChunk.text, normalized);

    _updateChunk(chunk.id, text: deduped, clearError: true);

    final stats = _stats.putIfAbsent(
      chunk.transcriptId,
      _TranscriptProcessingStats.new,
    );
    stats.pending = (stats.pending - 1).clamp(0, 1 << 30);
    if (deduped.isNotEmpty) {
      stats.success++;
    }
    _updateTranscript(
      chunk.transcriptId,
      status: _aggregateStatus(stats, hasChunks: true),
      updatedAt: DateTime.now(),
    );
  }

  void applyTranscriptionError(TranscriptChunk chunk, Object error) {
    _updateChunk(chunk.id, transcriptionError: error.toString());
    lastError = error.toString();

    final stats = _stats.putIfAbsent(
      chunk.transcriptId,
      _TranscriptProcessingStats.new,
    );
    stats.pending = (stats.pending - 1).clamp(0, 1 << 30);
    stats.failed++;

    _updateTranscript(
      chunk.transcriptId,
      status: _aggregateStatus(stats, hasChunks: true),
      updatedAt: DateTime.now(),
    );
  }

  List<TranscriptChunk> chunksFor(String transcriptId) {
    _ensureChunkIndexCurrent();
    return _chunksByTranscript[transcriptId] ?? const [];
  }

  String transcriptText(String transcriptId) {
    _ensureChunkIndexCurrent();
    return _transcriptTextById.putIfAbsent(
      transcriptId,
      () => mergeTranscriptChunks(chunksFor(transcriptId)),
    );
  }

  void replaceChunk(TranscriptChunk updatedChunk) {
    currentChunks = currentChunks
        .map((item) => item.id == updatedChunk.id ? updatedChunk : item)
        .toList();
    allChunks = allChunks
        .map((item) => item.id == updatedChunk.id ? updatedChunk : item)
        .toList();
    _refreshChunksFor(updatedChunk.transcriptId);
  }

  void replaceTranscript(Transcript updatedTranscript) {
    transcripts = transcripts
        .map(
          (item) => item.id == updatedTranscript.id ? updatedTranscript : item,
        )
        .toList();
    if (currentTranscript?.id == updatedTranscript.id) {
      currentTranscript = updatedTranscript;
    }
  }

  PersistedTranscriptState toPersistedState({
    required List<Summary> summaries,
    required List<ProcessingJob> processingJobs,
    required String summaryProvider,
    required String summaryLength,
    required String themeMode,
  }) {
    return PersistedTranscriptState(
      transcripts: transcripts,
      currentTranscript: currentTranscript,
      currentChunks: currentChunks,
      allChunks: allChunks,
      summaries: summaries,
      processingJobs: processingJobs,
      summaryProvider: summaryProvider,
      summaryLength: summaryLength,
      themeMode: themeMode,
    );
  }

  void _updateChunk(
    String chunkId, {
    String? text,
    String? transcriptionError,
    bool clearError = false,
  }) {
    String? affectedTranscriptId;
    currentChunks = currentChunks.map((chunk) {
      if (chunk.id != chunkId) {
        return chunk;
      }
      affectedTranscriptId = chunk.transcriptId;
      return chunk.copyWith(
        text: text,
        transcriptionError: transcriptionError,
        clearTranscriptionError: clearError,
        syncStatus: SyncStatus.pending,
        clearSyncError: true,
      );
    }).toList();

    allChunks = allChunks.map((chunk) {
      if (chunk.id != chunkId) {
        return chunk;
      }
      affectedTranscriptId = chunk.transcriptId;
      return chunk.copyWith(
        text: text,
        transcriptionError: transcriptionError,
        clearTranscriptionError: clearError,
        syncStatus: SyncStatus.pending,
        clearSyncError: true,
      );
    }).toList();

    if (affectedTranscriptId != null) {
      _refreshChunksFor(affectedTranscriptId!);
    }
  }

  void _updateTranscript(
    String id, {
    TranscriptStatus? status,
    int? durationSeconds,
    DateTime? updatedAt,
  }) {
    final nextUpdatedAt = updatedAt ?? DateTime.now();
    transcripts = transcripts
        .map(
          (transcript) => transcript.id == id
              ? transcript.copyWith(
                  status: status,
                  durationSeconds: durationSeconds,
                  updatedAt: nextUpdatedAt,
                  syncStatus: SyncStatus.pending,
                  clearSyncError: true,
                )
              : transcript,
        )
        .toList();

    if (currentTranscript?.id == id) {
      currentTranscript = currentTranscript!.copyWith(
        status: status,
        durationSeconds: durationSeconds,
        updatedAt: nextUpdatedAt,
        syncStatus: SyncStatus.pending,
        clearSyncError: true,
      );
    }
  }

  TranscriptStatus _aggregateStatus(
    _TranscriptProcessingStats stats, {
    required bool hasChunks,
  }) {
    if (!hasChunks || stats.total == 0) {
      return TranscriptStatus.empty;
    }
    if (stats.pending > 0) {
      return TranscriptStatus.transcribing;
    }
    if (stats.failed > 0) {
      return TranscriptStatus.transcriptionError;
    }
    if (stats.success > 0) {
      return TranscriptStatus.transcriptionCompleted;
    }
    return TranscriptStatus.empty;
  }

  void _rebuildStats() {
    _stats.clear();
    for (final chunk in allChunks) {
      final stats = _stats.putIfAbsent(
        chunk.transcriptId,
        _TranscriptProcessingStats.new,
      );
      stats.total++;
      if ((chunk.transcriptionError ?? '').isNotEmpty) {
        stats.failed++;
      } else if (chunk.text.trim().isNotEmpty) {
        stats.success++;
      }
    }
  }

  void _rebuildChunkIndex() {
    _chunksByTranscript.clear();
    _transcriptTextById.clear();
    for (final chunk in allChunks) {
      _chunksByTranscript
          .putIfAbsent(chunk.transcriptId, () => <TranscriptChunk>[])
          .add(chunk);
    }
    for (final entry in _chunksByTranscript.entries) {
      entry.value.sort((a, b) => a.chunkIndex.compareTo(b.chunkIndex));
      _chunksByTranscript[entry.key] = List.unmodifiable(entry.value);
    }
    _indexedAllChunks = allChunks;
    if (currentTranscript != null) {
      currentChunks = _chunksByTranscript[currentTranscript!.id] ?? const [];
    }
  }

  void _refreshChunksFor(String transcriptId) {
    final chunks =
        allChunks.where((chunk) => chunk.transcriptId == transcriptId).toList()
          ..sort((a, b) => a.chunkIndex.compareTo(b.chunkIndex));
    _setChunksFor(transcriptId, chunks);
    if (currentTranscript?.id == transcriptId) {
      currentChunks = _chunksByTranscript[transcriptId] ?? const [];
    }
  }

  void _setChunksFor(String transcriptId, List<TranscriptChunk> chunks) {
    _chunksByTranscript[transcriptId] = List.unmodifiable(chunks);
    _transcriptTextById.remove(transcriptId);
    _indexedAllChunks = allChunks;
  }

  void _ensureChunkIndexCurrent() {
    if (!identical(_indexedAllChunks, allChunks)) {
      _rebuildChunkIndex();
    }
  }
}

class _TranscriptProcessingStats {
  int total = 0;
  int pending = 0;
  int success = 0;
  int failed = 0;
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
