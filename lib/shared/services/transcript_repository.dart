import 'package:voicescribe_mobile/shared/models/domain.dart';

abstract class TranscriptRepository {
  Future<PersistedTranscriptState> load();
  Future<void> saveTranscript(Transcript transcript);
  Future<void> deleteTranscript(String id);
  Future<void> saveChunk(TranscriptChunk chunk);
  Future<void> saveSpeaker(SpeakerProfile speaker);
  Future<void> deleteSpeaker(String id);
  Future<void> saveSummary(Summary summary);
  Future<void> saveSetting(String key, String value);
}
