import 'dart:math' as math;

import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';

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
      if (transcript.status != TranscriptStatus.recording) {
        repairedTranscripts.add(transcript);
        continue;
      }

      final chunks =
          chunksByTranscript[transcript.id] ?? const <TranscriptChunk>[];
      final repaired = transcript.copyWith(
        status: _statusFor(chunks),
        durationSeconds: math.max(
          transcript.durationSeconds,
          _maxChunkEnd(chunks).round(),
        ),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        syncError: null,
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

  TranscriptStatus _statusFor(List<TranscriptChunk> chunks) {
    if (chunks.isEmpty) {
      return TranscriptStatus.empty;
    }
    if (chunks.any((chunk) => (chunk.transcriptionError ?? '').isNotEmpty)) {
      return TranscriptStatus.transcriptionError;
    }
    if (chunks.any((chunk) => chunk.text.trim().isNotEmpty)) {
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
