import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/shared/services/auth/auth_service.dart';
import 'package:voicescribe_mobile/shared/services/summary_service.dart';
import 'package:voicescribe_mobile/shared/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/shared/services/transcript_repository.dart';
import 'package:voicescribe_mobile/shared/services/whisper_service.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';

void main() {
  test('theme mode hydrates from persistence and saves updates', () async {
    final repository = _FakeRepository();
    repository.state = const PersistedTranscriptState(
      transcripts: [],
      currentTranscript: null,
      currentChunks: [],
      allChunks: [],
      summaries: [],
      processingJobs: [],
      summaryProvider: 'local',
      summaryLength: 'medium',
      themeMode: 'dark',
    );

    final controller = AppController(
      repository: repository,
      transcriptionService: _FakeTranscriptionService(responses: const {}),
      audioService: _FakeRecordingService(),
      summaryService: const LocalSummaryService(),
      authService: _FakeAuthService(),
    );

    await controller.bootstrap();

    expect(controller.themeMode, ThemeMode.dark);

    controller.setThemeMode(ThemeMode.light);
    await Future<void>.delayed(Duration.zero);

    expect(controller.themeMode, ThemeMode.light);
    expect(repository.savedSettings['themeMode'], 'light');

    controller.dispose();
  });

  test(
    'recording flow persists transcript and keeps error aggregate',
    () async {
      final repository = _FakeRepository();
      final audio = _FakeRecordingService();
      final whisper = _FakeTranscriptionService(
        responses: <String, Object>{
          '/tmp/chunk-1.wav': 'Ilk cumle',
          '/tmp/chunk-2.wav': Exception('network error'),
        },
      );

      final controller = AppController(
        repository: repository,
        transcriptionService: whisper,
        audioService: audio,
        summaryService: const LocalSummaryService(),
        authService: _FakeAuthService(),
      );

      await controller.bootstrap();
      await controller.startRecording('Demo');

      audio.emitChunk(
        const RecordedAudioChunk(
          path: '/tmp/chunk-1.wav',
          durationSeconds: 1,
          index: 1,
        ),
      );
      audio.emitChunk(
        const RecordedAudioChunk(
          path: '/tmp/chunk-2.wav',
          durationSeconds: 1,
          index: 2,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      await controller.stopRecording();

      expect(controller.transcripts, isNotEmpty);
      expect(
        controller.currentTranscript?.status,
        TranscriptStatus.transcriptionError,
      );
      expect(repository.savedStates, isNotEmpty);

      controller.dispose();
    },
  );

  test(
    'out-of-order timer persistence does not restore transcript to recording',
    () async {
      final repository = _DelayedRepository();
      final audio = _StopEmittingRecordingService(
        finalChunk: const RecordedAudioChunk(
          path: '/tmp/final-chunk.wav',
          durationSeconds: 1,
          index: 1,
        ),
      );
      final whisper = _DelayedTranscriptionService(
        delay: const Duration(milliseconds: 500),
        text: 'Merhaba dunya',
      );

      final controller = AppController(
        repository: repository,
        transcriptionService: whisper,
        audioService: audio,
        summaryService: const LocalSummaryService(),
        authService: _FakeAuthService(),
      );

      await controller.bootstrap();
      await controller.startRecording('Demo');
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await controller.stopRecording();
      await Future<void>.delayed(const Duration(milliseconds: 180));

      final reloaded = AppController(
        repository: repository,
        transcriptionService: whisper,
        audioService: _FakeRecordingService(),
        summaryService: const LocalSummaryService(),
        authService: _FakeAuthService(),
      );

      await reloaded.bootstrap();

      expect(reloaded.transcripts, isNotEmpty);
      expect(
        reloaded.transcripts.first.status,
        isNot(TranscriptStatus.recording),
      );

      controller.dispose();
      reloaded.dispose();
    },
  );

  test(
    'sync refresh must not leave completed transcript stuck in transcribing',
    () async {
      final repository = _SyncRefreshRaceRepository();
      final audio = _StopEmittingRecordingService(
        finalChunk: const RecordedAudioChunk(
          path: '/tmp/final-sync-race.wav',
          durationSeconds: 2,
          index: 1,
        ),
      );
      final whisper = _DelayedTranscriptionService(
        delay: const Duration(milliseconds: 20),
        text: 'Merhaba dunya',
      );
      final syncQueue = _ImmediateRefreshSyncQueueService();

      final controller = AppController(
        repository: repository,
        transcriptionService: whisper,
        audioService: audio,
        summaryService: const LocalSummaryService(),
        authService: _FakeAuthService(),
        syncQueueService: syncQueue,
      );

      await controller.bootstrap();
      await controller.startRecording('Demo');
      await controller.stopRecording();
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(controller.transcripts, isNotEmpty);
      expect(
        controller.transcripts.first.status,
        TranscriptStatus.transcriptionCompleted,
      );
      expect(
        controller.transcriptText(controller.transcripts.first.id),
        isNotEmpty,
      );

      controller.dispose();
    },
  );

  test(
    'sync refresh during active recording preserves current session',
    () async {
      final repository = _DelayedRepository();
      final audio = _FakeRecordingService();
      final whisper = _FakeTranscriptionService(
        responses: <String, Object>{'/tmp/live-after-refresh.wav': 'Merhaba'},
      );
      final syncQueue = _ImmediateRefreshSyncQueueService();

      final controller = AppController(
        repository: repository,
        transcriptionService: whisper,
        audioService: audio,
        summaryService: const LocalSummaryService(),
        authService: _FakeAuthService(),
        syncQueueService: syncQueue,
      );

      await controller.bootstrap();
      await controller.startRecording('Demo');
      await syncQueue.triggerSyncIfOnline();

      expect(controller.isRecording, isTrue);
      expect(controller.currentTranscript, isNotNull);

      audio.emitChunk(
        const RecordedAudioChunk(
          path: '/tmp/live-after-refresh.wav',
          durationSeconds: 2,
          index: 1,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.currentChunks, hasLength(1));
      expect(
        controller.transcriptText(controller.currentTranscript!.id),
        'Merhaba',
      );

      controller.dispose();
    },
  );

  test('transcription segments do not compress raw chunk timeline', () async {
    final repository = _DelayedRepository();
    final audio = _FakeRecordingService();
    final whisper = _FakeTranscriptionService(
      responses: <String, Object>{
        '/tmp/segment-short.wav': const TranscriptionResult(
          text: 'Kisa konusma',
          segments: [
            TranscriptionSegment(
              startSeconds: 0,
              endSeconds: 2,
              text: 'Kisa konusma',
            ),
          ],
        ),
        '/tmp/second.wav': 'Devam',
      },
    );

    final controller = AppController(
      repository: repository,
      transcriptionService: whisper,
      audioService: audio,
      summaryService: const LocalSummaryService(),
      authService: _FakeAuthService(),
    );

    await controller.bootstrap();
    await controller.startRecording('Demo');
    audio.emitChunk(
      const RecordedAudioChunk(
        path: '/tmp/segment-short.wav',
        durationSeconds: 15,
        index: 1,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    audio.emitChunk(
      const RecordedAudioChunk(
        path: '/tmp/second.wav',
        durationSeconds: 15,
        index: 2,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(controller.currentChunks, hasLength(2));
    expect(controller.currentChunks.first.startTime, 0);
    expect(controller.currentChunks.first.endTime, 15);
    expect(controller.currentChunks.last.startTime, 15);
    expect(controller.currentChunks.last.endTime, 30);

    controller.dispose();
  });

  test('bootstrap repairs stale recording transcripts', () async {
    final repository = _DelayedRepository();
    final now = DateTime.utc(2026, 5, 16, 12);
    repository._transcripts['stale-empty'] = Transcript(
      id: 'stale-empty',
      localId: 'stale-empty',
      title: 'Stale empty',
      durationSeconds: 2,
      status: TranscriptStatus.recording,
      recordedAt: now,
      createdAt: now,
      updatedAt: now,
      remoteId: '1',
      syncStatus: SyncStatus.synced,
    );
    repository._transcripts['stale-completed'] = Transcript(
      id: 'stale-completed',
      localId: 'stale-completed',
      title: 'Stale completed',
      durationSeconds: 2,
      status: TranscriptStatus.recording,
      recordedAt: now,
      createdAt: now,
      updatedAt: now,
      remoteId: '2',
      syncStatus: SyncStatus.synced,
    );
    repository._transcripts['stale-error'] = Transcript(
      id: 'stale-error',
      localId: 'stale-error',
      title: 'Stale error',
      durationSeconds: 2,
      status: TranscriptStatus.recording,
      recordedAt: now,
      createdAt: now,
      updatedAt: now,
      remoteId: '3',
      syncStatus: SyncStatus.synced,
    );
    repository._chunks['stale-completed-chunk-1'] = TranscriptChunk(
      id: 'stale-completed-chunk-1',
      transcriptId: 'stale-completed',
      chunkIndex: 1,
      text: 'Merhaba',
      audioPath: '/tmp/completed.wav',
      recordedAt: now,
      startTime: 0,
      endTime: 15,
      confidence: null,
      transcriptionError: null,
    );
    repository._chunks['stale-error-chunk-1'] = TranscriptChunk(
      id: 'stale-error-chunk-1',
      transcriptId: 'stale-error',
      chunkIndex: 1,
      text: '',
      audioPath: '/tmp/error.wav',
      recordedAt: now,
      startTime: 0,
      endTime: 20,
      confidence: null,
      transcriptionError: 'failed',
    );

    final controller = AppController(
      repository: repository,
      transcriptionService: _FakeTranscriptionService(responses: const {}),
      audioService: _FakeRecordingService(),
      summaryService: const LocalSummaryService(),
      authService: _FakeAuthService(),
    );

    await controller.bootstrap();

    final empty = controller.transcripts.firstWhere(
      (item) => item.id == 'stale-empty',
    );
    final completed = controller.transcripts.firstWhere(
      (item) => item.id == 'stale-completed',
    );
    final error = controller.transcripts.firstWhere(
      (item) => item.id == 'stale-error',
    );

    expect(empty.status, TranscriptStatus.empty);
    expect(empty.durationSeconds, 2);
    expect(empty.syncStatus, SyncStatus.pending);
    expect(completed.status, TranscriptStatus.transcriptionCompleted);
    expect(completed.durationSeconds, 15);
    expect(completed.syncStatus, SyncStatus.pending);
    expect(error.status, TranscriptStatus.transcriptionError);
    expect(error.durationSeconds, 20);
    expect(error.syncStatus, SyncStatus.pending);

    controller.dispose();
  });
}

class _FakeAuthService extends VoiceScribeAuthService {
  _FakeAuthService();

  static const AuthSessionState _session = AuthSessionState(
    userId: 'user-1',
    email: 'user@test.dev',
    accessToken: 'token',
    refreshToken: 'refresh',
    expiresAt: null,
  );

  @override
  Future<AuthSessionState?> restoreSession() async => _session;

  @override
  AuthSessionState? currentUser() => _session;

  @override
  Future<AuthSessionState> login({
    required String email,
    required String password,
  }) async => _session;

  @override
  Future<AuthSessionState> register({
    required String email,
    required String password,
  }) async => _session;

  @override
  Future<void> logout() async {}
}

class _FakeRepository implements TranscriptRepository {
  PersistedTranscriptState state = PersistedTranscriptState.empty();
  final List<PersistedTranscriptState> savedStates = [];
  final Map<String, String> savedSettings = {};

  @override
  Future<PersistedTranscriptState> load() async => state;

  @override
  Future<void> saveTranscript(Transcript transcript) async {
    savedStates.add(state);
  }

  @override
  Future<void> deleteTranscript(String id) async {}

  @override
  Future<void> saveChunk(TranscriptChunk chunk) async {}

  @override
  Future<void> saveSummary(Summary summary) async {}

  @override
  Future<void> saveProcessingJob(ProcessingJob job) async {}

  @override
  Future<void> deleteProcessingJob(String id) async {}

  @override
  Future<void> saveSetting(String key, String value) async {
    savedSettings[key] = value;
  }
}

class _DelayedRepository implements TranscriptRepository {
  final Map<String, Transcript> _transcripts = {};
  final Map<String, TranscriptChunk> _chunks = {};
  final Map<String, String> _settings = {};

  @override
  Future<PersistedTranscriptState> load() async {
    final transcripts = _transcripts.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final chunks = _chunks.values.toList()
      ..sort((a, b) => a.chunkIndex.compareTo(b.chunkIndex));
    return PersistedTranscriptState(
      transcripts: transcripts,
      currentTranscript: null,
      currentChunks: const [],
      allChunks: chunks,
      summaries: const [],
      processingJobs: const [],
      summaryProvider: 'local',
      summaryLength: 'medium',
      themeMode: _settings['themeMode'] ?? 'system',
    );
  }

  @override
  Future<void> saveTranscript(Transcript transcript) async {
    if (transcript.status == TranscriptStatus.recording &&
        transcript.durationSeconds > 0) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    _transcripts[transcript.id] = transcript;
  }

  @override
  Future<void> deleteTranscript(String id) async {
    _transcripts.remove(id);
    _chunks.removeWhere((_, chunk) => chunk.transcriptId == id);
  }

  @override
  Future<void> saveChunk(TranscriptChunk chunk) async {
    _chunks[chunk.id] = chunk;
  }

  @override
  Future<void> saveSummary(Summary summary) async {}

  @override
  Future<void> saveProcessingJob(ProcessingJob job) async {}

  @override
  Future<void> deleteProcessingJob(String id) async {}

  @override
  Future<void> saveSetting(String key, String value) async {
    _settings[key] = value;
  }
}

class _SyncRefreshRaceRepository extends _DelayedRepository {
  @override
  Future<void> saveTranscript(Transcript transcript) async {
    if (transcript.status == TranscriptStatus.transcriptionCompleted) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    await super.saveTranscript(transcript);
  }
}

class _FakeRecordingService implements RecordingService {
  final StreamController<RecordedAudioChunk> _chunks =
      StreamController.broadcast();
  final StreamController<double> _levels = StreamController.broadcast();

  @override
  Stream<RecordedAudioChunk> get chunks => _chunks.stream;

  @override
  Stream<double> get levels => _levels.stream;

  @override
  Future<void> dispose() async {
    await _chunks.close();
    await _levels.close();
  }

  void emitChunk(RecordedAudioChunk chunk) {
    _chunks.add(chunk);
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

class _StopEmittingRecordingService extends _FakeRecordingService {
  _StopEmittingRecordingService({required this.finalChunk});

  final RecordedAudioChunk finalChunk;

  @override
  Future<void> stop() async {
    emitChunk(finalChunk);
  }
}

class _ImmediateRefreshSyncQueueService extends SyncQueueService {
  SyncCompletionCallback? _onSyncComplete;
  Timer? _timer;

  @override
  Future<void> start({
    required AccessTokenProvider accessTokenProvider,
    SyncCompletionCallback? onSyncComplete,
  }) async {
    _onSyncComplete = onSyncComplete;
  }

  @override
  void scheduleSync({Duration delay = const Duration(milliseconds: 1)}) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      unawaited(_onSyncComplete?.call());
    });
  }

  @override
  Future<void> triggerSyncIfOnline() async {
    await _onSyncComplete?.call();
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
  }
}

class _FakeTranscriptionService implements TranscriptionService {
  _FakeTranscriptionService({required this.responses});

  final Map<String, Object> responses;
  final StreamController<ModelDownloadProgress> _progress =
      StreamController<ModelDownloadProgress>.broadcast();

  @override
  Stream<ModelDownloadProgress> get downloadProgress => _progress.stream;

  @override
  Future<void> dispose() async {
    await _progress.close();
  }

  @override
  Future<WhisperBootstrapResult> ensureModel() async {
    return const WhisperBootstrapResult(
      path: '/tmp/model.bin',
      downloaded: false,
      loaded: true,
    );
  }

  @override
  Future<TranscriptionResult> transcribeChunk(String audioPath) async {
    final response = responses[audioPath];
    if (response is Exception) {
      throw response;
    }
    if (response is TranscriptionResult) {
      return response;
    }
    return TranscriptionResult(
      text: response?.toString() ?? '',
      segments: const [],
    );
  }
}

class _DelayedTranscriptionService extends _FakeTranscriptionService {
  _DelayedTranscriptionService({required this.delay, required this.text})
    : super(responses: const {});

  final Duration delay;
  final String text;

  @override
  Future<TranscriptionResult> transcribeChunk(String audioPath) async {
    await Future<void>.delayed(delay);
    return TranscriptionResult(text: text, segments: const []);
  }
}
