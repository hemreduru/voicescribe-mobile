import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/features/recording/recording_screen.dart';
import 'package:voicescribe_mobile/features/summary/summary_screen.dart';
import 'package:voicescribe_mobile/l10n/app_localizations.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/shared/services/summary_service.dart';
import 'package:voicescribe_mobile/shared/services/transcript_repository.dart';
import 'package:voicescribe_mobile/shared/services/whisper_service.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';

void main() {
  testWidgets('recording screen shows localized title', (tester) async {
    final controller = _buildController();
    await controller.bootstrap();

    await tester.pumpWidget(
      _wrapWithApp(controller: controller, child: const RecordingScreen()),
    );

    await tester.pumpAndSettle();

    expect(find.text('Recording'), findsOneWidget);
  });

  testWidgets('summary screen renders generate button', (tester) async {
    final controller = _buildController();
    await controller.bootstrap();

    controller.transcriptController.transcripts = [
      Transcript(
        id: 'local-1',
        localId: 'local-1',
        title: 'Demo',
        durationSeconds: 30,
        status: TranscriptStatus.completed,
        recordedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    controller.transcriptController.allChunks = [
      TranscriptChunk(
        id: 'chunk-1',
        transcriptId: 'local-1',
        chunkIndex: 1,
        text: 'A sample transcript text.',
        audioPath: null,
        recordedAt: DateTime.now(),
        startTime: 0,
        endTime: 30,
        speakerLabel: null,
        confidence: null,
        transcriptionError: null,
      ),
    ];

    await tester.pumpWidget(
      _wrapWithApp(controller: controller, child: const SummaryScreen()),
    );

    await tester.pumpAndSettle();

    expect(find.text('Generate Summary'), findsOneWidget);
  });
}

Widget _wrapWithApp({
  required AppController controller,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [appControllerProvider.overrideWith((ref) => controller)],
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
  );
}

AppController _buildController() {
  return AppController(
    repository: _FakeRepository(),
    transcriptionService: _FakeTranscriptionService(),
    audioService: _FakeRecordingService(),
    summaryService: const LocalSummaryService(),
  );
}

class _FakeRepository implements TranscriptRepository {
  @override
  Future<PersistedTranscriptState> load() async =>
      PersistedTranscriptState.empty();

  @override
  Future<void> saveTranscript(Transcript transcript) async {}

  @override
  Future<void> deleteTranscript(String id) async {}

  @override
  Future<void> saveChunk(TranscriptChunk chunk) async {}

  @override
  Future<void> saveSpeaker(SpeakerProfile speaker) async {}

  @override
  Future<void> deleteSpeaker(String id) async {}

  @override
  Future<void> saveSummary(Summary summary) async {}

  @override
  Future<void> saveSetting(String key, String value) async {}
}

class _FakeRecordingService implements RecordingService {
  final _chunks = StreamController<RecordedAudioChunk>.broadcast();
  final _levels = StreamController<double>.broadcast();

  @override
  Stream<RecordedAudioChunk> get chunks => _chunks.stream;

  @override
  Stream<double> get levels => _levels.stream;

  @override
  Future<void> dispose() async {
    await _chunks.close();
    await _levels.close();
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

class _FakeTranscriptionService implements TranscriptionService {
  final _progress = StreamController<ModelDownloadProgress>.broadcast();

  @override
  Stream<ModelDownloadProgress> get downloadProgress => _progress.stream;

  @override
  Future<void> dispose() async {
    await _progress.close();
  }

  @override
  Future<WhisperBootstrapResult> ensureModel() async {
    return const WhisperBootstrapResult(
      path: '/tmp/model',
      downloaded: false,
      loaded: true,
    );
  }

  @override
  Future<String> transcribeChunk(String audioPath) async => '';
}
