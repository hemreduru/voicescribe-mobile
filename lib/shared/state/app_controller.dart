import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_riverpod/legacy.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/shared/services/database/sqflite_transcript_repository.dart';
import 'package:voicescribe_mobile/shared/services/summary_service.dart';
import 'package:voicescribe_mobile/shared/services/transcript_repository.dart';
import 'package:voicescribe_mobile/shared/services/whisper_service.dart';
import 'package:voicescribe_mobile/shared/state/controllers/recording_controller.dart';
import 'package:voicescribe_mobile/shared/state/controllers/speaker_controller.dart';
import 'package:voicescribe_mobile/shared/state/controllers/summary_controller.dart';
import 'package:voicescribe_mobile/shared/state/controllers/transcript_controller.dart';

part 'app_controller.g.dart';

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
  }) : _repository = repository,
       _transcriptionService = transcriptionService,
       _audioService = audioService,
       _summaryService = summaryService {
    _chunkSubscription = _audioService.chunks.listen(_handleAudioChunk);
    _levelSubscription = _audioService.levels.listen((value) {
      recordingController.applyAudioLevel(value);
      _notify();
    });
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

  final RecordingController recordingController = RecordingController();
  final TranscriptController transcriptController = TranscriptController();
  final SpeakerController speakerController = SpeakerController();
  final SummaryController summaryController = SummaryController();

  StreamSubscription<RecordedAudioChunk>? _chunkSubscription;
  StreamSubscription<double>? _levelSubscription;
  StreamSubscription<ModelDownloadProgress>? _modelProgressSubscription;
  Timer? _durationTimer;
  bool _disposed = false;

  ModelBootstrapState modelState = ModelBootstrapState.bootstrapping;
  ModelDownloadProgress? downloadProgress;
  String? bootstrapError;

  List<Transcript> get transcripts => transcriptController.transcripts;
  Transcript? get currentTranscript => transcriptController.currentTranscript;
  List<TranscriptChunk> get currentChunks => transcriptController.currentChunks;
  List<TranscriptChunk> get allChunks => transcriptController.allChunks;
  String? get lastError => transcriptController.lastError;

  List<SpeakerProfile> get speakers => speakerController.speakers;
  bool get speakerRecognitionEnabled => speakerController.recognitionEnabled;

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

  Future<void> bootstrap() async {
    modelState = ModelBootstrapState.bootstrapping;
    bootstrapError = null;
    _notify();

    final saved = await _repository.load();
    transcriptController.hydrate(saved);
    speakerController.hydrate(
      saved.speakers,
      recognitionEnabled: saved.speakerRecognitionEnabled,
    );
    summaryController.hydrate(
      summaries: saved.summaries,
      provider: saved.summaryProvider,
      length: saved.summaryLength,
    );
    _notify();

    try {
      await _transcriptionService.ensureModel();
      modelState = ModelBootstrapState.ready;
    } catch (error) {
      bootstrapError = error.toString();
      modelState = ModelBootstrapState.failed;
    }
    _notify();
  }

  Future<void> startRecording(String? title) async {
    if (isRecording) {
      return;
    }

    final transcript = transcriptController.startSession(title);
    recordingController.start();
    _notify();

    try {
      await _audioService.start();
      _startTimer();
      await _repository.saveTranscript(transcript);
    } catch (error) {
      transcriptController.removeTranscript(transcript.id);
      recordingController.stop();
      transcriptController.lastError = error.toString();
      _notify();
      rethrow;
    }
  }

  Future<void> stopRecording() async {
    if (!isRecording) {
      return;
    }
    _stopTimer();
    await _audioService.stop();

    recordingController.stop();
    transcriptController.markRecordingStopped(
      durationSeconds: recordingController.durationSeconds,
    );
    if (currentTranscript != null) {
      await _repository.saveTranscript(currentTranscript!);
    }
    _notify();
  }

  Future<void> togglePause() async {
    if (!isRecording) {
      return;
    }
    if (isPaused) {
      await _audioService.resume();
      recordingController.resume();
      _startTimer();
    } else {
      await _audioService.pause();
      recordingController.pause();
      _stopTimer();
    }
    _notify();
  }

  void removeTranscript(String id) {
    transcriptController.removeTranscript(id);
    unawaited(_repository.deleteTranscript(id));
    _notify();
  }

  void setSpeakerRecognitionEnabled({required bool value}) {
    speakerController.applyRecognitionEnabled(value: value);
    unawaited(
      _repository.saveSetting('speakerRecognitionEnabled', value.toString()),
    );
    _notify();
  }

  void addSpeaker(String name) {
    speakerController.addSpeaker(name);
    unawaited(_repository.saveSpeaker(speakers.last));
    _notify();
  }

  void updateSpeaker(String id, String name) {
    speakerController.updateSpeaker(id, name);
    final speaker = speakers.firstWhere((s) => s.id == id);
    unawaited(_repository.saveSpeaker(speaker));
    _notify();
  }

  void deleteSpeaker(String id) {
    speakerController.deleteSpeaker(id);
    unawaited(_repository.deleteSpeaker(id));
    _notify();
  }

  void setSummaryProvider(String value) {
    summaryController.applyProvider(value);
    unawaited(_repository.saveSetting('summaryProvider', value));
    _notify();
  }

  void setSummaryLength(String value) {
    summaryController.applyLength(value);
    unawaited(_repository.saveSetting('summaryLength', value));
    _notify();
  }

  Summary? latestSummaryFor(String transcriptId) {
    return summaryController.latestForTranscript(transcriptId);
  }

  Future<Summary?> generateSummaryForLatest() async {
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
      await _repository.saveSummary(summary);
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

  @override
  void dispose() {
    _disposed = true;
    _stopTimer();
    unawaited(_chunkSubscription?.cancel());
    unawaited(_levelSubscription?.cancel());
    unawaited(_modelProgressSubscription?.cancel());
    super.dispose();
  }

  void _handleAudioChunk(RecordedAudioChunk audioChunk) {
    final transcript = currentTranscript;
    if (transcript == null) {
      return;
    }

    final chunk = transcriptController.addRecordedChunk(audioChunk);
    recordingController.incrementChunkCount();
    _notify();
    unawaited(_repository.saveChunk(chunk));
    unawaited(_transcribe(chunk));
  }

  Future<void> _transcribe(TranscriptChunk chunk) async {
    try {
      final rawText = await _transcriptionService.transcribeChunk(
        chunk.audioPath ?? '',
      );
      transcriptController.applyTranscriptionSuccess(chunk, rawText);
      final updatedChunk = transcriptController.allChunks.firstWhere(
        (c) => c.id == chunk.id,
      );
      unawaited(_repository.saveChunk(updatedChunk));
      final matches = currentChunks.where((item) => item.id == chunk.id);
      final current = matches.isEmpty ? null : matches.first;
      if (current != null && current.text.trim().isNotEmpty) {
        recordingController.appendPreview(current.text);
      }
    } catch (error) {
      transcriptController.applyTranscriptionError(chunk, error);
      final updatedChunk = transcriptController.allChunks.firstWhere(
        (c) => c.id == chunk.id,
      );
      unawaited(_repository.saveChunk(updatedChunk));
    } finally {
      final path = chunk.audioPath;
      if (path != null) {
        unawaited(File(path).delete().catchError((_) => File(path)));
      }
      if (currentTranscript != null) {
        unawaited(_repository.saveTranscript(currentTranscript!));
      }
      _notify();
    }
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      recordingController.tick();
      transcriptController.updateCurrentDuration(
        recordingController.durationSeconds,
      );
      if (currentTranscript != null) {
        unawaited(_repository.saveTranscript(currentTranscript!));
      }
      _notify();
    });
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
