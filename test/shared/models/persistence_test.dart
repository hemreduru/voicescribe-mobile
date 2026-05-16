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
          confidence: null,
          transcriptionError: null,
        ),
      ],
      summaries: [
        Summary(
          id: 'summary-1',
          transcriptId: 'local-1',
          providerKey: 'local',
          model: 'local-default',
          summaryText: 'Kisa ozet',
          tokenCount: 12,
          processingTimeMs: 10,
          createdAt: now,
        ),
      ],
      processingJobs: const [],
      summaryProvider: 'local',
      summaryLength: 'medium',
      themeMode: 'dark',
    );

    final decoded = PersistedTranscriptState.fromJson(state.toJson());

    expect(decoded.transcripts.single.title, 'Demo');
    expect(decoded.transcripts.single.status, TranscriptStatus.completed);
    expect(decoded.allChunks.single.text, 'Merhaba');
    expect(decoded.summaries.single.summaryText, 'Kisa ozet');
    expect(decoded.themeMode, 'dark');
  });

  test('legacy speaker analysis statuses are not restored as empty', () {
    expect(
      TranscriptStatus.fromKey('speaker_analysis_completed'),
      TranscriptStatus.completed,
    );
    expect(
      TranscriptStatus.fromKey('speaker_analysis_pending'),
      TranscriptStatus.transcriptionCompleted,
    );
    expect(
      TranscriptStatus.fromKey('speaker_analysis_running'),
      TranscriptStatus.transcriptionCompleted,
    );
  });

  test('PersistedTranscriptState tolerates missing arrays', () {
    final decoded = PersistedTranscriptState.fromJson(const {});

    expect(decoded.transcripts, isEmpty);
    expect(decoded.currentTranscript, isNull);
    expect(decoded.allChunks, isEmpty);
    expect(decoded.summaries, isEmpty);
    expect(decoded.themeMode, 'system');
  });

  test('PersistedTranscriptState falls back to system theme mode', () {
    final decoded = PersistedTranscriptState.fromJson(const {
      'themeMode': 'sepia',
    });

    expect(decoded.themeMode, 'system');
  });
}
