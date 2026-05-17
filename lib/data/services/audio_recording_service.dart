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
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        streamBufferSize: 3200,
      ),
    );
    _isRecording = true;
    _emitTask = Future.value();
    _recordingSubscription = stream.listen((data) {
      final pcmBytes = Uint8List.fromList(data);
      _levelsController.add(_chunker.levelFor(pcmBytes));
      final chunks = _chunker.add(pcmBytes);
      for (final chunk in chunks) {
        // Isolate each chunk's failure so the emit pipeline never gets
        // poisoned — otherwise a single IO error would silently stop all
        // future chunks from reaching the transcription queue.
        _emitTask = _emitTask
            .then((_) => _emitChunk(chunk))
            .catchError((Object error, StackTrace stack) {
              AppLogger.error(
                '[Recording] Emit chunk failed (index=${chunk.index})',
                error,
                stack,
              );
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
    _chunksController.add(
      RecordedAudioChunk(
        path: file.path,
        durationSeconds: chunk.durationSeconds,
        index: chunk.index,
        averageLevel: chunk.averageLevel,
      ),
    );
  }
}

class RecordingPermissionException implements Exception {
  const RecordingPermissionException();

  @override
  String toString() => 'Microphone permission is required.';
}
