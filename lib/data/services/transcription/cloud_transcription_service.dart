import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:voicescribe_mobile/data/services/transcript_api_client.dart';
import 'package:voicescribe_mobile/data/services/transcription_service.dart';
import 'package:voicescribe_mobile/domain/models/app_error.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/ui/core/utils/logger.dart';

/// Transcribes recorded chunks through the backend speech-to-text relay
/// (`POST /api/v1/transcribe`). The provider key lives only on the backend.
///
/// Chunks are uploaded one at a time in submission order: the recording flow
/// de-duplicates the overlap between consecutive chunks, which needs the
/// previous chunk's text to be final first, and a serial queue keeps us well
/// under the per-user rate limit.
class CloudTranscriptionService implements TranscriptionService {
  CloudTranscriptionService({
    required TranscriptApiClient apiClient,
    required String? Function() tokenProvider,
    Future<void> Function(Duration duration)? delay,
  }) : _apiClient = apiClient,
       _tokenProvider = tokenProvider,
       _delay = delay ?? Future<void>.delayed;

  final TranscriptApiClient _apiClient;
  final String? Function() _tokenProvider;
  final Future<void> Function(Duration duration) _delay;

  String _language = 'tr';
  Future<void> _queue = Future<void>.value();

  /// Retries after the first attempt, for 429 / 502 / 503 / network errors.
  static const int _maxRetries = 3;
  static const Duration _baseBackoff = Duration(seconds: 2);
  static const Duration _maxRetryAfter = Duration(minutes: 1);

  @override
  String get currentTranscriptionLanguage => _language;

  @override
  void setTranscriptionLanguage(String language) {
    _language = AppPreferences.normalizeTranscriptionLanguage(language);
    AppLogger.info('[Transcription] Language set to $_language');
  }

  @override
  Future<TranscriptionResult> transcribeChunk(String audioPath) {
    final result = _queue.then((_) => _transcribe(audioPath));
    // A failed chunk must not poison the queue for the next one.
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<TranscriptionResult> _transcribe(String audioPath) async {
    final token = _tokenProvider()?.trim();
    if (token == null || token.isEmpty) {
      throw const TranscriptionException(
        'Transcription requires an authenticated session.',
        code: AppErrorCode.transcriptionAuthRequired,
      );
    }

    final Uint8List audio;
    try {
      audio = await File(audioPath).readAsBytes();
    } on FileSystemException catch (error) {
      throw TranscriptionException(
        'Chunk audio is unreadable: ${error.message}',
        code: AppErrorCode.transcriptionGeneric,
      );
    }
    final filename = p.basename(audioPath);

    for (var retry = 0; ; retry++) {
      final response = await _apiClient.transcribe(
        audio: audio,
        filename: filename,
        token: token,
        language: _language,
      );
      if (response.isSuccess) {
        return _resultOf(response);
      }

      final failure = _failureOf(response);
      if (!_isRetryable(response) || retry >= _maxRetries) {
        AppLogger.warning(
          '[Transcription] $filename failed '
          '(HTTP ${response.statusCode}, attempts=${retry + 1})',
        );
        throw failure;
      }
      final wait = _waitBefore(retry, response);
      AppLogger.info(
        '[Transcription] $filename HTTP ${response.statusCode}; retry '
        '${retry + 1}/$_maxRetries in ${wait.inSeconds}s',
      );
      await _delay(wait);
    }
  }

  TranscriptionResult _resultOf(ApiResponse response) {
    final data = response.data;
    final text = data is Map ? data['text'] : null;
    if (text is! String) {
      throw const TranscriptionException(
        'Transcription response has no text.',
        code: AppErrorCode.transcriptionGeneric,
      );
    }
    return TranscriptionResult(text: text.trim());
  }

  bool _isRetryable(ApiResponse response) {
    return response.isNetworkFailure ||
        response.statusCode == HttpStatus.tooManyRequests ||
        response.statusCode == HttpStatus.badGateway ||
        response.statusCode == HttpStatus.serviceUnavailable ||
        response.statusCode == HttpStatus.gatewayTimeout;
  }

  /// Honors the server's `Retry-After` (capped); otherwise exponential
  /// backoff: 2 s, 4 s, 8 s.
  Duration _waitBefore(int retry, ApiResponse response) {
    final retryAfter = response.retryAfterSeconds;
    if (retryAfter != null && retryAfter >= 0) {
      final wait = Duration(seconds: retryAfter);
      return wait > _maxRetryAfter ? _maxRetryAfter : wait;
    }
    return _baseBackoff * (1 << retry);
  }

  TranscriptionException _failureOf(ApiResponse response) {
    final code = switch (response.statusCode) {
      0 => AppErrorCode.transcriptionOffline,
      HttpStatus.unauthorized ||
      HttpStatus.forbidden => AppErrorCode.transcriptionAuthRequired,
      HttpStatus.tooManyRequests => AppErrorCode.transcriptionRateLimited,
      HttpStatus.badGateway ||
      HttpStatus.serviceUnavailable ||
      HttpStatus.gatewayTimeout => AppErrorCode.transcriptionUnavailable,
      _ => AppErrorCode.transcriptionGeneric,
    };
    return TranscriptionException(
      'Transcription failed: HTTP ${response.statusCode} '
              '${response.message ?? ''}'
          .trim(),
      code: code,
    );
  }
}
