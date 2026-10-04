import 'package:voicescribe_mobile/domain/models/app_error.dart';

class TranscriptionResult {
  const TranscriptionResult({required this.text});

  final String text;
}

/// Thrown when a chunk could not be transcribed (auth, rate limit, backend or
/// network failure) after the service exhausted its retries. The UI localizes
/// [code]; [message] is for logs and the persisted chunk error.
class TranscriptionException implements Exception {
  const TranscriptionException(this.message, {required this.code});

  final String message;
  final AppErrorCode code;

  @override
  String toString() => 'TranscriptionException: $message';
}

abstract class TranscriptionService {
  /// The currently configured transcription language code (`tr` or `en`).
  String get currentTranscriptionLanguage;

  /// Sets the transcription language (`tr` or `en`).
  void setTranscriptionLanguage(String language);

  /// Transcribes one recorded WAV chunk. Chunks are processed one at a time in
  /// submission order. Throws [TranscriptionException] on permanent failure.
  Future<TranscriptionResult> transcribeChunk(String audioPath);
}
