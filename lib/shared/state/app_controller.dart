import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/shared/services/auth/auth_service.dart';
import 'package:voicescribe_mobile/shared/services/database/sqflite_transcript_repository.dart';
import 'package:voicescribe_mobile/shared/services/speaker/speaker_analysis_service.dart';
import 'package:voicescribe_mobile/shared/services/summary_service.dart';
import 'package:voicescribe_mobile/shared/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/shared/services/transcript_repository.dart';
import 'package:voicescribe_mobile/shared/services/whisper_service.dart';
import 'package:voicescribe_mobile/shared/state/controllers/recording_controller.dart';
import 'package:voicescribe_mobile/shared/state/controllers/speaker_controller.dart';
import 'package:voicescribe_mobile/shared/state/controllers/summary_controller.dart';
import 'package:voicescribe_mobile/shared/state/controllers/transcript_controller.dart';

part 'app_controller.g.dart';
part 'flows/auth_flow.dart';
part 'flows/recording_flow.dart';
part 'flows/transcription_flow.dart';
part 'flows/speaker_analysis_flow.dart';
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

enum ModelBootstrapState { bootstrapping, ready, failed }

class AppController extends ChangeNotifier {
  AppController({
    required TranscriptRepository repository,
    required TranscriptionService transcriptionService,
    required RecordingService audioService,
    required SummaryService summaryService,
    VoiceScribeAuthService? authService,
    SyncQueueService? syncQueueService,
    SpeakerAnalysisService? speakerAnalysisService,
    AuthFlow? authFlow,
    RecordingFlow? recordingFlow,
    TranscriptionFlow? transcriptionFlow,
    SpeakerAnalysisFlow? speakerAnalysisFlow,
    SyncFlow? syncFlow,
  }) : _repository = repository,
       _transcriptionService = transcriptionService,
       _audioService = audioService,
       _summaryService = summaryService,
       _authService = authService ?? VoiceScribeAuthService(),
       _syncQueueService = syncQueueService ?? SyncQueueService(),
       _speakerAnalysisService =
           speakerAnalysisService ?? SpeakerAnalysisService(),
       _authFlow = authFlow ?? const AuthFlow(),
       _recordingFlow = recordingFlow ?? const RecordingFlow(),
       _transcriptionFlow = transcriptionFlow ?? const TranscriptionFlow(),
       _speakerAnalysisFlow =
           speakerAnalysisFlow ?? const SpeakerAnalysisFlow(),
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
  final SpeakerAnalysisService _speakerAnalysisService;
  final AuthFlow _authFlow;
  final RecordingFlow _recordingFlow;
  final TranscriptionFlow _transcriptionFlow;
  final SpeakerAnalysisFlow _speakerAnalysisFlow;
  final SyncFlow _syncFlow;

  final RecordingController recordingController = RecordingController();
  final TranscriptController transcriptController = TranscriptController();
  final SpeakerController speakerController = SpeakerController();
  final SummaryController summaryController = SummaryController();

  StreamSubscription<RecordedAudioChunk>? _chunkSubscription;
  StreamSubscription<double>? _levelSubscription;
  StreamSubscription<ModelDownloadProgress>? _modelProgressSubscription;
  // ignore: use_late_for_private_fields_and_variables
  Timer? _durationTimer;
  bool _disposed = false;
  bool _speakerAnalysisInProgress = false;
  bool _syncStarted = false;
  bool _authResolved = false;
  DateTime? _lastAudioLevelNotifyAt;
  double _lastNotifiedAudioLevel = 0;

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

  List<SpeakerProfile> get speakers => speakerController.speakers;

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
  double get speakerSimilarityThreshold =>
      _speakerAnalysisService.similarityThreshold;

  Future<void> bootstrap() async {
    modelState = ModelBootstrapState.bootstrapping;
    bootstrapError = null;
    _notify();

    final saved = await _repository.load();
    transcriptController.hydrate(saved);
    speakerController.hydrate(saved.speakers);
    summaryController.hydrate(
      summaries: saved.summaries,
      provider: saved.summaryProvider,
      length: saved.summaryLength,
    );
    _speakerAnalysisService.setSimilarityThreshold(
      saved.speakerSimilarityThreshold,
    );
    processingJobs = saved.processingJobs;
    await _archiveDuplicateSpeakerAnalysisJobs();
    _notify();

    try {
      _authSession = await _authService.restoreSession();
      _authResolved = true;
      if (_authSession != null) {
        await _ensureSyncStarted();
      }
      await _recoverPendingProcessingJobs();
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

  void addSpeaker(String name) {
    _ensureAuthenticated();
    speakerController.addSpeaker(name, userId: currentUserId);
    _persistLater(_repository.saveSpeaker(speakers.last));
    _notify();
  }

  void updateSpeaker(String id, String name) {
    _ensureAuthenticated();
    speakerController.updateSpeaker(id, name);
    final speaker = speakers.firstWhere((s) => s.id == id);
    _persistLater(_repository.saveSpeaker(speaker));
    _notify();
  }

  void deleteSpeaker(String id) {
    _ensureAuthenticated();
    speakerController.deleteSpeaker(id);
    _persistLater(_repository.deleteSpeaker(id));
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

  List<TranscriptChunk> chunksFor(String transcriptId) {
    return transcriptController.chunksFor(transcriptId);
  }

  String transcriptText(String transcriptId) {
    return transcriptController.transcriptText(transcriptId);
  }

  Future<double?> calibrateSpeakerThreshold() async {
    _ensureAuthenticated();
    final threshold = await _speakerAnalysisFlow.calibrateThreshold(this);
    if (threshold != null) {
      _notify();
    }
    return threshold;
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

  Future<void> _recoverPendingProcessingJobs() =>
      _speakerAnalysisFlow.recoverPendingProcessingJobs(this);

  Future<void> _enqueueSpeakerAnalysisIfReady(String transcriptId) =>
      _speakerAnalysisFlow.enqueueSpeakerAnalysisIfReady(this, transcriptId);

  Future<void> _archiveDuplicateSpeakerAnalysisJobs() =>
      _speakerAnalysisFlow.archiveDuplicateSpeakerAnalysisJobs(this);

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

  void _persistLater(Future<void> operation) {
    _syncFlow.persistLater(this, operation);
  }

  Future<void> _safeTriggerSync() => _syncFlow.safeTriggerSync(this);

  Future<void> _ensureSyncStarted() => _syncFlow.ensureSyncStarted(this);
}
