import 'dart:math' as math;

import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/models/transcript_extensions.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';

/// On cold start, moves any transcript stuck in `recording` or `transcribing`
/// status to a terminal status. Chunks that are still pending will be
/// re-queued by the recording subscription once it wires up.
class RepairStaleRecordingsUseCase {
  const RepairStaleRecordingsUseCase(this._repository);

  final TranscriptRepository _repository;

  Future<TranscriptSnapshot> execute(TranscriptSnapshot snapshot) async {
    final chunksByTranscript = <String, List<TranscriptChunk>>{};
    for (final chunk in snapshot.chunks) {
      chunksByTranscript.putIfAbsent(chunk.transcriptId, () => []).add(chunk);
    }

    var changed = false;
    final repairedTranscripts = <Transcript>[];
    for (final transcript in snapshot.transcripts) {
      if (transcript.status != TranscriptStatus.recording &&
          transcript.status != TranscriptStatus.transcribing) {
        repairedTranscripts.add(transcript);
        continue;
      }

      final chunks =
          chunksByTranscript[transcript.id] ?? const <TranscriptChunk>[];
      final repaired = transcript.markPendingSync(
        status: _coldStartStatus(chunks),
        durationSeconds: math.max(
          transcript.durationSeconds,
          _maxChunkEnd(chunks).round(),
        ),
      );
      repairedTranscripts.add(repaired);
      changed = true;
      await _repository.saveTranscript(repaired);
    }

    if (!changed) {
      return snapshot;
    }

    return snapshot.copyWith(transcripts: repairedTranscripts);
  }

  /// Cold-start aggregation differs from the live one: any chunk that already
  /// produced text is enough to mark the transcript completed, since pending
  /// chunks will be retried by the recording subscription on next launch.
  TranscriptStatus _coldStartStatus(List<TranscriptChunk> chunks) {
    if (chunks.isEmpty) {
      return TranscriptStatus.empty;
    }
    if (chunks.any((chunk) => (chunk.transcriptionError ?? '').isNotEmpty)) {
      return TranscriptStatus.transcriptionError;
    }
    if (chunks.any((chunk) => chunk.text.trim().isNotEmpty)) {
      return TranscriptStatus.completed;
    }
    if (chunks.every((chunk) => chunk.isTranscribed)) {
      return TranscriptStatus.completed;
    }
    return TranscriptStatus.transcriptionError;
  }

  double _maxChunkEnd(List<TranscriptChunk> chunks) {
    var maxEnd = 0.0;
    for (final chunk in chunks) {
      if (chunk.endTime > maxEnd) {
        maxEnd = chunk.endTime;
      }
    }
    return maxEnd;
  }
}
