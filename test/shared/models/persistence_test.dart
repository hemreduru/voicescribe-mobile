import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';

void main() {
  test('PersistedTranscriptState round-trips transcript JSON', () {
    final now = DateTime.parse('2026-04-26T12:00:00.000Z');
    final state = PersistedTranscriptState(
      transcripts: [
        Transcript(
          id: 'local-1',
          localId: 'local-1',
          title: 'Demo',
          durationSeconds: 12,
          status: TranscriptStatus.completed,
          recordedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      currentTranscript: null,
      currentChunks: const [],
      allChunks: [
        TranscriptChunk(
          id: 'chunk-1',
          transcriptId: 'local-1',
          chunkIndex: 1,
          text: 'Merhaba',
          audioPath: '/tmp/chunk.wav',
          recordedAt: now,
          startTime: 0,
          endTime: 12,
          speakerLabel: null,
          confidence: null,
        ),
      ],
    );

    final decoded = PersistedTranscriptState.fromJson(state.toJson());

    expect(decoded.transcripts.single.title, 'Demo');
    expect(decoded.transcripts.single.status, TranscriptStatus.completed);
    expect(decoded.allChunks.single.text, 'Merhaba');
  });

  test('PersistedTranscriptState tolerates missing arrays', () {
    final decoded = PersistedTranscriptState.fromJson(const {});

    expect(decoded.transcripts, isEmpty);
    expect(decoded.currentTranscript, isNull);
    expect(decoded.allChunks, isEmpty);
  });
}
