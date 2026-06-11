import 'package:voicescribe_mobile/domain/models/domain.dart';

abstract class TranscriptRepository {
  Stream<TranscriptSnapshot> watchSnapshot();

  Future<TranscriptSnapshot> loadSnapshot();

  Future<void> refresh();

  /// Re-reads the local cache and emits a fresh snapshot on [watchSnapshot],
  /// without any network round-trip. Use after an external writer (e.g. the
  /// sync queue) changed the database directly.
  Future<void> reloadFromCache();

  Future<void> saveTranscript(Transcript transcript);

  Future<void> deleteTranscript(String id);

  Future<void> saveChunk(TranscriptChunk chunk);

  Future<void> saveSummary(Summary summary);

  Future<void> deleteSummary(String id);

  Future<void> savePreferences(AppPreferences preferences);

  /// Fetches the full transcript list from the server and writes it into the
  /// local SQLite cache. On network/server failure this should **not** throw
  /// so the caller can fall back to the existing cache.
  Future<bool> fetchFromServer({required String token});

  /// Clears all cached transcripts, chunks and summaries. Called on logout
  /// so the next user doesn't see the previous user's data.
  Future<void> clearCache();
}
