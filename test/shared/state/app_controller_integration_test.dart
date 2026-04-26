import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/shared/services/summary_service.dart';
import 'package:voicescribe_mobile/shared/services/transcript_repository.dart';
import 'package:voicescribe_mobile/shared/services/whisper_service.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';

void main() {
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
}

class _FakeRepository implements TranscriptRepository {
  PersistedTranscriptState state = PersistedTranscriptState.empty();
  final List<PersistedTranscriptState> savedStates = [];

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
  Future<void> saveSpeaker(SpeakerProfile speaker) async {}

  @override
  Future<void> deleteSpeaker(String id) async {}

  @override
  Future<void> saveSummary(Summary summary) async {}

  @override
  Future<void> saveSetting(String key, String value) async {}
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
  Future<String> transcribeChunk(String audioPath) async {
    final response = responses[audioPath];
    if (response is Exception) {
      throw response;
    }
    return response?.toString() ?? '';
  }
}
