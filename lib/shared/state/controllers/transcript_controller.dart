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

  void hydrate(PersistedTranscriptState state) {
    transcripts = state.transcripts;
    currentTranscript = state.currentTranscript;
    currentChunks = state.currentChunks;
    allChunks = state.allChunks;
    _rebuildStats();
  }

  Transcript startSession(String? title) {
    final now = DateTime.now();
    final id = 'local-${now.millisecondsSinceEpoch}';
    final transcript = Transcript(
      id: id,
      localId: id,
      title: title?.trim().isNotEmpty ?? false ? title!.trim() : now.toString(),
      durationSeconds: 0,
      status: TranscriptStatus.recording,
      recordedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    transcripts = [transcript, ...transcripts];
    currentTranscript = transcript;
    currentChunks = [];
    _stats[id] = _TranscriptProcessingStats();
    lastError = null;
    return transcript;
  }

  void removeTranscript(String id) {
    transcripts = transcripts.where((item) => item.id != id).toList();
    allChunks = allChunks.where((item) => item.transcriptId != id).toList();
    _stats.remove(id);
    if (currentTranscript?.id == id) {
      currentTranscript = null;
      currentChunks = [];
    }
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
      speakerLabel: null,
      confidence: null,
      transcriptionError: null,
    );

    currentChunks = [...currentChunks, chunk];
    allChunks = [...allChunks, chunk];
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
    final chunks =
        allChunks.where((chunk) => chunk.transcriptId == transcriptId).toList()
          ..sort((a, b) => a.chunkIndex.compareTo(b.chunkIndex));
    return chunks;
  }

  String transcriptText(String transcriptId) {
    return mergeTranscriptChunks(chunksFor(transcriptId));
  }

  PersistedTranscriptState toPersistedState({
    required List<SpeakerProfile> speakers,
    required List<Summary> summaries,
    required String summaryProvider,
    required String summaryLength,
    required bool speakerRecognitionEnabled,
  }) {
    return PersistedTranscriptState(
      transcripts: transcripts,
      currentTranscript: currentTranscript,
      currentChunks: currentChunks,
      allChunks: allChunks,
      speakers: speakers,
      summaries: summaries,
      summaryProvider: summaryProvider,
      summaryLength: summaryLength,
      speakerRecognitionEnabled: speakerRecognitionEnabled,
    );
  }

  void _updateChunk(
    String chunkId, {
    String? text,
    String? transcriptionError,
    bool clearError = false,
  }) {
    currentChunks = currentChunks
        .map(
          (chunk) => chunk.id == chunkId
              ? chunk.copyWith(
                  text: text,
                  transcriptionError: transcriptionError,
                  clearTranscriptionError: clearError,
                )
              : chunk,
        )
        .toList();

    allChunks = allChunks
        .map(
          (chunk) => chunk.id == chunkId
              ? chunk.copyWith(
                  text: text,
                  transcriptionError: transcriptionError,
                  clearTranscriptionError: clearError,
                )
              : chunk,
        )
        .toList();
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
                )
              : transcript,
        )
        .toList();

    if (currentTranscript?.id == id) {
      currentTranscript = currentTranscript!.copyWith(
        status: status,
        durationSeconds: durationSeconds,
        updatedAt: nextUpdatedAt,
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
      return TranscriptStatus.completed;
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
