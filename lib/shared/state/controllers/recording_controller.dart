import 'package:voicescribe_mobile/shared/utils/text_utils.dart';

class RecordingController {
  bool isRecording = false;
  bool isPaused = false;
  int durationSeconds = 0;
  int chunkCount = 0;
  double audioLevel = 0;
  String liveTranscriptPreview = '';

  void start() {
    isRecording = true;
    isPaused = false;
    durationSeconds = 0;
    chunkCount = 0;
    audioLevel = 0;
    liveTranscriptPreview = '';
  }

  void stop() {
    isRecording = false;
    isPaused = false;
    audioLevel = 0;
  }

  void pause() {
    isPaused = true;
  }

  void resume() {
    isPaused = false;
  }

  void tick() {
    durationSeconds++;
  }

  // Controller methods intentionally keep mutation explicit for AppController.
  // ignore: use_setters_to_change_properties
  void applyAudioLevel(double value) {
    audioLevel = value;
  }

  void incrementChunkCount() {
    chunkCount++;
  }

  void appendPreview(String value) {
    final normalized = normalizeWhitespace(value);
    if (normalized.isEmpty) {
      return;
    }
    liveTranscriptPreview = normalizeWhitespace(
      '$liveTranscriptPreview $normalized',
    );
    if (liveTranscriptPreview.length > 500) {
      liveTranscriptPreview = liveTranscriptPreview.substring(
        liveTranscriptPreview.length - 500,
      );
    }
  }
}
