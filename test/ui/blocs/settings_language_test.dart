import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/ui/features/settings/bloc/settings_bloc.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeTranscriptRepository transcripts;
  late FakeAuthRepository auth;
  late FakeSyncQueueService sync;
  late FakeTranscriptionService transcription;
  late SettingsBloc bloc;

  setUp(() {
    transcripts = FakeTranscriptRepository();
    auth = FakeAuthRepository(session: FakeAuthRepository.defaultSession);
    sync = FakeSyncQueueService();
    transcription = FakeTranscriptionService();
    bloc = SettingsBloc(
      transcriptRepository: transcripts,
      authRepository: auth,
      syncQueueService: sync,
      transcriptionService: transcription,
    );
  });

  tearDown(() async {
    await bloc.close();
    await transcripts.dispose();
    await auth.dispose();
    await sync.dispose();
    await transcription.dispose();
  });

  test(
    'changing transcription language persists the preference and applies it to '
    'the transcription service',
    () async {
      bloc.add(const SettingsTranscriptionLanguageChanged('tr'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.preferences.transcriptionLanguage, 'tr');
      expect(transcription.language, 'tr');
      expect(transcripts.savedPreferences['latest']?.transcriptionLanguage, 'tr');
    },
  );

  test('unknown language values fall back to auto', () async {
    bloc.add(const SettingsTranscriptionLanguageChanged('fr'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.preferences.transcriptionLanguage, 'auto');
    expect(transcription.language, 'auto');
  });

  test('pendingSyncCount counts only un-synced transcripts', () async {
    final now = DateTime(2026, 6, 5);
    final seeded = FakeTranscriptRepository(
      initial: TranscriptSnapshot(
        transcripts: [
          Transcript(
            id: 'a',
            localId: 'a',
            title: 'Pending',
            durationSeconds: 1,
            status: TranscriptStatus.completed,
            recordedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.pending,
          ),
          Transcript(
            id: 'b',
            localId: 'b',
            title: 'Failed',
            durationSeconds: 1,
            status: TranscriptStatus.completed,
            recordedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.failed,
          ),
          Transcript(
            id: 'c',
            localId: 'c',
            title: 'Synced',
            durationSeconds: 1,
            status: TranscriptStatus.completed,
            recordedAt: now,
            createdAt: now,
            updatedAt: now,
            remoteId: 'r',
            syncStatus: SyncStatus.synced,
          ),
        ],
        chunks: const [],
        summaries: const [],
      ),
    );
    final scopedBloc = SettingsBloc(
      transcriptRepository: seeded,
      authRepository: auth,
      syncQueueService: sync,
      transcriptionService: transcription,
    );
    addTearDown(() async {
      await scopedBloc.close();
      await seeded.dispose();
    });

    scopedBloc.add(const SettingsSubscriptionRequested());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(scopedBloc.state.pendingSyncCount, 2);
  });
}
