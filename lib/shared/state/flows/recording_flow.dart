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
      await app._persist(app._repository.saveTranscript(transcript));
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
      await app._persist(
        app._repository.saveTranscript(app.currentTranscript!),
      );
      await app._enqueueSpeakerAnalysisIfReady(app.currentTranscript!.id);
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
    app.recordingController.incrementChunkCount();
    app._notify();
    app._persistLater(app._repository.saveChunk(chunk));
    unawaited(app._transcribe(chunk));
  }

  void startTimer(AppController app) {
    app._durationTimer?.cancel();
    app._durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      app.recordingController.tick();
      app.transcriptController.updateCurrentDuration(
        app.recordingController.durationSeconds,
      );
      if (app.currentTranscript != null) {
        unawaited(app._repository.saveTranscript(app.currentTranscript!));
      }
      app._notify();
    });
  }

  void stopTimer(AppController app) {
    app._durationTimer?.cancel();
    app._durationTimer = null;
  }
}
