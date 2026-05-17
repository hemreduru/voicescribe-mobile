import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/data/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/use_cases/repair_stale_recordings.dart';
import 'package:voicescribe_mobile/ui/features/recording/bloc/recording_bloc.dart';
import 'package:voicescribe_mobile/ui/features/transcript/bloc/transcript_detail_bloc.dart';

import '../../helpers/fakes.dart';

void main() {
  test(
    'stale recording repair moves recordings out of recording status',
    () async {
      final now = DateTime.utc(2026, 5, 16, 12);
      final repository = FakeTranscriptRepository(
        initial: TranscriptSnapshot(
          transcripts: [
            Transcript(
              id: 'stale',
              localId: 'stale',
              title: 'Stale',
              durationSeconds: 2,
              status: TranscriptStatus.recording,
              recordedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          chunks: [
            TranscriptChunk(
              id: 'chunk-1',
              transcriptId: 'stale',
              chunkIndex: 1,
              text: 'Merhaba',
              audioPath: '/tmp/chunk.wav',
              recordedAt: now,
              startTime: 0,
              endTime: 15,
              confidence: null,
              transcriptionError: null,
            ),
          ],
          summaries: const [],
        ),
      );

      final repaired = await RepairStaleRecordingsUseCase(
        repository,
      ).execute(repository.snapshot);

      expect(repaired.transcripts.single.status, TranscriptStatus.completed);
      expect(repaired.transcripts.single.durationSeconds, 15);
    },
  );

  group('recording bloc', () {
    late FakeRecordingService audio;

    blocTest<RecordingBloc, RecordingState>(
      'transcribes emitted chunks',
      setUp: () {
        audio = FakeRecordingService();
      },
      build: () => RecordingBloc(
        transcriptRepository: FakeTranscriptRepository(),
        recordingService: audio,
        transcriptionService: FakeTranscriptionService(
          responses: const {'/tmp/chunk-1.wav': 'Merhaba dunya'},
        ),
        authRepository: FakeAuthRepository(
          session: FakeAuthRepository.defaultSession,
        ),
        syncQueueService: FakeSyncQueueService(),
      ),
      act: (bloc) async {
        bloc.add(const RecordingSubscriptionRequested());
        bloc.add(const RecordingStarted('Demo'));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.isRecording, isTrue);
        audio.emitChunk(
          const RecordedAudioChunk(
            path: '/tmp/chunk-1.wav',
            durationSeconds: 2,
            index: 1,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
      verify: (bloc) {
        expect(bloc.state.currentChunks, hasLength(1));
        expect(bloc.state.currentChunks.single.text, 'Merhaba dunya');
        expect(
          bloc.state.currentTranscript?.status,
          TranscriptStatus.completed,
        );
      },
    );

    blocTest<RecordingBloc, RecordingState>(
      'completed status is preserved when dedupe leaves a chunk text empty',
      setUp: () {
        audio = FakeRecordingService();
      },
      build: () => RecordingBloc(
        transcriptRepository: FakeTranscriptRepository(),
        recordingService: audio,
        transcriptionService: FakeTranscriptionService(
          responses: const {
            '/tmp/chunk-1.wav': 'Ayni ifade',
            '/tmp/chunk-2.wav': 'Ayni ifade',
          },
        ),
        authRepository: FakeAuthRepository(
          session: FakeAuthRepository.defaultSession,
        ),
        syncQueueService: FakeSyncQueueService(),
      ),
      act: (bloc) async {
        bloc.add(const RecordingSubscriptionRequested());
        bloc.add(const RecordingStarted('Demo'));
        await Future<void>.delayed(Duration.zero);
        audio.emitChunk(
          const RecordedAudioChunk(
            path: '/tmp/chunk-1.wav',
            durationSeconds: 2,
            index: 1,
          ),
        );
        audio.emitChunk(
          const RecordedAudioChunk(
            path: '/tmp/chunk-2.wav',
            durationSeconds: 2,
            index: 2,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));
      },
      verify: (bloc) {
        expect(bloc.state.currentChunks, hasLength(2));
        expect(bloc.state.currentChunks[1].text, isEmpty);
        expect(
          bloc.state.currentTranscript?.status,
          TranscriptStatus.completed,
        );
      },
    );
  });

  blocTest<TranscriptDetailBloc, TranscriptDetailState>(
    'detail bloc generates summary for selected transcript',
    build: () {
      final now = DateTime.utc(2026, 5, 16, 12);
      return TranscriptDetailBloc(
        transcriptId: 'local-1',
        transcriptRepository: FakeTranscriptRepository(
          initial: TranscriptSnapshot(
            transcripts: [
              Transcript(
                id: 'local-1',
                localId: 'local-1',
                title: 'Demo',
                durationSeconds: 3,
                status: TranscriptStatus.completed,
                recordedAt: now,
                createdAt: now,
                updatedAt: now,
              ),
            ],
            chunks: [
              TranscriptChunk(
                id: 'chunk-1',
                transcriptId: 'local-1',
                chunkIndex: 1,
                text: 'First sentence. Second sentence.',
                audioPath: null,
                recordedAt: now,
                startTime: 0,
                endTime: 3,
                confidence: null,
                transcriptionError: null,
              ),
            ],
            summaries: const [],
          ),
        ),
        summaryService: const LocalSummaryService(),
        syncQueueService: FakeSyncQueueService(),
      );
    },
    act: (bloc) async {
      bloc.add(const TranscriptDetailSubscriptionRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TranscriptDetailSummaryRequested());
      await Future<void>.delayed(Duration.zero);
    },
    verify: (bloc) {
      expect(bloc.state.summary, isNotNull);
      expect(bloc.state.summary!.transcriptId, 'local-1');
    },
  );
}
