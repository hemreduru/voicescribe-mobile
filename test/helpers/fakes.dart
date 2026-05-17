import 'dart:async';

import 'package:voicescribe_mobile/data/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/auth_repository.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';

class FakeTranscriptRepository implements TranscriptRepository {
  FakeTranscriptRepository({TranscriptSnapshot? initial})
    : snapshot = initial ?? TranscriptSnapshot.empty();

  TranscriptSnapshot snapshot;
  final _controller = StreamController<TranscriptSnapshot>.broadcast();
  final Map<String, AppPreferences> savedPreferences = {};

  @override
  Stream<TranscriptSnapshot> watchSnapshot() => _controller.stream;

  @override
  Future<TranscriptSnapshot> loadSnapshot() async => snapshot;

  @override
  Future<void> refresh() async => emit();

  @override
  Future<void> saveTranscript(Transcript transcript) async {
    final existing = snapshot.transcripts
        .where((item) => item.id != transcript.id)
        .toList();
    snapshot = snapshot.copyWith(transcripts: [transcript, ...existing]);
    emit();
  }

  @override
  Future<void> deleteTranscript(String id) async {
    snapshot = snapshot.copyWith(
      transcripts: snapshot.transcripts.where((item) => item.id != id).toList(),
      chunks: snapshot.chunks.where((item) => item.transcriptId != id).toList(),
      summaries: snapshot.summaries
          .where((item) => item.transcriptId != id)
          .toList(),
    );
    emit();
  }

  @override
  Future<void> saveChunk(TranscriptChunk chunk) async {
    snapshot = snapshot.copyWith(
      chunks: [...snapshot.chunks.where((item) => item.id != chunk.id), chunk],
    );
    emit();
  }

  @override
  Future<void> saveSummary(Summary summary) async {
    snapshot = snapshot.copyWith(
      summaries: [
        summary,
        ...snapshot.summaries.where((item) => item.id != summary.id),
      ],
    );
    emit();
  }

  @override
  Future<void> deleteSummary(String id) async {
    snapshot = snapshot.copyWith(
      summaries: snapshot.summaries.where((item) => item.id != id).toList(),
    );
    emit();
  }

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    snapshot = snapshot.copyWith(preferences: preferences);
    savedPreferences['latest'] = preferences;
    emit();
  }

  void emit() {
    if (!_controller.isClosed) {
      _controller.add(snapshot);
    }
  }

  Future<void> dispose() => _controller.close();
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthSessionState? session}) : _session = session;

  AuthSessionState? _session;
  final _controller = StreamController<AuthSessionState?>.broadcast();

  static const defaultSession = AuthSessionState(
    userId: 'user-1',
    email: 'user@test.dev',
    accessToken: 'token',
    refreshToken: 'refresh',
    expiresAt: null,
  );

  @override
  Stream<AuthSessionState?> watchSession() => _controller.stream;

  @override
  AuthSessionState? currentSession() => _session;

  @override
  Future<AuthSessionState?> restoreSession() async {
    _controller.add(_session);
    return _session;
  }

  @override
  Future<AuthSessionState> login({
    required String email,
    required String password,
  }) async {
    _session = defaultSession.copyWith(email: email);
    _controller.add(_session);
    return _session!;
  }

  @override
  Future<AuthSessionState> register({
    required String email,
    required String password,
  }) => login(email: email, password: password);

  @override
  Future<void> logout() async {
    _session = null;
    _controller.add(null);
  }

  Future<void> dispose() => _controller.close();
}

class FakeRecordingService implements RecordingService {
  final _chunks = StreamController<RecordedAudioChunk>.broadcast();
  final _levels = StreamController<double>.broadcast();

  @override
  Stream<RecordedAudioChunk> get chunks => _chunks.stream;

  @override
  Stream<double> get levels => _levels.stream;

  void emitChunk(RecordedAudioChunk chunk) {
    _chunks.add(chunk);
  }

  void emitLevel(double value) {
    _levels.add(value);
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _chunks.close();
    await _levels.close();
  }
}

class FakeTranscriptionService implements TranscriptionService {
  FakeTranscriptionService({Map<String, Object>? responses})
    : responses = responses ?? const {};

  final Map<String, Object> responses;
  final _progress = StreamController<ModelDownloadProgress>.broadcast();

  @override
  Stream<ModelDownloadProgress> get downloadProgress => _progress.stream;

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

  @override
  Future<void> dispose() async {
    await _progress.close();
  }
}

class FakeSyncQueueService extends SyncQueueService {
  SyncCompletionCallback? onComplete;
  final _events = StreamController<SyncEvent>.broadcast();
  bool failManualSync = false;
  int triggerSyncCallCount = 0;
  int manualSyncCallCount = 0;
  int scheduledSyncCallCount = 0;
  SyncTrigger? lastTrigger;
  SyncTrigger? lastManualTrigger;
  SyncTrigger? lastScheduledTrigger;
  DateTime? lastSuccessfulSyncAt;

  @override
  Stream<SyncEvent> get syncEvents => _events.stream;

  @override
  Future<void> start({
    required AccessTokenProvider accessTokenProvider,
    SyncCompletionCallback? onSyncComplete,
  }) async {
    onComplete = onSyncComplete;
  }

  @override
  Future<void> triggerSyncIfOnline({
    SyncTrigger trigger = SyncTrigger.auto,
    bool force = false,
  }) async {
    triggerSyncCallCount += 1;
    lastTrigger = trigger;
    await onComplete?.call();
  }

  @override
  Future<void> runManualSync({SyncTrigger trigger = SyncTrigger.manual}) async {
    manualSyncCallCount += 1;
    lastManualTrigger = trigger;
    _events.add(
      SyncEvent(
        type: SyncEventType.started,
        trigger: trigger,
        occurredAt: DateTime.now(),
        metrics: const SyncMetrics.empty(),
      ),
    );
    if (failManualSync) {
      _events.add(
        SyncEvent(
          type: SyncEventType.failure,
          trigger: trigger,
          occurredAt: DateTime.now(),
          metrics: const SyncMetrics.empty(),
          error: 'manual_sync_failed',
        ),
      );
      throw StateError('manual_sync_failed');
    }
    lastSuccessfulSyncAt = DateTime.now();
    _events.add(
      SyncEvent(
        type: SyncEventType.success,
        trigger: trigger,
        occurredAt: lastSuccessfulSyncAt!,
        metrics: const SyncMetrics.empty(),
      ),
    );
    await onComplete?.call();
  }

  @override
  void scheduleSync({
    Duration delay = const Duration(seconds: 2),
    SyncTrigger trigger = SyncTrigger.auto,
  }) {
    scheduledSyncCallCount += 1;
    lastScheduledTrigger = trigger;
  }

  @override
  Future<DateTime?> readLastSuccessfulSyncAt() async => lastSuccessfulSyncAt;

  @override
  Future<void> dispose() async {
    await _events.close();
  }
}
