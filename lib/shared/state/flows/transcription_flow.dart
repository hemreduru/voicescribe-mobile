part of '../app_controller.dart';

class TranscriptionFlow {
  const TranscriptionFlow();

  Future<void> transcribe(AppController app, TranscriptChunk chunk) async {
    Transcript? transcriptForPersistence;
    try {
      final transcription = await app._transcriptionService.transcribeChunk(
        chunk.audioPath ?? '',
      );
      app.transcriptController.applyTranscriptionSuccess(
        chunk,
        transcription.text,
      );
      transcriptForPersistence = app.transcriptController.transcripts
          .firstWhere((item) => item.id == chunk.transcriptId);
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
      transcriptForPersistence = app.transcriptController.transcripts
          .firstWhere((item) => item.id == chunk.transcriptId);
      final updatedChunk = app.transcriptController.allChunks.firstWhere(
        (c) => c.id == chunk.id,
      );
      app._persistLater(app._repository.saveChunk(updatedChunk));
    } finally {
      final transcript = transcriptForPersistence;
      if (transcript != null) {
        app._saveTranscriptLater(transcript, scheduleSync: true);
      }
      app._notify();
      if (!app.isRecording && app.currentTranscript != null) {
        // Speaker analysis removed
      }
    }
  }
}
