import 'package:voicescribe_mobile/domain/models/domain.dart';

abstract class TranscriptRepository {
  Stream<TranscriptSnapshot> watchSnapshot();

  Future<TranscriptSnapshot> loadSnapshot();

  Future<void> refresh();

  Future<void> saveTranscript(Transcript transcript);

  Future<void> deleteTranscript(String id);

  Future<void> saveChunk(TranscriptChunk chunk);

  Future<void> saveSummary(Summary summary);

  Future<void> deleteSummary(String id);

  Future<void> savePreferences(AppPreferences preferences);
}
