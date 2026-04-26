import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/shared/state/controllers/transcript_controller.dart';

void main() {
  test('keeps transcription error status when any chunk fails', () {
    final controller = TranscriptController();
    controller.startSession('Demo');

    final firstChunk = controller.addRecordedChunk(
      const RecordedAudioChunk(
        path: '/tmp/1.wav',
        durationSeconds: 2,
        index: 1,
      ),
    );
    final secondChunk = controller.addRecordedChunk(
      const RecordedAudioChunk(
        path: '/tmp/2.wav',
        durationSeconds: 2,
        index: 2,
      ),
    );

    controller.applyTranscriptionSuccess(firstChunk, 'Merhaba dunya');
    controller.applyTranscriptionError(secondChunk, Exception('failed'));
    controller.markRecordingStopped(durationSeconds: 4);

    expect(
      controller.currentTranscript?.status,
      TranscriptStatus.transcriptionError,
    );
    expect(
      controller
          .chunksFor(controller.currentTranscript!.id)
          .any((chunk) => (chunk.transcriptionError ?? '').isNotEmpty),
      isTrue,
    );
  });

  test('marks transcript as completed when all chunks succeed', () {
    final controller = TranscriptController();
    controller.startSession('Demo');

    final chunk = controller.addRecordedChunk(
      const RecordedAudioChunk(
        path: '/tmp/1.wav',
        durationSeconds: 2,
        index: 1,
      ),
    );

    controller.applyTranscriptionSuccess(chunk, 'Merhaba dunya');
    controller.markRecordingStopped(durationSeconds: 2);

    expect(controller.currentTranscript?.status, TranscriptStatus.completed);
    expect(
      controller.transcriptText(controller.currentTranscript!.id),
      'Merhaba dunya',
    );
  });
}
