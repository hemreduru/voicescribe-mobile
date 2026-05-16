import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/shared/services/auth/auth_service.dart';
import 'package:voicescribe_mobile/shared/services/database/sqflite_transcript_repository.dart';
import 'package:voicescribe_mobile/shared/services/summary_service.dart';
import 'package:voicescribe_mobile/shared/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/shared/services/transcript_repository.dart';
import 'package:voicescribe_mobile/shared/services/whisper_service.dart';
import 'package:voicescribe_mobile/shared/state/controllers/recording_controller.dart';
import 'package:voicescribe_mobile/shared/state/controllers/summary_controller.dart';
import 'package:voicescribe_mobile/shared/state/controllers/transcript_controller.dart';

part 'app_controller.g.dart';
part 'flows/auth_flow.dart';
part 'flows/recording_flow.dart';
part 'flows/transcription_flow.dart';
part 'flows/sync_flow.dart';

@Riverpod(keepAlive: true)
TranscriptRepository transcriptRepository(Ref ref) {
  return SqfliteTranscriptRepository();
}

@Riverpod(keepAlive: true)
TranscriptionService transcriptionService(Ref ref) {
  final service = WhisperTranscriptionService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
}

@Riverpod(keepAlive: true)
RecordingService audioRecordingService(Ref ref) {
  final service = AudioRecordingService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
}

@Riverpod(keepAlive: true)
SummaryService summaryService(Ref ref) {
  return const LocalSummaryService();
}

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  final controller = AppController(
    repository: ref.watch(transcriptRepositoryProvider),
    transcriptionService: ref.watch(transcriptionServiceProvider),
    audioService: ref.watch(audioRecordingServiceProvider),
    summaryService: ref.watch(summaryServiceProvider),
  );
  ref.onDispose(controller.dispose);
  unawaited(controller.bootstrap());
  return controller;
});

final appThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appControllerProvider).themeMode;
});

final appLocaleProvider = Provider<Locale?>((ref) {
  final preference = ref.watch(appControllerProvider).localePreference;
  return switch (preference) {
    'en' => const Locale('en'),
    'tr' => const Locale('tr'),
    _ => null,
  };
});

enum ModelBootstrapState { bootstrapping, ready, failed }

class AppController extends ChangeNotifier {
  AppController({
    required TranscriptRepository repository,
    required TranscriptionService transcriptionService,
    required RecordingService audioService,
    required SummaryService summaryService,
    VoiceScribeAuthService? authService,
    SyncQueueService? syncQueueService,
    AuthFlow? authFlow,
    RecordingFlow? recordingFlow,
    TranscriptionFlow? transcriptionFlow,
    SyncFlow? syncFlow,
  }) : _repository = repository,
       _transcriptionService = transcriptionService,
       _audioService = audioService,
       _summaryService = summaryService,
       _authService = authService ?? VoiceScribeAuthService(),
       _syncQueueService = syncQueueService ?? SyncQueueService(),
       _authFlow = authFlow ?? const AuthFlow(),
       _recordingFlow = recordingFlow ?? const RecordingFlow(),
       _transcriptionFlow = transcriptionFlow ?? const TranscriptionFlow(),
       _syncFlow = syncFlow ?? const SyncFlow() {
    _chunkSubscription = _audioService.chunks.listen(_handleAudioChunk);
    _levelSubscription = _audioService.levels.listen(_handleAudioLevel);
    _modelProgressSubscription = _transcriptionService.downloadProgress.listen((
      progress,
    ) {
      downloadProgress = progress;
      _notify();
    });
  }

  final TranscriptRepository _repository;
  final TranscriptionService _transcriptionService;
  final RecordingService _audioService;
  final SummaryService _summaryService;
  final VoiceScribeAuthService _authService;
  final SyncQueueService _syncQueueService;
  final AuthFlow _authFlow;
  final RecordingFlow _recordingFlow;
  final TranscriptionFlow _transcriptionFlow;
  final SyncFlow _syncFlow;

  final RecordingController recordingController = RecordingController();
  final TranscriptController transcriptController = TranscriptController();
  final SummaryController summaryController = SummaryController();

  StreamSubscription<RecordedAudioChunk>? _chunkSubscription;
  StreamSubscription<double>? _levelSubscription;
  StreamSubscription<ModelDownloadProgress>? _modelProgressSubscription;
  // ignore: use_late_for_private_fields_and_variables
  Timer? _durationTimer;
  Future<void> _pendingTranscriptSave = Future<void>.value();
  bool _disposed = false;
  bool _syncStarted = false;
  bool _authResolved = false;
  DateTime? _lastAudioLevelNotifyAt;
  double _lastNotifiedAudioLevel = 0;
  ThemeMode _themeMode = ThemeMode.system;
  String _localePreference = 'system';

  static const Duration _audioLevelNotifyInterval = Duration(milliseconds: 120);

  ModelBootstrapState modelState = ModelBootstrapState.bootstrapping;
  ModelDownloadProgress? downloadProgress;
  String? bootstrapError;
  AuthSessionState? _authSession;
  List<ProcessingJob> processingJobs = [];

  List<Transcript> get transcripts => transcriptController.transcripts;
  Transcript? get currentTranscript => transcriptController.currentTranscript;
  List<TranscriptChunk> get currentChunks => transcriptController.currentChunks;
  List<TranscriptChunk> get allChunks => transcriptController.allChunks;
  String? get lastError => transcriptController.lastError;

  bool get isRecording => recordingController.isRecording;
  bool get isPaused => recordingController.isPaused;
  int get durationSeconds => recordingController.durationSeconds;
  int get chunkCount => recordingController.chunkCount;
  double get audioLevel => recordingController.audioLevel;
  String get liveTranscriptPreview => recordingController.liveTranscriptPreview;

  List<Summary> get summaries => summaryController.summaries;
  String get summaryProvider => summaryController.provider;
  String get summaryLength => summaryController.length;
  bool get summaryGenerating => summaryController.generating;

  AuthSessionState? get authSession => _authSession;
  bool get isAuthResolved => _authResolved;
  bool get isAuthenticated => _authSession?.isAuthenticated ?? false;
  bool get isModelReady => modelState == ModelBootstrapState.ready;
  String? get currentUserId => _authSession?.userId;
  String? get currentUserEmail => _authSession?.email;
  ThemeMode get themeMode => _themeMode;
  String get localePreference => _localePreference;

  Future<void> bootstrap() async {
    modelState = ModelBootstrapState.bootstrapping;
    bootstrapError = null;
    _notify();

    final saved = await _repairStaleRecordings(await _repository.load());
    transcriptController.hydrate(saved);
    summaryController.hydrate(
      summaries: saved.summaries,
      provider: saved.summaryProvider,
      length: saved.summaryLength,
    );
    _themeMode = _themeModeFromKey(saved.themeMode);
    _localePreference = _localePreferenceFromKey(saved.localePreference);
    processingJobs = saved.processingJobs;
    _notify();

    try {
      _authSession = await _authService.restoreSession();
      _authResolved = true;
      if (_authSession != null) {
        await _ensureSyncStarted();
      }
      await _transcriptionService.ensureModel();
      modelState = ModelBootstrapState.ready;
    } catch (error) {
      _authResolved = true;
      bootstrapError = error.toString();
      modelState = ModelBootstrapState.failed;
    }
    _notify();
  }

  Future<void> register({required String email, required String password}) =>
      _authFlow.register(this, email: email, password: password);

  Future<void> login({required String email, required String password}) =>
      _authFlow.login(this, email: email, password: password);

  Future<void> logout() => _authFlow.logout(this);

  Future<void> restoreSession() => _authFlow.restoreSession(this);

  Future<void> startRecording(String? title) =>
      _recordingFlow.startRecording(this, title);

  Future<void> stopRecording() => _recordingFlow.stopRecording(this);

  Future<void> togglePause() => _recordingFlow.togglePause(this);

  void removeTranscript(String id) {
    _ensureAuthenticated();
    transcriptController.removeTranscript(id);
    processingJobs = processingJobs
        .where((item) => item.transcriptId != id)
        .toList();
    _persistLater(_repository.deleteTranscript(id));
    _notify();
  }

  void updateTranscriptTitle(String id, String title) {
    _ensureAuthenticated();
    final updated = transcriptController.updateTranscriptTitle(id, title);
    if (updated == null) {
      return;
    }
    _persistLater(_repository.saveTranscript(updated));
    _notify();
  }

  void setSummaryProvider(String value) {
    _ensureAuthenticated();
    summaryController.applyProvider(value);
    _persistLater(_repository.saveSetting('summaryProvider', value));
    _notify();
  }

  void setSummaryLength(String value) {
    _ensureAuthenticated();
    summaryController.applyLength(value);
    _persistLater(_repository.saveSetting('summaryLength', value));
    _notify();
  }

  void setThemeMode(ThemeMode value) {
    if (_themeMode == value) {
      return;
    }
    _themeMode = value;
    _persistLater(_repository.saveSetting('themeMode', _themeModeKey(value)));
    _notify();
  }

  void setLocalePreference(String value) {
    final normalized = _localePreferenceFromKey(value);
    if (_localePreference == normalized) {
      return;
    }
    _localePreference = normalized;
    _persistLater(_repository.saveSetting('localePreference', normalized));
    _notify();
  }

  Summary? latestSummaryFor(String transcriptId) {
    return summaryController.latestForTranscript(transcriptId);
  }

  Future<Summary?> generateSummaryForLatest() async {
    _ensureAuthenticated();
    if (transcripts.isEmpty) {
      return null;
    }
    final transcript = transcripts.first;
    final text = transcriptText(transcript.id);
    final summary = await summaryController.generate(
      transcript: transcript,
      transcriptText: text,
      summaryService: _summaryService,
    );
    if (summary != null) {
      await _persist(
        _repository.saveSummary(
          summary.copyWith(syncStatus: SyncStatus.pending),
        ),
      );
    }
    _notify();
    return summary;
  }

  Future<Summary?> generateSummaryForTranscript(String transcriptId) async {
    _ensureAuthenticated();
    final transcript = _findTranscript(
      transcriptController.transcripts,
      transcriptId,
    );
    if (transcript == null) {
      return null;
    }
    final text = transcriptText(transcript.id);
    final summary = await summaryController.generate(
      transcript: transcript,
      transcriptText: text,
      summaryService: _summaryService,
    );
    if (summary != null) {
      await _persist(
        _repository.saveSummary(
          summary.copyWith(syncStatus: SyncStatus.pending),
        ),
      );
    }
    _notify();
    return summary;
  }

  List<TranscriptChunk> chunksFor(String transcriptId) {
    return transcriptController.chunksFor(transcriptId);
  }

  String transcriptText(String transcriptId) {
    return transcriptController.transcriptText(transcriptId);
  }

  Future<void> ensureModelReady() async {
    if (isModelReady) {
      return;
    }
    modelState = ModelBootstrapState.bootstrapping;
    bootstrapError = null;
    _notify();

    try {
      await _transcriptionService.ensureModel();
      modelState = ModelBootstrapState.ready;
      bootstrapError = null;
    } catch (error) {
      modelState = ModelBootstrapState.failed;
      bootstrapError = error.toString();
      rethrow;
    } finally {
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimer();
    unawaited(_chunkSubscription?.cancel());
    unawaited(_levelSubscription?.cancel());
    unawaited(_modelProgressSubscription?.cancel());
    unawaited(_syncQueueService.dispose());
    super.dispose();
  }

  void _handleAudioChunk(RecordedAudioChunk audioChunk) {
    _recordingFlow.handleAudioChunk(this, audioChunk);
  }

  void _handleAudioLevel(double value) {
    recordingController.applyAudioLevel(value);
    final now = DateTime.now();
    final previousAt = _lastAudioLevelNotifyAt;
    final previousLevel = _lastNotifiedAudioLevel;
    final isResetEvent = value <= 0.01 && previousLevel > 0.01;
    final changedEnough = (value - previousLevel).abs() >= 0.06;
    final elapsedEnough =
        previousAt == null ||
        now.difference(previousAt) >= _audioLevelNotifyInterval;
    if (!(isResetEvent || changedEnough || elapsedEnough)) {
      return;
    }
    _lastAudioLevelNotifyAt = now;
    _lastNotifiedAudioLevel = value;
    _notify();
  }

  Future<void> _transcribe(TranscriptChunk chunk) =>
      _transcriptionFlow.transcribe(this, chunk);

  void _startTimer() {
    _recordingFlow.startTimer(this);
  }

  void _stopTimer() {
    _recordingFlow.stopTimer(this);
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _ensureAuthenticated() {
    _authFlow.ensureAuthenticated(this);
  }

  Future<void> _persist(Future<void> operation) =>
      _syncFlow.persist(this, operation);

  Future<void> _saveTranscript(
    Transcript transcript, {
    bool scheduleSync = false,
  }) {
    final next = _pendingTranscriptSave.catchError((_) {}).then((_) async {
      if (scheduleSync) {
        await _persist(_repository.saveTranscript(transcript));
      } else {
        await _repository.saveTranscript(transcript);
      }
      _reconcileSavedTranscript(transcript);
    });
    _pendingTranscriptSave = next;
    return next;
  }

  Future<void> _saveChunkAndTranscript(
    TranscriptChunk chunk,
    Transcript transcript, {
    bool scheduleSync = false,
  }) {
    final next = _pendingTranscriptSave.catchError((_) {}).then((_) async {
      await _repository.saveChunk(chunk);
      if (scheduleSync) {
        await _persist(_repository.saveTranscript(transcript));
      } else {
        await _repository.saveTranscript(transcript);
      }
      _reconcileSavedTranscript(transcript);
    });
    _pendingTranscriptSave = next;
    return next;
  }

  void _reconcileSavedTranscript(Transcript transcript) {
    final existingMatches = transcriptController.transcripts.where(
      (item) => item.id == transcript.id,
    );
    final existing = existingMatches.isEmpty ? null : existingMatches.first;
    if (existing != null && existing.updatedAt.isAfter(transcript.updatedAt)) {
      return;
    }
    transcriptController.replaceTranscript(transcript);
    if (transcriptController.currentTranscript == null ||
        transcriptController.currentTranscript!.id == transcript.id) {
      transcriptController.currentTranscript = transcript;
    }
    _notify();
  }

  void _saveTranscriptLater(
    Transcript transcript, {
    bool scheduleSync = false,
  }) {
    unawaited(_saveTranscript(transcript, scheduleSync: scheduleSync));
  }

  void _persistLater(Future<void> operation) {
    _syncFlow.persistLater(this, operation);
  }

  Future<void> _safeTriggerSync() => _syncFlow.safeTriggerSync(this);

  Future<void> _ensureSyncStarted() => _syncFlow.ensureSyncStarted(this);

  /// Called by SyncQueueService after a successful sync cycle.
  /// Reloads all data from SQLite to reflect server-pulled changes in the UI.
  Future<void> _refreshFromDb() async {
    try {
      final saved = _preserveActiveSession(await _repository.load());
      transcriptController.hydrate(saved);
      summaryController.hydrate(
        summaries: saved.summaries,
        provider: saved.summaryProvider,
        length: saved.summaryLength,
      );
      _themeMode = _themeModeFromKey(saved.themeMode);
      _localePreference = _localePreferenceFromKey(saved.localePreference);
      processingJobs = saved.processingJobs;
      _notify();
    } catch (_) {
      // Ignore refresh errors — UI will be stale until next sync
    }
  }

  Future<PersistedTranscriptState> _repairStaleRecordings(
    PersistedTranscriptState saved,
  ) async {
    final chunksByTranscript = <String, List<TranscriptChunk>>{};
    for (final chunk in saved.allChunks) {
      chunksByTranscript.putIfAbsent(chunk.transcriptId, () => []).add(chunk);
    }

    var changed = false;
    final repairedTranscripts = <Transcript>[];
    for (final transcript in saved.transcripts) {
      if (transcript.status != TranscriptStatus.recording) {
        repairedTranscripts.add(transcript);
        continue;
      }

      final chunks =
          chunksByTranscript[transcript.id] ?? const <TranscriptChunk>[];
      final repaired = transcript.copyWith(
        status: _staleRecordingStatusFor(chunks),
        durationSeconds: math.max(
          transcript.durationSeconds,
          _maxChunkEnd(chunks).round(),
        ),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        clearSyncError: true,
      );
      repairedTranscripts.add(repaired);
      changed = true;
      await _repository.saveTranscript(repaired);
    }

    if (!changed) {
      return saved;
    }

    return PersistedTranscriptState(
      transcripts: repairedTranscripts,
      currentTranscript: saved.currentTranscript,
      currentChunks: saved.currentChunks,
      allChunks: saved.allChunks,
      summaries: saved.summaries,
      processingJobs: saved.processingJobs,
      summaryProvider: saved.summaryProvider,
      summaryLength: saved.summaryLength,
      themeMode: saved.themeMode,
      localePreference: saved.localePreference,
    );
  }

  TranscriptStatus _staleRecordingStatusFor(List<TranscriptChunk> chunks) {
    if (chunks.isEmpty) {
      return TranscriptStatus.empty;
    }
    if (chunks.any((chunk) => (chunk.transcriptionError ?? '').isNotEmpty)) {
      return TranscriptStatus.transcriptionError;
    }
    if (chunks.any((chunk) => chunk.text.trim().isNotEmpty)) {
      return TranscriptStatus.transcriptionCompleted;
    }
    return TranscriptStatus.transcriptionError;
  }

  double _maxChunkEnd(List<TranscriptChunk> chunks) {
    var maxEnd = 0.0;
    for (final chunk in chunks) {
      if (chunk.endTime > maxEnd) {
        maxEnd = chunk.endTime;
      }
    }
    return maxEnd;
  }

  PersistedTranscriptState _preserveActiveSession(
    PersistedTranscriptState saved,
  ) {
    final activeTranscript = transcriptController.currentTranscript;
    if (activeTranscript == null) {
      return saved;
    }

    final savedTranscript = _findTranscript(
      saved.transcripts,
      activeTranscript.id,
    );
    final preservedTranscript = _mergeTranscriptSyncMetadata(
      activeTranscript,
      savedTranscript,
    );
    final savedChunksById = {
      for (final chunk in saved.allChunks) chunk.id: chunk,
    };
    final preservedCurrentChunks = transcriptController.currentChunks
        .map(
          (chunk) => _mergeChunkSyncMetadata(chunk, savedChunksById[chunk.id]),
        )
        .toList(growable: false);

    var replacedTranscript = false;
    final transcripts = <Transcript>[];
    for (final transcript in saved.transcripts) {
      if (transcript.id == preservedTranscript.id) {
        transcripts.add(preservedTranscript);
        replacedTranscript = true;
      } else {
        transcripts.add(transcript);
      }
    }
    if (!replacedTranscript) {
      transcripts.insert(0, preservedTranscript);
    }

    final allChunks = [
      for (final chunk in saved.allChunks)
        if (chunk.transcriptId != preservedTranscript.id) chunk,
      ...preservedCurrentChunks,
    ];

    return PersistedTranscriptState(
      transcripts: transcripts,
      currentTranscript: preservedTranscript,
      currentChunks: preservedCurrentChunks,
      allChunks: allChunks,
      summaries: saved.summaries,
      processingJobs: saved.processingJobs,
      summaryProvider: saved.summaryProvider,
      summaryLength: saved.summaryLength,
      themeMode: saved.themeMode,
      localePreference: saved.localePreference,
    );
  }

  Transcript? _findTranscript(List<Transcript> transcripts, String id) {
    for (final transcript in transcripts) {
      if (transcript.id == id) {
        return transcript;
      }
    }
    return null;
  }

  Transcript _mergeTranscriptSyncMetadata(
    Transcript active,
    Transcript? saved,
  ) {
    if (saved == null) {
      return active;
    }
    return active.copyWith(
      remoteId: active.remoteId ?? saved.remoteId,
      lastSyncedAt: active.lastSyncedAt ?? saved.lastSyncedAt,
    );
  }

  TranscriptChunk _mergeChunkSyncMetadata(
    TranscriptChunk active,
    TranscriptChunk? saved,
  ) {
    if (saved == null) {
      return active;
    }
    return active.copyWith(
      remoteId: active.remoteId ?? saved.remoteId,
      lastSyncedAt: active.lastSyncedAt ?? saved.lastSyncedAt,
    );
  }

  static ThemeMode _themeModeFromKey(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _themeModeKey(ThemeMode value) {
    return switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  static String _localePreferenceFromKey(String? value) {
    return switch (value) {
      'en' => 'en',
      'tr' => 'tr',
      _ => 'system',
    };
  }
}
