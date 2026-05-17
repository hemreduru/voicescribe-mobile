import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/data/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/auth_repository.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/l10n/app_localizations.dart';
import 'package:voicescribe_mobile/ui/core/router/app_shell.dart';
import 'package:voicescribe_mobile/ui/features/bootstrap/bloc/bootstrap_bloc.dart';
import 'package:voicescribe_mobile/ui/features/recording/bloc/recording_bloc.dart';
import 'package:voicescribe_mobile/ui/features/recording/views/recording_screen.dart';
import 'package:voicescribe_mobile/ui/features/transcript/bloc/transcript_list_bloc.dart';
import 'package:voicescribe_mobile/ui/features/transcript/views/transcript_screen.dart';

import '../helpers/fakes.dart';

void main() {
  testWidgets('bootstrap screen shows percent and byte totals', (tester) async {
    await tester.pumpWidget(
      _wrapWithApp(
        fakes: _Fakes(),
        blocs: const <BlocProvider<dynamic>>[],
        child: const BootstrapScreen(
          state: BootstrapState(
            downloadProgress: ModelDownloadProgress(
              bytesDownloaded: 150 * 1024 * 1024,
              totalBytes: 300 * 1024 * 1024,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Downloading model 50%'), findsOneWidget);
    expect(find.textContaining('150 MB / 300 MB'), findsOneWidget);
  });

  testWidgets('recording screen shows localized title', (tester) async {
    final fakes = _Fakes();
    await tester.pumpWidget(
      _wrapWithApp(
        fakes: fakes,
        blocs: [
          BlocProvider<RecordingBloc>(
            create: (_) => RecordingBloc(
              transcriptRepository: fakes.transcripts,
              recordingService: fakes.recording,
              transcriptionService: fakes.transcription,
              authRepository: fakes.auth,
              syncQueueService: fakes.sync,
            )..add(const RecordingSubscriptionRequested()),
          ),
        ],
        child: const RecordingScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Recording'), findsOneWidget);
    expect(find.text('Enter session title...'), findsOneWidget);
    expect(find.text('Session Status'), findsNothing);
    expect(find.text('Live Transcript'), findsNothing);
  });

  testWidgets('transcript detail renders transcript and summary tabs', (
    tester,
  ) async {
    final now = DateTime.now();
    final fakes = _Fakes(
      snapshot: TranscriptSnapshot(
        transcripts: [
          Transcript(
            id: 'local-1',
            localId: 'local-1',
            title: 'Demo',
            durationSeconds: 30,
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
            text: 'A sample transcript text.',
            audioPath: null,
            recordedAt: now,
            startTime: 0,
            endTime: 30,
            confidence: null,
            transcriptionError: null,
          ),
        ],
        summaries: const [],
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        fakes: fakes,
        blocs: [
          BlocProvider<TranscriptListBloc>(
            create: (_) => TranscriptListBloc(
              transcriptRepository: fakes.transcripts,
              syncQueueService: fakes.sync,
            )..add(const TranscriptListSubscriptionRequested()),
          ),
          BlocProvider<RecordingBloc>(
            create: (_) => RecordingBloc(
              transcriptRepository: fakes.transcripts,
              recordingService: fakes.recording,
              transcriptionService: fakes.transcription,
              authRepository: fakes.auth,
              syncQueueService: fakes.sync,
            )..add(const RecordingSubscriptionRequested()),
          ),
        ],
        child: const TranscriptScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Demo'));
    await tester.pumpAndSettle();

    expect(find.text('Transcript'), findsWidgets);
    expect(find.text('Summary'), findsOneWidget);
    await tester.tap(find.text('Summary'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Generate Summary'), findsOneWidget);
  });
}

Widget _wrapWithApp({
  required _Fakes fakes,
  required List<BlocProvider<dynamic>> blocs,
  required Widget child,
}) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<TranscriptRepository>.value(value: fakes.transcripts),
      RepositoryProvider<AuthRepository>.value(value: fakes.auth),
      RepositoryProvider<RecordingService>.value(value: fakes.recording),
      RepositoryProvider<TranscriptionService>.value(
        value: fakes.transcription,
      ),
      RepositoryProvider<SummaryService>.value(value: fakes.summary),
      RepositoryProvider<SyncQueueService>.value(value: fakes.sync),
    ],
    child: blocs.isEmpty
        ? MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('tr')],
            home: child,
          )
        : MultiBlocProvider(
            providers: blocs,
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('tr')],
              home: child,
            ),
          ),
  );
}

class _Fakes {
  _Fakes({TranscriptSnapshot? snapshot})
    : transcripts = FakeTranscriptRepository(initial: snapshot),
      auth = FakeAuthRepository(session: FakeAuthRepository.defaultSession),
      recording = FakeRecordingService(),
      transcription = FakeTranscriptionService(),
      summary = const LocalSummaryService(),
      sync = FakeSyncQueueService();

  final FakeTranscriptRepository transcripts;
  final FakeAuthRepository auth;
  final FakeRecordingService recording;
  final FakeTranscriptionService transcription;
  final LocalSummaryService summary;
  final FakeSyncQueueService sync;
}
