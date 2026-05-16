part of '../app_controller.dart';

class RecordingFlow {
  const RecordingFlow();

  Future<void> startRecording(AppController app, String? title) async {
    app._ensureAuthenticated();
    if (app.isRecording) {
      return;
    }

    final transcript = app.transcriptController.startSession(
      title,
      userId: app.currentUserId,
    );
    app.recordingController.start();
    app._notify();

    try {
      await app._audioService.start();
      app._startTimer();
      await app._saveTranscript(transcript);
    } catch (error) {
      app.transcriptController.removeTranscript(transcript.id);
      app.recordingController.stop();
      app.transcriptController.lastError = error.toString();
      app._notify();
      rethrow;
    }
  }

  Future<void> stopRecording(AppController app) async {
    if (!app.isRecording) {
      return;
    }
    app._stopTimer();
    await app._audioService.stop();

    app.recordingController.stop();
    app.transcriptController.markRecordingStopped(
      durationSeconds: app.recordingController.durationSeconds,
    );
    if (app.currentTranscript != null) {
      await app._saveTranscript(app.currentTranscript!, scheduleSync: true);
    }
    app._notify();
  }

  Future<void> togglePause(AppController app) async {
    if (!app.isRecording) {
      return;
    }
    if (app.isPaused) {
      await app._audioService.resume();
      app.recordingController.resume();
      app._startTimer();
    } else {
      await app._audioService.pause();
      app.recordingController.pause();
      app._stopTimer();
    }
    app._notify();
  }

  void handleAudioChunk(AppController app, RecordedAudioChunk audioChunk) {
    final transcript = app.currentTranscript;
    if (transcript == null) {
      return;
    }

    final chunk = app.transcriptController.addRecordedChunk(audioChunk);
    final transcriptForPersistence = app.currentTranscript;
    app.recordingController.incrementChunkCount();
    app._notify();
    if (transcriptForPersistence == null) {
      return;
    }
    unawaited(_persistAndTranscribe(app, chunk, transcriptForPersistence));
  }

  Future<void> _persistAndTranscribe(
    AppController app,
    TranscriptChunk chunk,
    Transcript transcript,
  ) async {
    try {
      await app._saveChunkAndTranscript(chunk, transcript, scheduleSync: true);
      await app._transcribe(chunk);
    } catch (error) {
      app.transcriptController.applyTranscriptionError(chunk, error);
      app._notify();
    }
  }

  void startTimer(AppController app) {
    app._durationTimer?.cancel();
    app._durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      app.recordingController.tick();
      app.transcriptController.updateCurrentDuration(
        app.recordingController.durationSeconds,
      );
      if (app.currentTranscript != null) {
        app._saveTranscriptLater(app.currentTranscript!);
      }
      app._notify();
    });
  }

  void stopTimer(AppController app) {
    app._durationTimer?.cancel();
    app._durationTimer = null;
  }
}
