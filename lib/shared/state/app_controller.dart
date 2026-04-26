import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/domain.dart';
import '../services/audio_recording_service.dart';
import '../services/transcript_repository.dart';
import '../services/whisper_service.dart';
import '../utils/text_utils.dart';

final transcriptRepositoryProvider = Provider<TranscriptRepository>(
  (ref) => const JsonTranscriptRepository(),
);

final whisperServiceProvider = Provider<WhisperTranscriptionService>((ref) {
  final service = WhisperTranscriptionService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  final service = AudioRecordingService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  final controller = AppController(
    repository: ref.watch(transcriptRepositoryProvider),
    whisperService: ref.watch(whisperServiceProvider),
    audioService: ref.watch(audioRecordingServiceProvider),
  );
  ref.onDispose(controller.dispose);
  unawaited(controller.bootstrap());
  return controller;
});

enum ModelBootstrapState { bootstrapping, ready, failed }

class AppController extends ChangeNotifier {
  AppController({
    required TranscriptRepository repository,
    required WhisperTranscriptionService whisperService,
    required AudioRecordingService audioService,
  }) : _repository = repository,
       _whisperService = whisperService,
       _audioService = audioService {
    _chunkSubscription = _audioService.chunks.listen(_handleAudioChunk);
    _levelSubscription = _audioService.levels.listen((value) {
      audioLevel = value;
      _notify();
    });
    _modelProgressSubscription = _whisperService.downloadProgress.listen((
      progress,
    ) {
      downloadProgress = progress;
      _notify();
    });
  }

  final TranscriptRepository _repository;
  final WhisperTranscriptionService _whisperService;
  final AudioRecordingService _audioService;
  StreamSubscription<RecordedAudioChunk>? _chunkSubscription;
  StreamSubscription<double>? _levelSubscription;
  StreamSubscription<ModelDownloadProgress>? _modelProgressSubscription;
  Timer? _durationTimer;
  bool _disposed = false;
  int _pendingTranscriptions = 0;

  ModelBootstrapState modelState = ModelBootstrapState.bootstrapping;
  ModelDownloadProgress? downloadProgress;
  String? bootstrapError;
  String? lastError;

  List<Transcript> transcripts = [];
  Transcript? currentTranscript;
  List<TranscriptChunk> currentChunks = [];
  List<TranscriptChunk> allChunks = [];
  List<SpeakerProfile> speakers = [
    SpeakerProfile(
      id: 'speaker-1',
      name: 'Konuşmacı 1',
      embedding: const [],
      createdAt: DateTime.now(),
    ),
  ];

  bool isRecording = false;
  bool isPaused = false;
  int durationSeconds = 0;
  int chunkCount = 0;
  double audioLevel = 0;
  String liveTranscriptPreview = '';

  bool get hasPendingTranscriptions => _pendingTranscriptions > 0;

  Future<void> bootstrap() async {
    modelState = ModelBootstrapState.bootstrapping;
    bootstrapError = null;
    _notify();

    final saved = await _repository.load();
    transcripts = saved.transcripts;
    currentTranscript = saved.currentTranscript;
    currentChunks = saved.currentChunks;
    allChunks = saved.allChunks;
    _notify();

    try {
      await _whisperService.ensureModel();
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

    final now = DateTime.now();
    final id = 'local-${now.millisecondsSinceEpoch}';
    final transcript = Transcript(
      id: id,
      localId: id,
      title: title?.trim().isNotEmpty == true
          ? title!.trim()
          : now.toLocal().toString(),
      durationSeconds: 0,
      status: TranscriptStatus.recording,
      recordedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    transcripts = [transcript, ...transcripts];
    currentTranscript = transcript;
    currentChunks = [];
    isRecording = true;
    isPaused = false;
    durationSeconds = 0;
    chunkCount = 0;
    liveTranscriptPreview = '';
    lastError = null;
    _notify();

    try {
      await _audioService.start();
      _startTimer();
      await _persist();
    } catch (error) {
      transcripts = transcripts.where((item) => item.id != id).toList();
      currentTranscript = null;
      isRecording = false;
      isPaused = false;
      lastError = error.toString();
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

    isRecording = false;
    isPaused = false;
    audioLevel = 0;

    final transcript = currentTranscript;
    if (transcript != null) {
      _updateTranscript(
        transcript.id,
        status: currentChunks.isEmpty
            ? TranscriptStatus.empty
            : TranscriptStatus.transcribing,
        durationSeconds: durationSeconds,
      );
    }
    await _persist();
    _notify();
  }

  Future<void> togglePause() async {
    if (!isRecording) {
      return;
    }
    if (isPaused) {
      await _audioService.resume();
      isPaused = false;
      _startTimer();
    } else {
      await _audioService.pause();
      isPaused = true;
      _stopTimer();
    }
    _notify();
  }

  void removeTranscript(String id) {
    transcripts = transcripts.where((item) => item.id != id).toList();
    allChunks = allChunks.where((item) => item.transcriptId != id).toList();
    if (currentTranscript?.id == id) {
      currentTranscript = null;
      currentChunks = [];
    }
    unawaited(_persist());
    _notify();
  }

  void addSpeaker(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    speakers = [
      ...speakers,
      SpeakerProfile(
        id: 'speaker-${DateTime.now().microsecondsSinceEpoch}',
        name: trimmed,
        embedding: const [],
        createdAt: DateTime.now(),
      ),
    ];
    _notify();
  }

  void updateSpeaker(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    speakers = speakers
        .map(
          (speaker) =>
              speaker.id == id ? speaker.copyWith(name: trimmed) : speaker,
        )
        .toList();
    _notify();
  }

  void deleteSpeaker(String id) {
    speakers = speakers.where((speaker) => speaker.id != id).toList();
    _notify();
  }

  List<TranscriptChunk> chunksFor(String transcriptId) {
    final chunks =
        allChunks.where((chunk) => chunk.transcriptId == transcriptId).toList()
          ..sort((a, b) => a.chunkIndex.compareTo(b.chunkIndex));
    return chunks;
  }

  String transcriptText(String transcriptId) {
    return mergeTranscriptChunks(chunksFor(transcriptId));
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

    final previousEnd = currentChunks.isEmpty
        ? 0.0
        : currentChunks.last.endTime;
    final now = DateTime.now();
    final chunk = TranscriptChunk(
      id: '${transcript.id}-chunk-${currentChunks.length + 1}',
      transcriptId: transcript.id,
      chunkIndex: currentChunks.length + 1,
      text: '',
      audioPath: audioChunk.path,
      recordedAt: now,
      startTime: previousEnd,
      endTime: previousEnd + audioChunk.durationSeconds,
      speakerLabel: null,
      confidence: null,
    );

    currentChunks = [...currentChunks, chunk];
    allChunks = [...allChunks, chunk];
    chunkCount = currentChunks.length;
    _updateTranscript(
      transcript.id,
      status: TranscriptStatus.transcribing,
      durationSeconds: chunk.endTime.round(),
    );
    unawaited(_persist());
    _notify();
    unawaited(_transcribe(chunk));
  }

  Future<void> _transcribe(TranscriptChunk chunk) async {
    _pendingTranscriptions++;
    try {
      final rawText = await _whisperService.transcribeChunk(
        chunk.audioPath ?? '',
      );
      final text = normalizeWhitespace(rawText);
      if (text.isEmpty) {
        return;
      }

      final previousChunk = chunksFor(
        chunk.transcriptId,
      ).where((item) => item.chunkIndex == chunk.chunkIndex - 1).firstOrNull;
      final deduped = previousChunk == null
          ? text
          : removeOverlap(previousChunk.text, text);
      _updateChunkText(chunk.id, deduped);
      liveTranscriptPreview = normalizeWhitespace(
        '$liveTranscriptPreview $deduped',
      );
      if (liveTranscriptPreview.length > 500) {
        liveTranscriptPreview = liveTranscriptPreview.substring(
          liveTranscriptPreview.length - 500,
        );
      }
      _updateTranscript(
        chunk.transcriptId,
        status: TranscriptStatus.completed,
        updatedAt: DateTime.now(),
      );
    } catch (error) {
      lastError = error.toString();
      _updateTranscript(
        chunk.transcriptId,
        status: TranscriptStatus.transcriptionError,
        updatedAt: DateTime.now(),
      );
    } finally {
      _pendingTranscriptions--;
      final path = chunk.audioPath;
      if (path != null) {
        unawaited(File(path).delete().catchError((_) => File(path)));
      }
      await _persist();
      _notify();
    }
  }

  void _updateChunkText(String chunkId, String text) {
    currentChunks = currentChunks
        .map(
          (chunk) => chunk.id == chunkId ? chunk.copyWith(text: text) : chunk,
        )
        .toList();
    allChunks = allChunks
        .map(
          (chunk) => chunk.id == chunkId ? chunk.copyWith(text: text) : chunk,
        )
        .toList();
  }

  void _updateTranscript(
    String id, {
    TranscriptStatus? status,
    int? durationSeconds,
    DateTime? updatedAt,
  }) {
    final nextUpdatedAt = updatedAt ?? DateTime.now();
    transcripts = transcripts
        .map(
          (transcript) => transcript.id == id
              ? transcript.copyWith(
                  status: status,
                  durationSeconds: durationSeconds,
                  updatedAt: nextUpdatedAt,
                )
              : transcript,
        )
        .toList();
    if (currentTranscript?.id == id) {
      currentTranscript = currentTranscript!.copyWith(
        status: status,
        durationSeconds: durationSeconds,
        updatedAt: nextUpdatedAt,
      );
    }
  }

  Future<void> _persist() {
    return _repository.save(
      PersistedTranscriptState(
        transcripts: transcripts,
        currentTranscript: currentTranscript,
        currentChunks: currentChunks,
        allChunks: allChunks,
      ),
    );
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      durationSeconds++;
      final transcript = currentTranscript;
      if (transcript != null) {
        _updateTranscript(transcript.id, durationSeconds: durationSeconds);
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

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
