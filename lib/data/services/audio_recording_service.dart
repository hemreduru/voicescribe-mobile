import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:voicescribe_mobile/data/services/pcm_chunker.dart';
import 'package:voicescribe_mobile/data/services/wav_writer.dart';
import 'package:voicescribe_mobile/ui/core/utils/logger.dart';

class RecordedAudioChunk {
  const RecordedAudioChunk({
    required this.path,
    required this.durationSeconds,
    required this.index,
    required this.averageLevel,
  });

  final String path;
  final double durationSeconds;
  final int index;
  final double averageLevel;
}

abstract class RecordingService {
  Stream<RecordedAudioChunk> get chunks;
  Stream<double> get levels;

  /// Sets the text shown in the Android foreground-service notification while
  /// recording. Call from the UI layer (which has localized strings) before
  /// [start]. No-op on platforms without a foreground recording service.
  void setForegroundNotification({required String title, String? content});

  Future<void> start();
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
}

class AudioRecordingService implements RecordingService {
  AudioRecordingService({
    AudioRecorder? recorder,
    PcmChunker? chunker,
    WavWriter? wavWriter,
  }) : _recorder = recorder ?? AudioRecorder(),
       _chunker = chunker ?? PcmChunker(),
       _wavWriter = wavWriter ?? const WavWriter();

  final AudioRecorder _recorder;
  final PcmChunker _chunker;
  final WavWriter _wavWriter;
  final _chunksController = StreamController<RecordedAudioChunk>.broadcast(
    sync: true,
  );
  final _levelsController = StreamController<double>.broadcast(sync: true);

  StreamSubscription<List<int>>? _recordingSubscription;
  bool _isRecording = false;
  Future<void> _emitTask = Future.value();
  String _notificationTitle = 'VoiceScribe';
  String? _notificationContent;
  // Consecutive chunk-write failures. A full disk fails *every* write, so a run
  // of failures (vs. a one-off IO hiccup) means we should stop and tell the
  // user rather than silently dropping audio for the rest of the session.
  int _consecutiveEmitFailures = 0;
  bool _storageFaultRaised = false;
  static const int _emitFailureLimit = 2;

  @override
  void setForegroundNotification({required String title, String? content}) {
    _notificationTitle = title.trim().isEmpty ? 'VoiceScribe' : title.trim();
    _notificationContent = content;
  }

  @override
  Stream<RecordedAudioChunk> get chunks => _chunksController.stream;

  @override
  Stream<double> get levels => _levelsController.stream;

  @override
  Future<void> start() async {
    if (_isRecording) {
      return;
    }
    if (!await _recorder.hasPermission()) {
      throw const RecordingPermissionException();
    }

    _chunker.reset();
    final stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        streamBufferSize: 3200,
        // Run a foreground service with a persistent notification so recording
        // survives the app being backgrounded / the screen turning off.
        androidConfig: AndroidRecordConfig(
          service: AndroidService(
            title: _notificationTitle,
            content: _notificationContent,
          ),
        ),
      ),
    );
    _isRecording = true;
    _consecutiveEmitFailures = 0;
    _storageFaultRaised = false;
    _emitTask = Future.value();
    _recordingSubscription = stream.listen((data) {
      final pcmBytes = Uint8List.fromList(data);
      _levelsController.add(_chunker.levelFor(pcmBytes));
      final chunks = _chunker.add(pcmBytes);
      for (final chunk in chunks) {
        // Isolate each chunk's failure so the emit pipeline never gets
        // poisoned — otherwise a single IO error would silently stop all
        // future chunks from reaching the transcription queue.
        _emitTask = _emitTask.then((_) => _emitChunk(chunk)).catchError((
          Object error,
          StackTrace stack,
        ) {
          _onEmitFailure(chunk.index, error, stack);
        });
      }
    }, onError: _levelsController.addError);
  }

  @override
  Future<void> pause() async {
    if (!_isRecording) {
      return;
    }
    await _recorder.pause();
  }

  @override
  Future<void> resume() async {
    if (!_isRecording) {
      return;
    }
    await _recorder.resume();
  }

  @override
  Future<void> stop() async {
    if (!_isRecording) {
      return;
    }
    await _recorder.stop();
    await _recordingSubscription?.cancel();
    _recordingSubscription = null;
    _isRecording = false;

    await _emitTask;
    for (final chunk in _chunker.finish()) {
      await _emitChunk(chunk);
    }
    _levelsController.add(0);
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
    await _chunksController.close();
    await _levelsController.close();
  }

  Future<void> _emitChunk(PcmChunk chunk) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/voicescribe_chunks/chunk_${DateTime.now().microsecondsSinceEpoch}_${chunk.index}.wav',
    );
    await _wavWriter.writeWavFile(file: file, pcm16Data: chunk.pcm16Data);
    _consecutiveEmitFailures = 0;
    _chunksController.add(
      RecordedAudioChunk(
        path: file.path,
        durationSeconds: chunk.durationSeconds,
        index: chunk.index,
        averageLevel: chunk.averageLevel,
      ),
    );
  }

  /// Handles a failed chunk write. One-off IO errors are tolerated, but a run of
  /// them (the signature of a full disk) stops recording and surfaces a fault on
  /// the chunk stream so the UI can warn the user instead of losing audio
  /// silently for the rest of a long session.
  void _onEmitFailure(int index, Object error, StackTrace stack) {
    _consecutiveEmitFailures += 1;
    AppLogger.error(
      '[Recording] Emit chunk failed '
      '(index=$index, consecutive=$_consecutiveEmitFailures)',
      error,
      stack,
    );
    if (_consecutiveEmitFailures >= _emitFailureLimit && !_storageFaultRaised) {
      _storageFaultRaised = true;
      _chunksController.addError(const RecordingStorageException());
      unawaited(stop());
    }
  }
}

class RecordingPermissionException implements Exception {
  const RecordingPermissionException();

  @override
  String toString() => 'Microphone permission is required.';
}

/// Raised on the chunk stream when recorded audio can no longer be written to
/// disk (typically a full storage volume), so the UI can stop and warn the user.
class RecordingStorageException implements Exception {
  const RecordingStorageException();

  @override
  String toString() => 'Storage is full; recording was stopped.';
}
