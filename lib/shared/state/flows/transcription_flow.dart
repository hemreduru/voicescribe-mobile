part of '../app_controller.dart';

class TranscriptionFlow {
  const TranscriptionFlow();

  Future<void> transcribe(AppController app, TranscriptChunk chunk) async {
    try {
      final transcription = await app._transcriptionService.transcribeChunk(
        chunk.audioPath ?? '',
      );
      final firstSegment = transcription.segments.isEmpty
          ? null
          : transcription.segments.first;
      final lastSegment = transcription.segments.isEmpty
          ? null
          : transcription.segments.last;
      final nextStart = firstSegment == null
          ? null
          : math.min(
              chunk.endTime,
              math.max(
                chunk.startTime,
                chunk.startTime + firstSegment.startSeconds,
              ),
            );
      final nextEnd = lastSegment == null
          ? null
          : math.min(
              chunk.endTime,
              math.max(
                chunk.startTime,
                chunk.startTime + lastSegment.endSeconds,
              ),
            );
      app.transcriptController.applyTranscriptionSuccess(
        chunk,
        transcription.text,
        absoluteStartTime: nextStart,
        absoluteEndTime: nextEnd,
      );
      final updatedChunk = app.transcriptController.allChunks.firstWhere(
        (c) => c.id == chunk.id,
      );
      app._persistLater(app._repository.saveChunk(updatedChunk));
      final matches = app.currentChunks.where((item) => item.id == chunk.id);
      final current = matches.isEmpty ? null : matches.first;
      if (current != null && current.text.trim().isNotEmpty) {
        app.recordingController.appendPreview(current.text);
      }
    } catch (error) {
      app.transcriptController.applyTranscriptionError(chunk, error);
      final updatedChunk = app.transcriptController.allChunks.firstWhere(
        (c) => c.id == chunk.id,
      );
      app._persistLater(app._repository.saveChunk(updatedChunk));
    } finally {
      if (app.currentTranscript != null) {
        app._persistLater(
          app._repository.saveTranscript(app.currentTranscript!),
        );
      }
      app._notify();
      if (!app.isRecording && app.currentTranscript != null) {
        await app._enqueueSpeakerAnalysisIfReady(app.currentTranscript!.id);
      }
    }
  }
}
