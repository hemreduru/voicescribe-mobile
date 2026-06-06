import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/ui/features/recording/bloc/recording_bloc.dart';

TranscriptChunk _chunk(
  String transcriptId,
  int index, {
  required double start,
  required double end,
  required bool transcribed,
  String? error,
  String? audioPath = '/tmp/x.wav',
}) {
  return TranscriptChunk(
    id: '$transcriptId-chunk-$index',
    transcriptId: transcriptId,
    chunkIndex: index,
    text: transcribed ? 'done' : '',
    audioPath: audioPath,
    recordedAt: DateTime(2026),
    startTime: start,
    endTime: end,
    confidence: null,
    transcriptionError: error,
    isTranscribed: transcribed,
  );
}

void main() {
  group('RecordingState transcription progress', () {
    final transcript = Transcript(
      id: 't1',
      localId: 't1',
      title: 'x',
      status: TranscriptStatus.transcribing,
      durationSeconds: 30,
      recordedAt: DateTime(2026),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    test('counts done vs total and sums only pending audio for the active session', () {
      final chunks = [
        _chunk('t1', 1, start: 0, end: 15, transcribed: true),
        _chunk('t1', 2, start: 15, end: 30, transcribed: false),
        _chunk('t1', 3, start: 30, end: 40, transcribed: false),
      ];
      final state = RecordingState(
        currentTranscript: transcript,
        allChunks: chunks,
        realtimeFactor: 2,
      );

      expect(state.totalProgressChunks, 3);
      expect(state.transcribedProgressChunks, 1);
      // Pending audio = (30-15) + (40-30) = 25s; ETA = 25 * 2.0 = 50s.
      expect(state.pendingAudioSeconds, 25);
      expect(state.isTranscribing, isTrue);
      expect(state.estimatedTranscriptionRemaining, const Duration(seconds: 50));
    });

    test('excludes errored and audio-less chunks from the pending backlog', () {
      final chunks = [
        _chunk('t1', 1, start: 0, end: 15, transcribed: false, error: 'boom'),
        _chunk('t1', 2, start: 15, end: 30, transcribed: false, audioPath: ''),
        _chunk('t1', 3, start: 30, end: 45, transcribed: false),
      ];
      final state = RecordingState(
        currentTranscript: transcript,
        allChunks: chunks,
        realtimeFactor: 1,
      );

      // Only chunk 3 is a real pending backlog (15s).
      expect(state.pendingAudioSeconds, 15);
      expect(state.estimatedTranscriptionRemaining, const Duration(seconds: 15));
    });

    test('reports no remaining estimate once everything is transcribed', () {
      final chunks = [
        _chunk('t1', 1, start: 0, end: 15, transcribed: true),
        _chunk('t1', 2, start: 15, end: 30, transcribed: true),
      ];
      final state = RecordingState(
        currentTranscript: transcript,
        allChunks: chunks,
      );

      expect(state.isTranscribing, isFalse);
      expect(state.estimatedTranscriptionRemaining, isNull);
    });
  });
}
