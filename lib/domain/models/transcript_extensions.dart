import 'package:voicescribe_mobile/domain/models/domain.dart';

extension TranscriptMutations on Transcript {
  /// Marks the transcript as dirty for sync: bumps `updatedAt`, resets
  /// `syncError`, sets `syncStatus` to pending. Optionally updates `status`
  /// and `durationSeconds` in the same call.
  Transcript markPendingSync({
    TranscriptStatus? status,
    int? durationSeconds,
    String? title,
    bool overrideTitle = false,
  }) {
    return copyWith(
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      title: overrideTitle ? title : this.title,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      syncError: null,
    );
  }
}

extension TranscriptChunkMutations on TranscriptChunk {
  TranscriptChunk markPendingSync() {
    return copyWith(
      syncStatus: SyncStatus.pending,
      syncError: null,
    );
  }
}
